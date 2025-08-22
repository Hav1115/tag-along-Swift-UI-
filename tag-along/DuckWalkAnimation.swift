//
//  DuckWalkAnimation.swift
//  tag-along
//
//  Created by Havish Komatreddy on 8/6/25.
//

import SwiftUI

struct DuckWalkAnimationView: View {
  @EnvironmentObject var router: Router

  // start off‐screen
  @State private var xOffset: CGFloat = -150
  // toggle between left/right foot
  @State private var frameIndex = 0

  // how long to cross
  private let walkDuration: Double = 3
  // how fast to swap feet
  private let frameInterval: Double = 0.25
  private let footFrames = ["duckL", "duckR"]

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color(hex: "#F7F7F2").ignoresSafeArea()

        Image(footFrames[frameIndex])
          .resizable()
          .frame(width: 100, height: 100)
          .offset(
            x: xOffset,
            y: (geo.size.height / 2) - 50
          )
      }
      .onAppear {
        // 1) march across
        withAnimation(.linear(duration: walkDuration)) {
          xOffset = geo.size.width + 150
        }
        // 2) flip feet
        Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { timer in
          frameIndex = (frameIndex + 1) % footFrames.count
        }
        // 3) when done, go home
        DispatchQueue.main.asyncAfter(deadline: .now() + walkDuration) {
          router.route = .tabs(start: 0)
        }
      }
    }
  }
}
