import SwiftUI
import UIKit

// Data model for an Exchange or Wallet
struct ExchangeItem: Identifiable {
    let id = UUID()
    let name: String
}

// Sample lists for exchanges and wallets
private let sampleExchanges: [ExchangeItem] = [
    ExchangeItem(name: "Binance"),
    ExchangeItem(name: "Binance US"),
    ExchangeItem(name: "Coinbase Pro"),
    ExchangeItem(name: "Kraken"),
    ExchangeItem(name: "KuCoin"),
    ExchangeItem(name: "Bitstamp"),
    ExchangeItem(name: "Poloniex"),
    ExchangeItem(name: "Bittrex"),
    ExchangeItem(name: "OKX"),
    ExchangeItem(name: "Huobi"),
    ExchangeItem(name: "Gemini"),
    ExchangeItem(name: "Gate.io"),
    ExchangeItem(name: "BitMEX"),
    ExchangeItem(name: "Bybit"),
    ExchangeItem(name: "Deribit"),
    ExchangeItem(name: "Binance Futures")
]

private let sampleWallets: [ExchangeItem] = [
    ExchangeItem(name: "MetaMask"),
    ExchangeItem(name: "Trust Wallet"),
    ExchangeItem(name: "Rainbow"),
    ExchangeItem(name: "Exodus"),
    ExchangeItem(name: "Ledger Live"),
    ExchangeItem(name: "Trezor")
]

// Dictionary mapping exchange names to asset logo names
private let brandLogoMap: [String: String] = [
    "Binance": "binanceLogo",
    "Binance US": "binanceUSLogo",
    "Coinbase Pro": "coinbaseProLogo",
    "Kraken": "krakenLogo",
    "KuCoin": "kucoinLogo",
    "Bitstamp": "bitstampLogo",
    "Poloniex": "poloniexLogo",
    "Bittrex": "bittrexLogo",
    "OKX": "okxLogo",
    "Huobi": "huobiLogo",
    "Gemini": "geminiLogo",
    "Gate.io": "gateLogo",
    "BitMEX": "bitmexLogo",
    "Bybit": "bybitLogo",
    "Deribit": "deribitLogo",
    "Binance Futures": "binanceFuturesLogo"
]

// Dictionary mapping wallet names to asset logo names
private let walletLogoMap: [String: String] = [
    "MetaMask": "metamaskLogo",
    "Trust Wallet": "trustWalletLogo",
    "Rainbow": "rainbowLogo",
    "Exodus": "exodusLogo",
    "Ledger Live": "ledgerLiveLogo",
    "Trezor": "trezorLogo"
]

struct ExchangesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Toggle search bar visibility and hold search text
    @State private var showSearch = false
    @State private var searchText = ""
    
    // Two-column grid layout
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 16),
        GridItem(.flexible(minimum: 140), spacing: 16)
    ]
    
    // Filtered lists
    private var filteredExchanges: [ExchangeItem] {
        sampleExchanges.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredWallets: [ExchangeItem] {
        sampleWallets.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Futuristic background from your Theme.swift
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom top bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Exchanges & Wallets")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    }) {
                        Image(systemName: showSearch ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Search bar toggle
                if showSearch {
                    HStack {
                        TextField("Search", text: $searchText)
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Spacer()
                                    if !searchText.isEmpty {
                                        Button(action: { searchText = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding(.trailing, 8)
                                        }
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Exchanges Section
                        Text("Exchanges")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredExchanges) { exchange in
                                NavigationLink(destination: ExchangeDetailView(item: exchange)) {
                                    ExchangeGridCard(
                                        name: exchange.name,
                                        logo: brandLogoMap[exchange.name]
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Wallets Section
                        Text("Wallets")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredWallets) { wallet in
                                NavigationLink(destination: ExchangeDetailView(item: wallet)) {
                                    ExchangeGridCard(
                                        name: wallet.name,
                                        logo: walletLogoMap[wallet.name]
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - ExchangeGridCard
/// A gradient “card” displaying the exchange/wallet name, an optional logo, and a Connect button.
struct ExchangeGridCard: View {
    let name: String
    let logo: String?
    
    var body: some View {
        ZStack {
            // Custom gradient using brand colors from assets "BrandPrimary" and "BrandSecondary"
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("BrandPrimary").opacity(0.5),
                    Color("BrandSecondary").opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                // Display logo if available; fallback to a question mark icon
                if let logoName = logo, !logoName.isEmpty {
                    Image(logoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        // Connect logic goes here (or navigate to details)
                    }) {
                        Text("Connect")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(12)
        }
        .frame(height: 130)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
        .scaleEffect(0.98)
        .animation(.easeInOut, value: name)
    }
}

// MARK: - ExchangeDetailView
/// A detail view with a custom top bar for navigation.
struct ExchangeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let item: ExchangeItem
    
    var body: some View {
        ZStack {
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom top bar with a back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    // Extra space for symmetry
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                Text("More details and connection options go here. You can manage your account, view real-time data, and access advanced trading tools.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
struct ExchangesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExchangesView()
        }
    }
}
