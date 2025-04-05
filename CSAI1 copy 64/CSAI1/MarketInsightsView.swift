import SwiftUI
import Charts

// MARK: - Data Models

/// Single data point for charting price, volume, or market cap at a given time.
struct MarketDataPoint: Identifiable, Codable {
    let id: UUID
    let time: Date
    let price: Double
    let volume: Double
    let marketCap: Double
    
    init(time: Date, price: Double, volume: Double, marketCap: Double) {
        self.id = UUID()
        self.time = time
        self.price = price
        self.volume = volume
        self.marketCap = marketCap
    }
    
    // Custom decode
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.time       = try container.decode(Date.self,   forKey: .time)
        self.price      = try container.decode(Double.self, forKey: .price)
        self.volume     = try container.decode(Double.self, forKey: .volume)
        self.marketCap  = try container.decode(Double.self, forKey: .marketCap)
        self.id         = UUID()
    }
    
    // Custom encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time,       forKey: .time)
        try container.encode(price,      forKey: .price)
        try container.encode(volume,     forKey: .volume)
        try container.encode(marketCap,  forKey: .marketCap)
    }
    
    private enum CodingKeys: String, CodingKey {
        case time, price, volume, marketCap
    }
}

/// We store the chart data from e.g. CoinPaprika or Binance in a common struct:
struct CryptoMarketChart: Decodable {
    let prices:       [[Double]]   // [ [timestampMs, price], ... ]
    let market_caps:  [[Double]]   // [ [timestampMs, marketCap], ... ]
    let total_volumes:[[Double]]   // [ [timestampMs, volume], ... ]
}

// We *no longer* declare FearGreedData or FearGreedResponse here, so it won’t conflict with your HomeView.

// MARK: - Skeleton Loader

private let customSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest  = 12
    config.timeoutIntervalForResource = 15
    return URLSession(configuration: config)
}()

struct SkeletonView: View {
    @State private var isAnimating = false
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .shimmering(active: isAnimating)
            .onAppear { isAnimating = true }
    }
}
extension View {
    func shimmering(active: Bool) -> some View {
        self.overlay(
            ShimmerView(isActive: active)
                .mask(self)
        )
    }
}
struct ShimmerView: View {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.45),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: -geo.size.width * 2 + geo.size.width * 2 * phase)
                .onAppear {
                    guard isActive else { return }
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
        .clipped()
    }
}

// MARK: - Coin Info Models

struct CoinInfo: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
}

@MainActor
class CoinListViewModel: ObservableObject {
    @Published var allCoins: [CoinInfo] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    var filteredCoins: [CoinInfo] {
        if searchText.isEmpty { return allCoins }
        return allCoins.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.symbol.lowercased().contains(searchText.lowercased())
        }
    }
    
    func fetchCoinList() {
        Task {
            self.isLoading = true
            self.errorMessage = nil
            let urlString = "https://api.coinpaprika.com/v1/coins" // or any other
            guard let url = URL(string: urlString) else {
                self.isLoading = false
                self.errorMessage = "Invalid URL for coin list."
                return
            }
            do {
                let (data, response) = try await customSession.data(from: url)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    print("Coin list error from server (\(http.statusCode)): \(raw)")
                    self.isLoading = false
                    self.errorMessage = "Coin list error: \(http.statusCode)"
                    return
                }
                let rawList = try JSONDecoder().decode([CoinInfo].self, from: data)
                // Possibly filter out non-crypto, test code
                self.allCoins = rawList.filter { !$0.symbol.isEmpty }
                print("Loaded \(self.allCoins.count) coins from network.")
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = "Coin list error: \(error.localizedDescription)"
                print("Coin list error: \(error)")
            }
        }
    }
}

// MARK: - Stats View

struct StatsView: View {
    let dataPoints: [MarketDataPoint]
    let metric: MarketInsightsView.Metric
    
    private var values: [Double] {
        dataPoints.map { valueForMetric($0) }
    }
    private var minValue: Double { values.min() ?? 0 }
    private var maxValue: Double { values.max() ?? 0 }
    private var avgValue: Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            statColumn("Min", minValue)
            statColumn("Max", maxValue)
            statColumn("Avg", avgValue)
        }
        .font(.caption)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func statColumn(_ title: String, _ value: Double) -> some View {
        VStack {
            Text(title).foregroundColor(.gray)
            Text(String(format: "$%.2f", value))
                .foregroundColor(.white)
        }
    }
    
    private func valueForMetric(_ p: MarketDataPoint) -> Double {
        switch metric {
        case .price:     return p.price
        case .volume:    return p.volume
        case .marketCap: return p.marketCap
        }
    }
}

