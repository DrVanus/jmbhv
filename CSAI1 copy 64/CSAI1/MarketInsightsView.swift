import SwiftUI
#if canImport(Charts)
import Charts
#endif
import Combine

// MARK: - Data Models

struct MarketDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

/// Response model for CoinGecko API
struct CoinGeckoResponse: Decodable {
    let prices: [[Double]]
    let market_caps: [[Double]]
    let total_volumes: [[Double]]
}

// MARK: - ViewModel

class MarketInsightsViewModel: ObservableObject {
    @Published var chartData: [MarketDataPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Fetch historical data from CoinGecko.
    func fetchChartData(coinId: String, timeFrame: MarketInsightsView.TimeFrame, metric: MarketInsightsView.Metric) {
        isLoading = true
        errorMessage = nil
        
        // Map time frame to days for CoinGecko API.
        let days: String
        switch timeFrame {
        case .day:   days = "1"
        case .week:  days = "7"
        case .month: days = "30"
        case .year:  days = "365"
        }
        
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coinId)/market_chart?vs_currency=usd&days=\(days)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CoinGeckoResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { response in
                var dataArray: [[Double]] = []
                switch metric {
                case .price:
                    dataArray = response.prices
                case .marketCap:
                    dataArray = response.market_caps
                case .volume:
                    dataArray = response.total_volumes
                }
                self.chartData = dataArray.compactMap { arr in
                    // Each element is [timestamp, value]
                    if arr.count >= 2 {
                        let time = Date(timeIntervalSince1970: arr[0] / 1000)
                        let value = arr[1]
                        return MarketDataPoint(time: time, value: value)
                    }
                    return nil
                }
                self.chartData.sort { $0.time < $1.time }
            }
            .store(in: &cancellables)
    }
}

// MARK: - MarketInsightsView

struct MarketInsightsView: View {
    
    // MARK: Metric and Time Frame
    enum Metric: String, CaseIterable, Identifiable {
        case price = "Price (USD)"
        case volume = "Volume"
        case marketCap = "Market Cap"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .price:     return "The average trading price in USD."
            case .volume:    return "The total trading volume over the period."
            case .marketCap: return "The overall market capitalization."
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
    
    // MARK: Properties
    let symbol: String  // e.g. "BTC", "ETH"
    @State private var selectedMetric: Metric = .price
    @State private var selectedTimeFrame: TimeFrame = .day
    @StateObject private var vm = MarketInsightsViewModel()
    
    /// Map symbol to CoinGecko coin ID.
    private var coinId: String {
        let mapping: [String: String] = [
            "BTC": "bitcoin",
            "ETH": "ethereum"
        ]
        return mapping[symbol.uppercased()] ?? symbol.lowercased()
    }
    
    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Market Insights (\(symbol.uppercased()))")
                .font(.headline)
                .foregroundColor(.white)
            
            // Metric Picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Time Frame Picker
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases) { tf in
                    Text(tf.rawValue).tag(tf)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Chart Area
            Group {
                if vm.isLoading {
                    ProgressView("Loading data...")
                        .foregroundColor(.white)
                } else if let error = vm.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if vm.chartData.isEmpty {
                    Text("No data available.")
                        .foregroundColor(.gray)
                } else {
                    if #available(iOS 16, *) {
                        Chart(vm.chartData) { point in
                            LineMark(
                                x: .value("Time", point.time),
                                y: .value(selectedMetric.rawValue, point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(colorForMetric(selectedMetric))
                        }
                        .frame(height: 180)
                    } else {
                        Text("Chart view requires iOS 16 or later.")
                            .foregroundColor(.gray)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
            
            // Explanation
            Text(selectedMetric.description)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            vm.fetchChartData(coinId: coinId, timeFrame: selectedTimeFrame, metric: selectedMetric)
        }
        .onChange(of: selectedTimeFrame) { newTF in
            vm.fetchChartData(coinId: coinId, timeFrame: newTF, metric: selectedMetric)
        }
        .onChange(of: selectedMetric) { newMetric in
            vm.fetchChartData(coinId: coinId, timeFrame: selectedTimeFrame, metric: newMetric)
        }
    }
    
    // MARK: Helper
    private func colorForMetric(_ metric: Metric) -> Color {
        switch metric {
        case .price: return .blue
        case .volume: return .green
        case .marketCap: return .orange
        }
    }
}

// MARK: - Preview

struct MarketInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MarketInsightsView(symbol: "BTC")
        }
        .preferredColorScheme(.dark)
    }
}
