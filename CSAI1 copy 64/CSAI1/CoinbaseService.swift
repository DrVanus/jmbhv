//
//  CoinbaseService.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//  Updated with improved error handling, retry logic, and coin pair filtering
//

import Foundation

struct CoinbaseSpotPriceResponse: Decodable {
    let data: DataField?

    struct DataField: Decodable {
        let base: String      // e.g., "BTC"
        let currency: String  // e.g., "USD"
        let amount: String    // e.g., "27450.12"
    }
}

actor CoinbaseService {
    
    // A list of known valid coin pairs. Update as needed.
    private let validPairs: Set<String> = [
        "BTC-USD", "ETH-USD", "USDT-USD", "XRP-USD", "BNB-USD",
        "USDC-USD", "SOL-USD", "DOGE-USD", "ADA-USD", "TRX-USD",
        "WBTC-USD", "WETH-USD", "WEETH-USD", "UNI-USD", "DAI-USD",
        "APT-USD", "TON-USD", "LINK-USD", "XLM-USD", "WSTETH-USD",
        "AVAX-USD", "SUI-USD", "SHIB-USD", "HBAR-USD", "LTC-USD",
        "OM-USD", "DOT-USD", "BCH-USD", "SUSDE-USD", "AAVE-USD",
        "ATOM-USD", "CRO-USD", "NEAR-USD", "PEPE-USD", "OKB-USD",
        "CBBTC-USD", "GT-USD"
    ]
    
    /// Asynchronously fetch the spot price for a given coin (default "BTC") in a specified fiat (default "USD").
    /// Returns a Double value if successful; otherwise, returns nil.
    func fetchSpotPrice(coin: String = "BTC", fiat: String = "USD", maxRetries: Int = 3) async -> Double? {
        let coinPair = "\(coin.uppercased())-\(fiat.uppercased())"
        
        // Skip unsupported pairs immediately
        if !validPairs.contains(coinPair) {
            print("CoinbaseService: \(coinPair) is not in the list of valid pairs.")
            return nil
        }
        
        let endpoint = "https://api.coinbase.com/v2/prices/\(coinPair)/spot"
        guard let url = URL(string: endpoint) else {
            print("CoinbaseService: Invalid URL: \(endpoint)")
            return nil
        }
        
        var attempt = 0
        while attempt < maxRetries {
            attempt += 1
            do {
                // Configure custom timeout intervals
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 10
                config.timeoutIntervalForResource = 15
                let session = URLSession(configuration: config)
                
                let (data, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if !(200...299).contains(httpResponse.statusCode) {
                        print("CoinbaseService: HTTP status code = \(httpResponse.statusCode) on attempt \(attempt) for \(coinPair)")
                        if httpResponse.statusCode == 404 || httpResponse.statusCode == 400 {
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("CoinbaseService: Response body = \(responseString)")
                            }
                            print("CoinbaseService: Coin pair \(coinPair) appears to be invalid. Aborting retries.")
                            return nil
                        }
                    }
                }
                
                let decoded = try JSONDecoder().decode(CoinbaseSpotPriceResponse.self, from: data)
                guard let dataField = decoded.data else {
                    print("CoinbaseService: 'data' field was missing in the response on attempt \(attempt).")
                    return nil
                }
                
                if let price = Double(dataField.amount) {
                    print("CoinbaseService: Successfully fetched price \(price) for \(coinPair) on attempt \(attempt)")
                    return price
                } else {
                    print("CoinbaseService: Failed to convert amount \(dataField.amount) to Double on attempt \(attempt)")
                    return nil
                }
                
            } catch {
                print("CoinbaseService error on attempt \(attempt) for \(coinPair): \(error.localizedDescription)")
                if attempt < maxRetries {
                    let delaySeconds = Double(attempt * 2)
                    print("CoinbaseService: Retrying in \(delaySeconds) seconds...")
                    try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                } else {
                    print("CoinbaseService: All attempts failed for \(coinPair). Last error: \(error.localizedDescription)")
                    return nil
                }
            }
        }
        return nil
    }
}
