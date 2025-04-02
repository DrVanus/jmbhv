import SwiftUI
import WalletConnectSign

// Manager to handle WalletConnect initialization and connection
class WalletConnectManager: ObservableObject {
    @Published var pairingURI: String?
    @Published var isPairing: Bool = false

    init() {
        // Create your app metadata using the v2 API types
        let metadata = SignClient.Metadata(
            name: "CSAI1",
            description: "CSAI1 Wallet Connection Demo",
            url: "https://yourapp.com",
            icons: ["https://yourapp.com/icon.png"]
        )
        // Replace with your actual project ID from WalletConnect Cloud
        let config = SignClient.Config(projectId: "your_project_id_here", metadata: metadata)
        
        // Initialize the WalletConnect client
        SignClient.initialize(config: config) { result in
            switch result {
            case .success(let client):
                print("WalletConnect client initialized: \(client)")
            case .failure(let error):
                print("Failed to initialize WalletConnect: \(error)")
            }
        }
    }

    func connect() {
        // Define the permissions for the session (customize as needed)
        let permissions = Session.Permissions(
            blockchains: ["eip155:1"],
            methods: ["eth_sendTransaction", "eth_sign"],
            events: []
        )
        // Initiate connection; the API no longer requires a topic parameter
        SignClient.instance.connect(permissions: permissions) { result in
            switch result {
            case .success(let pairing):
                DispatchQueue.main.async {
                    self.pairingURI = pairing.uri
                    self.isPairing = true
                }
                print("Pairing URI: \(pairing.uri)")
            case .failure(let error):
                print("Error connecting: \(error)")
            }
        }
    }
}

struct ExchangeConnectionView: View {
    @StateObject var walletManager = WalletConnectManager()
    
    // Example wallet options with display name and image asset names.
    // Replace the image names with your own asset names.
    let walletOptions: [(name: String, imageName: String)] = [
        ("MetaMask", "metamaskIcon"),
        ("Trust Wallet", "trustwalletIcon"),
        ("Rainbow", "rainbowIcon")
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Connect Your Wallet/Exchange")
                    .font(.title)
                    .padding()
                
                List(walletOptions, id: \.name) { option in
                    Button(action: {
                        // For now, simply call connect(). In a more complex implementation,
                        // you might customize the connection based on the selected wallet.
                        walletManager.connect()
                    }) {
                        HStack {
                            Image(option.imageName)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                            Text(option.name)
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                if let uri = walletManager.pairingURI {
                    VStack {
                        Text("Pairing URI:")
                            .font(.caption)
                        Text(uri)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .navigationTitle("Connect Wallet")
        }
    }
}

struct ExchangeConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeConnectionView()
    }
}
