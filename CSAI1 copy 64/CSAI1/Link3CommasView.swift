//
//  Link3CommasView.swift
//  CSAI1
//
//  Created by DM on 4/2/25.
//


import SwiftUI

struct Link3CommasView: View {
    @State private var apiKey = ""
    @State private var apiSecret = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Your 3Commas API Credentials")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("API Secret", text: $apiSecret)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Save") {
                // Save credentials (for demo purposes, using UserDefaults)
                UserDefaults.standard.set(apiKey, forKey: "ThreeCommasAPIKey")
                UserDefaults.standard.set(apiSecret, forKey: "ThreeCommasAPISecret")
                // Optionally, trigger an API test call to verify credentials here.
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}