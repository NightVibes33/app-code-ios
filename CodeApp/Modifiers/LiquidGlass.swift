//
//  LiquidGlass.swift
//  App Code
//
//  iOS 26 Liquid Glass helpers for App Code surfaces.
//

import SwiftUI

extension View {
    @ViewBuilder
    func appCodeGlassPanel(cornerRadius: CGFloat = 14, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
