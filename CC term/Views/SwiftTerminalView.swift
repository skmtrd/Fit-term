//
//  SwiftTerminalView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
@preconcurrency import SwiftTerm

struct SwiftTerminalView: UIViewRepresentable {
    let viewModel: TerminalViewModel

    func makeUIView(context: Context) -> TerminalView {
        let tv = TerminalView(frame: .zero)
        tv.terminalDelegate = context.coordinator
        tv.nativeBackgroundColor = .black
        tv.nativeForegroundColor = .white
        tv.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.isScrollEnabled = true
        viewModel.attachTerminalView(tv)
        return tv
    }

    func updateUIView(_ uiView: TerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        let viewModel: TerminalViewModel

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            viewModel.sendToShell(Data(data))
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            viewModel.resizeShell(cols: newCols, rows: newRows)
        }

        func setTerminalTitle(source: TerminalView, title: String) {
            viewModel.title = title
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func scrolled(source: TerminalView, position: Double) {}
        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}
        func clipboardCopy(source: TerminalView, content: Data) {}
        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
    }
}
