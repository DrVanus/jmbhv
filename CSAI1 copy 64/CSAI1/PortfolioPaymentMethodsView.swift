import SwiftUI

/// Official 3commas brand color (#14c9bc)
private let threeCommasColor = Color(red: 0.078, green: 0.784, blue: 0.737)

struct PortfolioPaymentMethodsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showLinkSheet = false
    @State private var showInfoPanel = false  // Toggles the display of help info
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                ZStack {
                    // Subtle black accent circle behind the header text
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 30)
                        .offset(y: -180)
                        .scaleEffect(1.3)
                    
                    VStack(spacing: 24) {
                        // Reintroduced smaller “Payment Methods” title at the top
                        Text("Payment Methods")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Main header: “Connect your Exchanges & Wallets”
                        Text("Connect Your Exchanges & Wallets")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, -4) // Slightly pull this up
                        
                        // Subtitle
                        Text("Link your crypto exchange accounts and wallets to trade directly from within the app.")
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 20)
                        
                        // Link 3commas button
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
                            .background(threeCommasColor)
                            .cornerRadius(12)
                            .shadow(color: threeCommasColor.opacity(0.4), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal, 40)
                        
                        // “View All Exchanges & Wallets” button with a solid blue background
                        NavigationLink {
                            ExchangesView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "link.circle.fill")
                                    .font(.title2)
                                Text("View All Exchanges & Wallets")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal, 40)
                        
                        // Collapsible info panel toggle
                        Button {
                            withAnimation {
                                showInfoPanel.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showInfoPanel ? "questionmark.circle.fill" : "questionmark.circle")
                                    .font(.title3)
                                Text(showInfoPanel ? "Hide Info" : "Show Info")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                        }
                        
                        // Collapsible info panel content
                        if showInfoPanel {
                            // Info: How It Works
                            InfoCardView(
                                title: "How It Works",
                                message: """
                                By linking your exchange or wallet via 3commas, you establish a secure API connection. Your credentials remain protected on 3commas servers, and CryptoSage AI only accesses your trading and balance data. Once connected, you can:
                                • Track real-time balances across your exchanges and portfolio
                                • Place trades from one unified interface
                                • Monitor markets and adjust positions quickly
                                • Leverage our AI insights to optimize your portfolio and uncover new trading opportunities
                                """
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                            
                            // Info: Need Help?
                            InfoCardView(
                                title: "Need Help?",
                                message: """
                                For detailed setup instructions or troubleshooting, visit our Support page. Contact us directly if you have any questions about linking your accounts and wallets.
                                """
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Disclaimer at the bottom
                        Text("All exchange connections are handled securely via 3commas.\nYour credentials are never stored on our servers.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
            .background(FuturisticBackground()) // Themed background from Theme.swift
            .toolbar {
                // Custom white icon-only back button with a slightly smaller icon
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showLinkSheet) {
                Link3CommasView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - InfoCardView
struct InfoCardView: View {
    let title: String
    let message: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if #available(iOS 15.0, *) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            } else {
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
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.easeInOut, value: title)
    }
}
