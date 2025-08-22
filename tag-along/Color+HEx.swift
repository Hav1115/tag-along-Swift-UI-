//
//  Color+HEx.swift
//  tag-along
//
//  Created by Havish Komatreddy on 8/3/25.
//

import SwiftUI

extension Color {
  /// Initialize from a hex string, e.g. "#A1B2C3" or "A1B2C3"
  init(hex: String) {
    // 1. Strip out non-hex characters (like “#”)
    let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
    var int:  UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)

    // 2. Extract R/G/B
    let r, g, b: UInt64
    if hex.count == 6 {
      r = (int >> 16) & 0xFF
      g = (int >>  8) & 0xFF
      b =  int        & 0xFF
    } else {
      // fallback to black on invalid input
      r = 0; g = 0; b = 0
    }

    // 3. Initialize Color
    self.init(
      red:   Double(r) / 255,
      green: Double(g) / 255,
      blue:  Double(b) / 255
    )
  }
}
