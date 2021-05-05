//
//  Color+Figma.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

extension Color {
    // Converts HSB values from Figma into SwiftUI's colorspace.
    // Reference:: https://stackoverflow.com/a/39144203/8639572
    static func hsb(_ hue: Double, _ saturation: Double, _ brightness: Double) -> Color {
        return Color(hue: hue / 360, saturation: saturation / 100, brightness: brightness / 100)
    }

    // Based on Actions. Refer to Figma
    static let baseBackground = Self.black
    static let baseCard = hsb(214, 21, 13)

    static let modalBackground = hsb(210, 24, 13)
    static let modalCard = hsb(213, 24, 18)

    static let sheetBackground = hsb(212, 27, 19)
}
