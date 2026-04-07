//
//  TranscriptionConfirmView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct TranscriptionConfirmView: View {
    @Binding var text: String
    let onSend: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(minHeight: 120)

                HStack(spacing: 16) {
                    Button {
                        onCancel()
                    } label: {
                        Text("キャンセル")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }

                    Button {
                        onSend(text)
                    } label: {
                        Text("送信")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(text.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(text.isEmpty)
                }
            }
            .padding()
            .navigationTitle("文字起こし結果")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
