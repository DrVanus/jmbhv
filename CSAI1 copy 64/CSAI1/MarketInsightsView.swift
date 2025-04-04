import SwiftUI
import Charts

// MARK: - Data Models

struct MarketDataPoint: Identifiable, Codable {
    let id = UUID()
    let time: Date
    let price: Double
    let volume: Double
    let marketCap: Double
}

struct CryptoMarketChart: Decodable {
    let prices: [[Double]]
    let market_caps: [[Double]]
    let total_volumes: [[Double]]
}

struct CoinInfo: Decodable, Identifiable {
    let id: String
    let symbol: String
    let name: String
}

// MARK: - ViewModels

class MarketInsightsViewModel: ObservableObject {
    @Published var dataPoints: [MarketDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var usingCache = false  // to indicate if we used local fallback
    
    private let cacheKey = "cachedMarketData"  // Key in UserDefaults
    
    func fetchLiveData(coinID: String, timeFrame: MarketInsightsView.TimeFrame) {
        isLoading = true
        errorMessage = nil
        usingCache = false
        dataPoints.removeAll()
        
        let days: String
        switch timeFrame {
        case .day: days = "1"
        case .week: days = "7"
        case .month: days = "30"
        case .year: days = "365"
        }
        
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinID)/market_chart?vs_currency=usd&days=\(days)"
        print("Requesting URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            self.errorMessage = "Invalid URL."
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // For a "network connection was lost" or any other network error
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Network error: \(error)")
                    // Attempt fallback from local cache
                    self.loadFromCache()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP status code: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    self.errorMessage = "No data returned from server."
                    print("No data returned from server.")
                    // Attempt fallback from local cache
                    self.loadFromCache()
                    return
                }
                
                do {
                    let cryptoData = try JSONDecoder().decode(CryptoMarketChart.self, from: data)
                    let count = min(cryptoData.prices.count,
                                    cryptoData.market_caps.count,
                                    cryptoData.total_volumes.count)
                    var points: [MarketDataPoint] = []
                    for i in 0..<count {
                        let timestamp = cryptoData.prices[i][0]
                        let date = Date(timeIntervalSince1970: timestamp / 1000)
                        let price = cryptoData.prices[i][1]
                        let marketCap = cryptoData.market_caps[i][1]
                        let volume = cryptoData.total_volumes[i][1]
                        points.append(MarketDataPoint(time: date, price: price, volume: volume, marketCap: marketCap))
                    }
                    points.sort { $0.time < $1.time }
                    self.dataPoints = points
                    print("Loaded \(points.count) data points from network.")
                    
                    // Cache the data for fallback
                    self.saveToCache(points)
                    
                } catch {
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                    // Attempt fallback from local cache
                    self.loadFromCache()
                }
            }
        }.resume()
    }
    
    // MARK: - Caching
    
    private func saveToCache(_ points: [MarketDataPoint]) {
        do {
            let encoded = try JSONEncoder().encode(points)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("Cached dataPoints to UserDefaults (\(points.count) points).")
        } catch {
            print("Failed to encode dataPoints for caching: \(error)")
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
                print("Loaded \(cachedPoints.count) data points from local cache.")
            } else {
                print("Cached data was empty.")
            }
        } catch {
            print("Error decoding cached data: \(error)")
        }
    }
}

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
        isLoading = true
        errorMessage = nil
        let urlString = "https://api.coingecko.com/api/v3/coins/list?include_platform=false"
        print("Requesting coin list from: \(urlString)")
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid URL for coin list."
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Coin list error: \(error)")
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No coin list data returned."
                    print("No coin list data.")
                    return
                }
                do {
                    self.allCoins = try JSONDecoder().decode([CoinInfo].self, from: data)
                    print("Loaded \(self.allCoins.count) coins.")
                } catch {
                    self.errorMessage = "Coin list decoding error: \(error.localizedDescription)"
                    print("Coin list decoding error: \(error)")
                }
            }
        }.resume()
    }
}

