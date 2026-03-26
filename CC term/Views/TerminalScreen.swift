//
//  TerminalScreen.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct TerminalScreen: View {
    @Bindable var viewModel: TerminalViewModel

    var body: some View {
        SwiftTerminalView(viewModel: viewModel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.title)
                        .font(.system(.headline, design: .monospaced))
                        .lineLimit(1)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("切断") {
                        Task { await viewModel.disconnect() }
                    }
                    .foregroundStyle(.red)
                }
            }
    }
}
