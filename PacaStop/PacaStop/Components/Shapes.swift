//
//  Shapes.swift
//  PacaStop
//
//  Small custom shapes used across the design (the streak "flame" triangle, etc.).
//

import SwiftUI

/// An upward-pointing triangle — the streak-chip "flame".
struct UpTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