// MARK: - Coin Selector

struct CoinSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: CoinListViewModel
    var onSelect: (CoinInfo) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if vm.isLoading {
                    ProgressView("Loading coins...")
                } else if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") { vm.fetchCoinList() }
                        .padding(.bottom)
                } else if vm.allCoins.isEmpty {
                    Text("No coins available. Check your connection or try again.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(vm.filteredCoins) { coin in
                            Button {
                                onSelect(coin)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(coin.name)
                                    Text(coin.symbol.uppercased())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .refreshable { vm.fetchCoinList() }
                    .searchable(text: $vm.searchText, prompt: "Search coins...")
                }
            }
            .navigationTitle("Select a Coin")
            .onAppear {
                if vm.allCoins.isEmpty {
                    vm.fetchCoinList()
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class MarketInsightsViewModel: ObservableObject {
    @Published var dataPoints: [MarketDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var usingCache = false
    
    private let cacheKey = "cachedMarketData_insights"
    
    /// Immediately loads any cached data, then tries concurrent fetch from multiple sources.
    func fetchLiveData(coinID: String, timeFrame: MarketInsightsView.TimeFrame) {
        loadFromCache()
        
        Task {
            self.isLoading = true
            self.errorMessage = nil
            // If we had no cache, we show skeleton:
            if !usingCache {
                self.dataPoints.removeAll()
            }
            let success = await fetchConcurrent(coinID: coinID, timeFrame: timeFrame)
            if !success {
                loadDummyData()
            }
            self.isLoading = false
        }
    }
    
    /// Race multiple data sources (CoinPaprika, Binance, etc.)
    private func fetchConcurrent(coinID: String, timeFrame: MarketInsightsView.TimeFrame) async -> Bool {
        let (days, interval) = daysAndInterval(for: timeFrame)
        
        // Make tasks
        let fetchTasks: [() async -> [MarketDataPoint]?] = [
            { await self.fetchCoinPaprika(coinID: coinID, days: days, interval: interval) },
            { await self.fetchBinance(coinID: coinID, days: days, interval: interval) }
            // Add more if you want (CoinGecko, etc.)
        ]
        
        if let firstSuccess = await raceFetches(fetchTasks) {
            self.dataPoints = firstSuccess
            print("Loaded \(firstSuccess.count) points from concurrency race.")
            saveToCache(firstSuccess)
            return true
        } else {
            return false
        }
    }
    
    /// Returns the *first* successful [MarketDataPoint] from the given tasks, ignoring failures.
    private func raceFetches(_ tasks: [() async -> [MarketDataPoint]?]) async -> [MarketDataPoint]? {
        // We can do naive concurrency:
        await withTaskGroup(of: [MarketDataPoint]?.self) { group in
            // Add them all
            for t in tasks {
                group.addTask {
                    return await t()
                }
            }
            // The moment we find a non-nil result, we can return it.
            for await result in group {
                if let valid = result, !valid.isEmpty {
                    // Cancel the group
                    group.cancelAll()
                    return valid
                }
            }
            // If none succeeded, return nil
            return nil
        }
    }
    
    /// Example: queries coinpaprika’s “historical” data.
    private func fetchCoinPaprika(coinID: String, days: String, interval: String) async -> [MarketDataPoint]? {
        // We approximate "days" with start/end timestamps.
        guard let (start, end) = dateRangeFromDaysString(days) else { return nil }
        let base = "https://api.coinpaprika.com/v1/tickers/\(coinID)/historical"
        var urlComponents = URLComponents(string: base)
        urlComponents?.queryItems = [
            URLQueryItem(name: "start",     value: iso8601String(start)),
            URLQueryItem(name: "end",       value: iso8601String(end)),
            URLQueryItem(name: "interval",  value: interval)  // e.g. "1h" or "1d"
        ]
        guard let url = urlComponents?.url else { return nil }
        
        print("[CoinPaprika] Attempting fetch: \(url.absoluteString)")
        
        do {
            let (data, response) = try await customSession.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("CoinPaprika error (\(http.statusCode)): \(raw)")
                self.errorMessage = "CoinPaprika error: \(http.statusCode)"
                return nil
            }
            // We parse a different structure.
            // According to docs, it might be [ { timestamp, price, volume, market_cap }, ... ]
            // Let's decode a custom array:
            let rawArray = try JSONDecoder().decode([[String:Double?]].self, from: data)
            // Convert
            var results: [MarketDataPoint] = []
            for item in rawArray {
                guard
                  let timeSec = item["timestamp"] ?? nil,
                  let price   = item["price"]     ?? nil
                else { continue }
                let date = Date(timeIntervalSince1970: timeSec)
                let volume = item["volume_24h"]     ?? 0
                let mcap   = item["market_cap"]     ?? 0
                results.append(MarketDataPoint(time: date, price: price, volume: volume, marketCap: mcap))
            }
            results.sort { $0.time < $1.time }
            if results.isEmpty { return nil }
            return results
        } catch {
            print("CoinPaprika fetch failed: \(error.localizedDescription)")
            self.errorMessage = "CoinPaprika error: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Example: placeholder for Binance. Adjust as needed.
    private func fetchBinance(coinID: String, days: String, interval: String) async -> [MarketDataPoint]? {
        // We do a silly example. Suppose binance has an endpoint.
        // Real binance klines endpoint: e.g. "GET /api/v3/klines?symbol=BTCUSDT&interval=1h&startTime=..."
        // For demonstration, we pretend to do a minimal fetch or return nil.
        // If you want real code, fill in actual logic.
        guard let (start, end) = dateRangeFromDaysString(days) else { return nil }
        let symbol = symbolForBinance(coinID: coinID) // convert "bitcoin" to "BTCUSDT" or so.
        let base = "https://api.binance.com/api/v3/klines"
        var urlComponents = URLComponents(string: base)
        // Just do 1h for everything.
        urlComponents?.queryItems = [
            URLQueryItem(name: "symbol", symbol),
            URLQueryItem(name: "interval", "1h"),
            URLQueryItem(name: "startTime", String(Int(start.timeIntervalSince1970 * 1000))),
            URLQueryItem(name: "endTime",   String(Int(end.timeIntervalSince1970 * 1000)))
        ].compactMap { $0 }
        guard let url = urlComponents?.url else { return nil }
        
        print("[Binance] Attempting fetch: \(url.absoluteString)")
        
        do {
            let (data, response) = try await customSession.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let raw = String(data: data, encoding: .utf8) ?? ""
                print("Binance error (\(http.statusCode)): \(raw)")
                self.errorMessage = "Binance error: \(http.statusCode)"
                return nil
            }
            // Kline response is typically an array of arrays:
            // [ [OpenTime, Open, High, Low, Close, Volume, CloseTime, ...], [...], ... ]
            // We'll parse them:
            let rawKlines = try JSONDecoder().decode([[AnyDecodable]].self, from: data)
            var results: [MarketDataPoint] = []
            for arr in rawKlines {
                // We only read certain fields
                guard
                  arr.count >= 6,
                  let openTimeMs = arr[0].value as? Double,
                  let closePrice = arr[4].value as? String,
                  let volStr     = arr[5].value as? String,
                  let cPrice     = Double(closePrice),
                  let cVol       = Double(volStr)
                else { continue }
                
                let date = Date(timeIntervalSince1970: openTimeMs / 1000)
                // no direct marketcap from binance klines, so 0
                results.append(MarketDataPoint(time: date, price: cPrice, volume: cVol, marketCap: 0))
            }
            results.sort { $0.time < $1.time }
            if results.isEmpty { return nil }
            return results
        } catch {
            print("Binance fetch failed: \(error.localizedDescription)")
            self.errorMessage = "Binance error: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func loadDummyData() {
        print("Loading dummy data fallback...")
        let dummyJSON = """
        {
          "prices": [
            [1640995200000, 47000.0],
            [1641081600000, 48000.0],
            [1641168000000, 49000.0],
            [1641254400000, 50000.0]
          ],
          "market_caps": [
            [1640995200000, 880000000000],
            [1641081600000, 890000000000],
            [1641168000000, 900000000000],
            [1641254400000, 910000000000]
          ],
          "total_volumes": [
            [1640995200000, 35000000000],
            [1641081600000, 36000000000],
            [1641168000000, 37000000000],
            [1641254400000, 38000000000]
          ]
        }
        """
        guard let data = dummyJSON.data(using: .utf8) else {
            self.errorMessage = "Failed to load dummy data."
            return
        }
        do {
            let cryptoData = try JSONDecoder().decode(CryptoMarketChart.self, from: data)
            let count = min(cryptoData.prices.count,
                            cryptoData.market_caps.count,
                            cryptoData.total_volumes.count)
            var points: [MarketDataPoint] = []
            for i in 0..<count {
                let tstamp = cryptoData.prices[i][0]
                let date = Date(timeIntervalSince1970: tstamp / 1000)
                let price = cryptoData.prices[i][1]
                let mcap  = cryptoData.market_caps[i][1]
                let vol   = cryptoData.total_volumes[i][1]
                points.append(MarketDataPoint(time: date, price: price, volume: vol, marketCap: mcap))
            }
            points.sort { $0.time < $1.time }
            self.dataPoints = points
            self.usingCache = true
            print("Loaded \(points.count) dummy data points.")
        } catch {
            print("Dummy data decoding error: \(error)")
            self.errorMessage = "Dummy data error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Caching
    private func saveToCache(_ points: [MarketDataPoint]) {
        do {
            let encoded = try JSONEncoder().encode(points)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("Cached \(points.count) data points in \(cacheKey).")
        } catch {
            print("Caching error: \(error)")
        }
    }
    private func loadFromCache() {
        guard let savedData = UserDefaults.standard.data(forKey: cacheKey) else {
            print("No cached data found.")
            return
        }
        do {
            let cachedPoints = try JSONDecoder().decode([MarketDataPoint].self, from: savedData)
            if !cachedPoints.isEmpty {
                self.dataPoints = cachedPoints
                self.usingCache = true
                print("Loaded \(cachedPoints.count) data points from cache.")
            } else {
                print("Cached data is empty.")
            }
        } catch {
            print("Cache decoding error: \(error)")
        }
    }
    
    /// Returns (daysParam, intervalParam) for e.g. coinpaprika or binance usage
    private func daysAndInterval(for tf: MarketInsightsView.TimeFrame) -> (String, String) {
        switch tf {
        case .day:        return ("1",    "1h")
        case .week:       return ("7",    "1d")
        case .month:      return ("30",   "1d")
        case .year:       return ("365",  "1d")
        case .threeYears: return ("1095", "1d")
        case .all:        return ("max",  "1d")
        }
    }
    
    /// Attempt to parse a date range from the "days" string. If "max", we do ~ 5 years as an example.
    private func dateRangeFromDaysString(_ days: String) -> (Date, Date)? {
        let now = Date()
        if days == "max" {
            // e.g. 5 years
            if let d = Calendar.current.date(byAdding: .year, value: -5, to: now) {
                return (d, now)
            }
        } else if let dVal = Int(days) {
            if let start = Calendar.current.date(byAdding: .day, value: -dVal, to: now) {
                return (start, now)
            }
        }
        return nil
    }
    
    /// Convert date to ISO8601 string for coinpaprika, e.g. "2025-04-04T20:07:31Z"
    private func iso8601String(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        return fmt.string(from: date)
    }
    
    /// Convert coinID to binance symbol. For "bitcoin" => "BTCUSDT" for example.
    private func symbolForBinance(coinID: String) -> String {
        // You might keep a map of known IDs to binance symbols:
        switch coinID.lowercased() {
        case "bitcoin":     return "BTCUSDT"
        case "ethereum":    return "ETHUSDT"
        // etc...
        default:            return "BTCUSDT"
        }
    }
}

// MARK: - The main MarketInsightsView

struct MarketInsightsView: View {
    
    enum Metric: String, CaseIterable, Identifiable {
        case price     = "Price (USD)"
        case volume    = "Volume"
        case marketCap = "Market Cap"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .price:     return "The current price in USD."
            case .volume:    return "The 24-hour trading volume."
            case .marketCap: return "The current market capitalization."
            }
        }
    }
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day   = "1D"
        case week  = "1W"
        case month = "1M"
        case year  = "1Y"
        case threeYears = "3Y"
        case all   = "ALL"
        
        var id: String { rawValue }
    }
    
    @StateObject private var insightsVM = MarketInsightsViewModel()
    @StateObject private var coinListVM = CoinListViewModel()
    
    @State private var selectedCoin: CoinInfo = CoinInfo(id: "bitcoin", symbol: "btc", name: "Bitcoin")
    @State private var selectedMetric: Metric = .price
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var showCoinSelector = false
    
    // For the top error overlay:
    @State private var showErrorOverlay = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // background gradient
            LinearGradient(
                gradient: Gradient(colors: [.black, Color(.darkGray)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selectedCoin.name) Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Market trends for \(selectedCoin.name).")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Controls
                    VStack(spacing: 12) {
                        // Coin
                        HStack {
                            Text("Coin:")
                                .foregroundColor(.gray)
                            Button {
                                showCoinSelector = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedCoin.name)
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                            }
                            Spacer()
                        }
                        // Metric
                        HStack {
                            Text("Metric:")
                                .foregroundColor(.gray)
                            Picker("Metric", selection: $selectedMetric) {
                                ForEach(Metric.allCases) { m in
                                    Text(m.rawValue).tag(m)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        // TimeFrame
                        HStack {
                            Text("Time Frame:")
                                .foregroundColor(.gray)
                            Picker("Time Frame", selection: $selectedTimeFrame) {
                                ForEach(TimeFrame.allCases) { tf in
                                    Text(tf.rawValue).tag(tf)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Chart & Stats
                    Group {
                        if insightsVM.isLoading {
                            chartSkeleton
                        } else if let error = insightsVM.errorMessage, insightsVM.dataPoints.isEmpty {
                            errorFallback(error: error)
                        } else if insightsVM.dataPoints.isEmpty {
                            VStack(spacing: 8) {
                                Text("No data points to display.")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        } else {
                            chartSection
                            StatsView(dataPoints: insightsVM.dataPoints, metric: selectedMetric)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedMetric.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(selectedMetric.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Market Sentiment (placeholder)
                    VStack {
                        Text("Market Sentiment")
                            .font(.headline)
                            .foregroundColor(.white)
                        // If you want Fear & Greed from your HomeView, unify them or rename the data model.
                        Text("Live sentiment data coming soon.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Example:
                        // Text("Fear (28)")
                        //   .font(.headline)
                        //   .foregroundColor(.yellow)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            
            // Top error overlay
            if showErrorOverlay {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.yellow)
                    Text(insightsVM.errorMessage ?? "Unknown Error")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
                .padding()
                .transition(.move(edge: .top))
            }
        }
        .onAppear { fetchData() }
        .onChange(of: selectedMetric)     { _ in fetchData() }
        .onChange(of: selectedTimeFrame)  { _ in fetchData() }
        .sheet(isPresented: $showCoinSelector) {
            CoinSelectorView(vm: coinListVM) { coin in
                selectedCoin = coin
                fetchData()
            }
        }
        .onChange(of: insightsVM.errorMessage) { newValue in
            withAnimation {
                showErrorOverlay = (newValue != nil && !insightsVM.dataPoints.isEmpty)
            }
        }
    }
    
    // MARK: - Skeleton
    private var chartSkeleton: some View {
        VStack(spacing: 16) {
            SkeletonView()
                .frame(height: 220)
                .padding(.horizontal)
            HStack(spacing: 20) {
                SkeletonView().frame(width: 80, height: 40)
                SkeletonView().frame(width: 80, height: 40)
                SkeletonView().frame(width: 80, height: 40)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Error
    private func errorFallback(error: String) -> some View {
        VStack(spacing: 12) {
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            Button("Retry") {
                fetchData()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Chart
    private var chartSection: some View {
        Chart(insightsVM.dataPoints) { point in
            let yVal = valueForMetric(point)
            AreaMark(
                x: .value("Time", point.time),
                y: .value(selectedMetric.rawValue, yVal)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [colorForMetric().opacity(0.3), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            LineMark(
                x: .value("Time", point.time),
                y: .value(selectedMetric.rawValue, yVal)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(colorForMetric())
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if selectedMetric == .price, let price = value.as(Double.self) {
                    AxisValueLabel(String(format: "$%.2f", price))
                } else {
                    AxisValueLabel()
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks()
        }
        .frame(height: 220)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    private func fetchData() {
        insightsVM.fetchLiveData(coinID: selectedCoin.id, timeFrame: selectedTimeFrame)
    }
    private func valueForMetric(_ p: MarketDataPoint) -> Double {
        switch selectedMetric {
        case .price:     return p.price
        case .volume:    return p.volume
        case .marketCap: return p.marketCap
        }
    }
    private func colorForMetric() -> Color {
        switch selectedMetric {
        case .price:     return .blue
        case .volume:    return .green
        case .marketCap: return .orange
        }
    }
}

// MARK: - A small helper for decoding dynamic arrays from Binance
struct AnyDecodable: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        if let intVal = try? decoder.singleValueContainer().decode(Int.self) {
            value = intVal
        } else if let dblVal = try? decoder.singleValueContainer().decode(Double.self) {
            value = dblVal
        } else if let strVal = try? decoder.singleValueContainer().decode(String.self) {
            value = strVal
        } else if let boolVal = try? decoder.singleValueContainer().decode(Bool.self) {
            value = boolVal
        } else {
            value = ""
        }
    }
}

// MARK: - Previews

struct MarketInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        MarketInsightsView()
            .preferredColorScheme(.dark)
    }
}
