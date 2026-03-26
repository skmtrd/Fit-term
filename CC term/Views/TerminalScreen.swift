//
//  TerminalScreen.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct TerminalScreen: View {
    @Bindable var viewModel: TerminalViewModel
    @Query private var snippets: [Snippet]

    var body: some View {
        VStack(spacing: 0) {
            SwiftTerminalView(viewModel: viewModel)

            // スニペットバー（キーボード拡張エリアの上）
            if !snippets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(snippets) { snippet in
                            Button {
                                let data = Data(snippet.commandToSend.utf8)
                                viewModel.sendToShell(data)
                            } label: {
                                Text(snippet.label)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .background(Color(.systemGray6))
            }
        }
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
