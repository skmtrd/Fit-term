//
//  KeyboardExtensionView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct KeyboardExtensionView: View {
    let sendToShell: (Data) -> Void
    let toggleKeyboard: () -> Void
    let closeTab: () -> Void
    let newTab: () -> Void
    @Query private var layouts: [KeyboardLayout]
    @Query private var snippets: [Snippet]

    private var layout: KeyboardLayout? { layouts.first }

    var body: some View {
        if let layout, !layout.buttons.isEmpty {
            let gridRows = layout.rows
            let gridCols = layout.columns

            GeometryReader { geo in
                let cellSize = geo.size.width / CGFloat(gridCols)

                ZStack(alignment: .topLeading) {
                    ForEach(layout.buttons) { button in
                        KeyButtonView(button: button) {
                            sendAction(button)
                        }
                        .frame(
                            width: cellSize * CGFloat(button.colSpan) - 6,
                            height: cellSize * CGFloat(button.rowSpan) - 6
                        )
                        .position(
                            x: cellSize * (CGFloat(button.col) + CGFloat(button.colSpan) / 2),
                            y: cellSize * (CGFloat(button.row) + CGFloat(button.rowSpan) / 2)
                        )
                    }
                }
            }
            .frame(height: CGFloat(gridRows) * cellSizeEstimate)
            .background(Color(.systemGray6))
        }
    }

    private var cellSizeEstimate: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let gridCols = layouts.first?.columns ?? 4
        return screenWidth / CGFloat(gridCols + 1)
    }

    private func sendAction(_ button: KeyboardButton) {
        switch button.actionType {
        case "key":
            if button.keyActionRawValue == KeyAction.toggleKeyboard.rawValue {
                toggleKeyboard()
                return
            }
            if button.keyActionRawValue == KeyAction.closeTab.rawValue {
                closeTab()
                return
            }
            if button.keyActionRawValue == KeyAction.newTab.rawValue {
                newTab()
                return
            }
            guard let bytes = button.keyBytes else { return }
            sendToShell(bytes)
        case "snippet":
            guard let snippet = snippets.first(where: { $0.id == button.snippetId }) else { return }
            sendToShell(Data(snippet.commandToSend.utf8))
        default:
            break
        }
    }
}

// MARK: - Shared Button View

struct KeyButtonView: View {
    let button: KeyboardButton
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if button.hasIcon {
                    Image(systemName: button.iconName)
                        .font(.system(size: 16))
                } else {
                    Text(button.label)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray5))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
