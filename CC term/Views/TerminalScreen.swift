//
//  TerminalScreen.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct TerminalScreen: View {
    @Bindable var viewModel: TerminalViewModel

    var body: some View {
        SwiftTerminalView(viewModel: viewModel)
    }
}