// MARK: - StatsView

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
            VStack {
                Text("Min").foregroundColor(.gray)
                Text(String(format: "$%.2f", minValue))
                    .foregroundColor(.white)
            }
            VStack {
                Text("Max").foregroundColor(.gray)
                Text(String(format: "$%.2f", maxValue))
                    .foregroundColor(.white)
            }
            VStack {
                Text("Avg").foregroundColor(.gray)
                Text(String(format: "$%.2f", avgValue))
                    .foregroundColor(.white)
            }
        }
        .font(.caption)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func valueForMetric(_ point: MarketDataPoint) -> Double {
        switch metric {
        case .price:
            return point.price
        case .volume:
            return point.volume
        case .marketCap:
            return point.marketCap
        }
    }
}

// MARK: - CoinSelectorView

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
                    Button("Retry") {
                        vm.fetchCoinList()
                    }
                    .padding(.bottom)
                }
                // Pull to refresh (iOS 15+)
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
                .refreshable {  // iOS 15 or newer
                    vm.fetchCoinList()
                }
                .searchable(text: $vm.searchText, prompt: "Search coins...")  // iOS 15 or newer
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

// MARK: - MarketInsightsView

struct MarketInsightsView: View {
    
    enum Metric: String, CaseIterable, Identifiable {
        case price = "Price (USD)"
        case volume = "Volume"
        case marketCap = "Market Cap"
        
        var id: String { rawValue }
        var description: String {
            switch self {
            case .price: return "The current price in USD."
            case .volume: return "The 24-hour trading volume."
            case .marketCap: return "The current market capitalization."
            }
        }
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "1D"
        case week = "1W"
        case month = "1M"
        case year = "1Y"
        
        var id: String { rawValue }
    }
    
    @StateObject private var insightsVM = MarketInsightsViewModel()
    @StateObject private var coinListVM = CoinListViewModel()
    
    @State private var selectedCoin: CoinInfo = CoinInfo(id: "bitcoin", symbol: "btc", name: "Bitcoin")
    @State private var selectedMetric: Metric = .price
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var showCoinSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(selectedCoin.name) Market Insights")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("View trends for a selected market metric over a given time frame.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Controls
            VStack(spacing: 12) {
                HStack {
                    Text("Coin:").foregroundColor(.gray)
                    Button {
                        showCoinSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCoin.name)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(Metric.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases) { tf in
                        Text(tf.rawValue).tag(tf)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // Chart & Stats
            Group {
                if insightsVM.isLoading {
                    ProgressView("Loading data...")
                        .foregroundColor(.white)
                        .padding()
                } else if let error = insightsVM.errorMessage {
                    // Show an error + a Retry button
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
                } else if insightsVM.dataPoints.isEmpty {
                    Text("No data available for the selected parameters.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    if insightsVM.usingCache {
                        Text("Using locally cached data.")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.horizontal)
                    }
                    chartSection
                    StatsView(dataPoints: insightsVM.dataPoints, metric: selectedMetric)
                        .padding(.horizontal)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal)
            
            // Explanation
            Text(selectedMetric.description)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear { fetchData() }
        .onChange(of: selectedMetric) { _ in fetchData() }
        .onChange(of: selectedTimeFrame) { _ in fetchData() }
        .sheet(isPresented: $showCoinSelector) {
            CoinSelectorView(vm: coinListVM) { coin in
                selectedCoin = coin
                fetchData()
            }
        }
    }
    
    private var chartSection: some View {
        Chart(insightsVM.dataPoints) { point in
            let yVal = valueForMetric(point)
            
            // Area
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
            
            // Line
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
        .chartXAxis { AxisMarks() }
        .frame(height: 200)
        .padding(.horizontal)
    }
    
    private func fetchData() {
        insightsVM.fetchLiveData(coinID: selectedCoin.id, timeFrame: selectedTimeFrame)
    }
    
    private func valueForMetric(_ point: MarketDataPoint) -> Double {
        switch selectedMetric {
        case .price:
            return point.price
        case .volume:
            return point.volume
        case .marketCap:
            return point.marketCap
        }
    }
    
    private func colorForMetric() -> Color {
        switch selectedMetric {
        case .price: return .blue
        case .volume: return .green
        case .marketCap: return .orange
        }
    }
}

// MARK: - Preview

struct MarketInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        MarketInsightsView()
            .preferredColorScheme(.dark)
    }
}
