//
//  Button.swift
//  Code
//
//  Created by Ken Chung on 11/4/2022.
//

import SwiftUI

struct NoAnim: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct SideBarButton: View {

    @State var title: String
    let onTap: () -> Void

    init(_ title: String, onTapGesture: @escaping () -> Void) {
        self._title = State.init(initialValue: title)
        self.onTap = onTapGesture
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Text(NSLocalizedString(title, comment: ""))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.init(id: "button.background"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .appCodeGlassPanel(cornerRadius: 12, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

struct SidebarActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer(minLength: 0)
            }
            .foregroundColor(isPrimary ? .white : Color("T1"))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isPrimary ? Color.accentColor : Color(id: "button.background").opacity(0.34),
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .appCodeGlassPanel(cornerRadius: 13, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

struct AppCodeSkeletonRows: View {
    var count: Int = 4

    var body: some View {
        VStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(id: "button.background").opacity(0.30))
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(id: "button.background").opacity(0.34))
                            .frame(height: 8)
                            .frame(maxWidth: index % 2 == 0 ? 130 : 96)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(id: "button.background").opacity(0.22))
                            .frame(height: 7)
                            .frame(maxWidth: index % 2 == 0 ? 92 : 116)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(Color(id: "sideBar.background").opacity(0.50), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .redacted(reason: .placeholder)
    }
}
