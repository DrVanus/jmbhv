import SwiftUI

private let brandAccent = Color("BrandAccent")

struct PortfolioPaymentMethodsView: View {
    @State private var showLinkSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Connect Exchanges & Wallets")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add or link your crypto exchange accounts and wallets here to trade directly from the app.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Option for linking with a 3commas account.
                Button("Link Now (3commas)") {
                    showLinkSheet = true
                }
                .padding()
                .foregroundColor(.white)
                .background(brandAccent)
                .cornerRadius(8)
                
                // Navigation option to view the exchanges and wallets.
                NavigationLink(destination: ExchangesView()) {
                    Text("View All Exchanges & Wallets")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FuturisticBackground())
            .sheet(isPresented: $showLinkSheet) {
                Link3CommasView()
            }
            .navigationTitle("Payment Methods")
        }
    }
}

struct PortfolioPaymentMethodsView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioPaymentMethodsView()
    }
}
