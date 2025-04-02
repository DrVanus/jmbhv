//
//  PortfolioPaymentMethodsView.swift
//  CSAI1
//
//  Created by DM on 4/2/25.
//


import SwiftUI

private let brandAccent = Color("BrandAccent")

struct PortfolioPaymentMethodsView: View {
    @State private var showLinkSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Connect Exchanges & Wallets")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Add or link your crypto exchange accounts and wallets here to trade directly from the app.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Link Now") {
                showLinkSheet = true
            }
            .padding()
            .foregroundColor(.white)
            .background(brandAccent)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuturisticBackground())
        .sheet(isPresented: $showLinkSheet) {
            Link3CommasView()
        }
    }
}