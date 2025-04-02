import SwiftUI

private let brandAccent = Color("BrandAccent")

struct PortfolioPaymentMethodsView: View {
    @State private var showLinkSheet = false
    
    var body: some View {
        NavigationView {
            // ScrollView to allow more flexible layouts and avoid cutoff on smaller screens.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Title & subtitle
                    VStack(spacing: 8) {
                        Text("Connect Exchanges & Wallets")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        Text("Add or link your crypto exchange accounts and wallets here to trade directly from the app.")
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Link 3commas button with custom styling & icon
                    Button {
                        showLinkSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "link.circle.fill")
                                .font(.title2)
                            Text("Link Now (3commas)")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(brandAccent)
                        .cornerRadius(12)
                        .shadow(color: brandAccent.opacity(0.4), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    
                    // “View All Exchanges & Wallets” section with a card-like style
                    NavigationLink {
                        ExchangesView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "tray.full.fill")
                                .font(.title2)
                            Text("View All Exchanges & Wallets")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    
                    // Example: A "How it works" info card (optional)
                    InfoCardView(
                        title: "How It Works",
                        message: "Securely connect your exchange or wallet via 3commas. Manage trades and balances directly from one interface."
                    )
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 40)
            }
            .background(FuturisticBackground()) // Themed background from your Theme.swift
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLinkSheet) {
                Link3CommasView()
            }
        }
    }
}

struct InfoCardView: View {
    let title: String
    let message: String
    
    // A simple glassy/blurry card style (iOS 15+). Fallback to a dark background if earlier iOS.
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if #available(iOS 15.0, *) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            } else {
                // Fallback for older iOS
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.4))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.easeInOut, value: title) // Subtle animation when text changes
    }
}

// MARK: - Previews

struct PortfolioPaymentMethodsView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioPaymentMethodsView()
    }
}
