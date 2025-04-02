//
//  Exchange.swift
//  CSAI1
//
//  Created by DM on 4/2/25.
//


import SwiftUI

// Dummy models for exchanges and wallets
struct Exchange: Identifiable {
    let id = UUID()
    let name: String
    let logoURL: String // Replace with your actual image handling later
}

struct Wallet: Identifiable {
    let id = UUID()
    let name: String
    let logoURL: String // Replace with your actual image handling later
}

struct ExchangesView: View {
    // Dummy data – replace with your real data sources later.
    let exchanges = [
        Exchange(name: "Binance", logoURL: "binance_logo_placeholder"),
        Exchange(name: "Coinbase", logoURL: "coinbase_logo_placeholder"),
        Exchange(name: "Kraken", logoURL: "kraken_logo_placeholder")
    ]
    
    let wallets = [
        Wallet(name: "MetaMask", logoURL: "metamask_logo_placeholder"),
        Wallet(name: "Trust Wallet", logoURL: "trustwallet_logo_placeholder"),
        Wallet(name: "Rainbow", logoURL: "rainbow_logo_placeholder")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Exchanges").font(.headline)) {
                    ForEach(exchanges) { exchange in
                        HStack(spacing: 15) {
                            // Replace with AsyncImage or your custom image loader if needed.
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .cornerRadius(5)
                            Text(exchange.name)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Wallets").font(.headline)) {
                    ForEach(wallets) { wallet in
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .cornerRadius(5)
                            Text(wallet.name)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Exchanges & Wallets")
        }
    }
}

struct ExchangesView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangesView()
    }
}