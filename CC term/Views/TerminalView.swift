//
//  TerminalView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct TerminalView: View {
    @Bindable var viewModel: TerminalViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.outputLines) { line in
                            Text(line.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(color(for: line.type))
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.black)
                .onChange(of: viewModel.outputLines.count) {
                    if let last = viewModel.outputLines.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input area
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)

                TextField("コマンドを入力...", text: $viewModel.commandInput)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await viewModel.sendCommand() }
                    }

                Button {
                    Task { await viewModel.sendCommand() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.commandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(8)
            .background(Color(.systemGray6))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Terminal")
                    .font(.system(.headline, design: .monospaced))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("切断") {
                    Task { await viewModel.disconnect() }
                }
                .foregroundStyle(.red)
            }
        }
    }

    private func color(for type: TerminalViewModel.LineType) -> Color {
        switch type {
        case .command: .green
        case .stdout: .white
        case .stderr: .red
        case .system: .yellow
        }
    }
}
