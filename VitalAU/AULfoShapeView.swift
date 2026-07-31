//
//  AULfoShapeView.swift
//  VitalAU
//
//  Editable LFO shape with Vital-style control-point dots + segment power handles.
//

import SwiftUI

enum AULfoShapeClipboard {
    static var data: Data?
}

struct AULfoShapeView: View {
    @ObservedObject var viewModel: VitalAUViewModel
    var lfoIndex: Int
    var color: Color = VitalColors.modTeal
    var reloadToken: Int = 0
    var gridSnap: Bool = false

    @State private var points: [VitalAUViewModel.LfoPoint] = []
    @State private var powers: [Float] = []
    @State private var buffer: [Float] = Array(repeating: 0.5, count: 256)
    @State private var dragIndex: Int? = nil
    @State private var dragPowerIndex: Int? = nil
    @State private var lastDragY: CGFloat = 0

    private let maxPower: Float = 20
    private let powerMouseMult: Float = 9

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Optional grid
                if gridSnap {
                    Canvas { ctx, sz in
                        for i in 1..<8 {
                            let x = CGFloat(i) / 8 * sz.width
                            var p = Path()
                            p.move(to: .init(x: x, y: 0))
                            p.addLine(to: .init(x: x, y: sz.height))
                            ctx.stroke(p, with: .color(.white.opacity(0.06)), lineWidth: 1)
                        }
                        for i in 1..<4 {
                            let y = CGFloat(i) / 4 * sz.height
                            var p = Path()
                            p.move(to: .init(x: 0, y: y))
                            p.addLine(to: .init(x: sz.width, y: y))
                            ctx.stroke(p, with: .color(.white.opacity(0.06)), lineWidth: 1)
                        }
                    }
                }

                Canvas { ctx, sz in
                    guard buffer.count > 1 else { return }
                    var path = Path()
                    let n = buffer.count
                    for i in 0..<n {
                        let x = CGFloat(i) / CGFloat(n - 1) * sz.width
                        let y = (1 - CGFloat(buffer[i])) * sz.height
                        if i == 0 { path.move(to: .init(x: x, y: y)) }
                        else { path.addLine(to: .init(x: x, y: y)) }
                    }
                    var fill = path
                    fill.addLine(to: .init(x: sz.width, y: sz.height))
                    fill.addLine(to: .init(x: 0, y: sz.height))
                    fill.closeSubpath()
                    ctx.fill(fill, with: .color(color.opacity(0.12)))
                    ctx.stroke(path, with: .color(color.opacity(0.9)),
                               style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                }

                // Power handles (filled small dots between points)
                ForEach(powerHandleIndices, id: \.self) { i in
                    let pos = powerPosition(index: i)
                    Circle()
                        .fill(color.opacity(0.85))
                        .frame(width: 7, height: 7)
                        .position(x: CGFloat(pos.x) * size.width,
                                  y: CGFloat(pos.y) * size.height)
                }

                // Point rings
                ForEach(points.indices, id: \.self) { i in
                    let p = points[i]
                    Circle()
                        .strokeBorder(color, lineWidth: 1.5)
                        .background(Circle().fill(VitalColors.widgetBg))
                        .frame(width: 10, height: 10)
                        .position(x: CGFloat(p.x) * size.width,
                                  y: CGFloat(p.y) * size.height)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragIndex == nil && dragPowerIndex == nil {
                            if let pi = nearestPower(to: g.startLocation, in: size) {
                                dragPowerIndex = pi
                                lastDragY = g.startLocation.y
                            } else {
                                dragIndex = nearestPoint(to: g.startLocation, in: size)
                            }
                        }
                        if let pi = dragPowerIndex {
                            let dy = Float((g.location.y - lastDragY) / max(size.height, 1))
                            lastDragY = g.location.y
                            var power = (powers.indices.contains(pi) ? powers[pi] : 0)
                            var fromY = points[pi].y
                            let toIdx = min(pi + 1, points.count - 1)
                            var toY = points[toIdx].y
                            var delta = dy * powerMouseMult
                            if fromY < toY { delta = -delta }
                            power = max(-maxPower, min(maxPower, power + delta))
                            _ = viewModel.setLfoPower(index: lfoIndex, pointIndex: pi, value: power)
                            reload()
                        } else if let idx = dragIndex {
                            var nx = Float(max(0, min(1, g.location.x / size.width)))
                            var ny = Float(max(0, min(1, g.location.y / size.height)))
                            if gridSnap {
                                nx = snap(nx, divisions: 8)
                                ny = snap(ny, divisions: 4)
                            }
                            _ = viewModel.setLfoPoint(index: lfoIndex, pointIndex: idx, x: nx, y: ny)
                            reload()
                        }
                    }
                    .onEnded { _ in
                        dragIndex = nil
                        dragPowerIndex = nil
                    }
            )
            .onAppear { reload() }
            .onChange(of: lfoIndex) { _ in reload() }
            .onChange(of: reloadToken) { _ in reload() }
            .onChange(of: gridSnap) { _ in reload() }
        }
        .contextMenu {
            Button("Copy Shape") {
                AULfoShapeClipboard.data = viewModel.lfoStateJSON(index: lfoIndex)
            }
            Button("Paste Shape") {
                guard let data = AULfoShapeClipboard.data else { return }
                _ = viewModel.setLfoStateJSON(index: lfoIndex, data: data)
                reload()
            }
            .disabled(AULfoShapeClipboard.data == nil)
            Divider()
            Button("Add Point") {
                let midX: Float = 0.5
                var after = 0
                for i in 0..<(points.count - 1) {
                    if points[i].x <= midX { after = i }
                }
                let y: Float = points.isEmpty ? 0.5
                    : (points[after].y + points[min(after + 1, points.count - 1)].y) * 0.5
                _ = viewModel.addLfoPoint(index: lfoIndex, after: after, x: midX, y: y)
                reload()
            }
            if points.count > 2 {
                Button("Remove Mid Point", role: .destructive) {
                    let mid = points.count / 2
                    _ = viewModel.removeLfoPoint(index: lfoIndex, pointIndex: mid)
                    reload()
                }
            }
            Button("Reset Powers") {
                for i in 0..<powers.count {
                    _ = viewModel.setLfoPower(index: lfoIndex, pointIndex: i, value: 0)
                }
                reload()
            }
            Button("Flip Horizontal") {
                _ = viewModel.flipLfoHorizontal(index: lfoIndex)
                reload()
            }
            Button("Flip Vertical") {
                _ = viewModel.flipLfoVertical(index: lfoIndex)
                reload()
            }
        }
    }

    private var powerHandleIndices: [Int] {
        guard points.count >= 2 else { return [] }
        return (0..<(points.count - 1)).filter { i in
            let dx = abs(points[i + 1].x - points[i].x)
            let dy = abs(points[i + 1].y - points[i].y)
            return dx > 0.04 && dy > 0.001
        }
    }

    private func powerPosition(index: Int) -> (x: Float, y: Float) {
        guard index >= 0, index + 1 < points.count else { return (0.5, 0.5) }
        let from = points[index]
        let to = points[index + 1]
        let x = (from.x + to.x) * 0.5
        let power = powers.indices.contains(index) ? powers[index] : 0
        let t = Self.powerScale(0.5, power)
        let y = from.y + (to.y - from.y) * t
        return (x, y)
    }

    private static func powerScale(_ value: Float, _ power: Float) -> Float {
        if abs(power) < 0.01 { return value }
        return (exp(power * value) - 1) / (exp(power) - 1)
    }

    private func snap(_ v: Float, divisions: Int) -> Float {
        let d = Float(divisions)
        return (v * d).rounded() / d
    }

    private func reload() {
        points = viewModel.lfoPoints(index: lfoIndex)
        powers = viewModel.lfoPowers(index: lfoIndex)
        buffer = viewModel.lfoDisplayBuffer(index: lfoIndex)
    }

    private func nearestPoint(to location: CGPoint, in size: CGSize) -> Int? {
        guard !points.isEmpty, size.width > 1 else { return nil }
        var best = 0
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (i, p) in points.enumerated() {
            let dx = CGFloat(p.x) * size.width - location.x
            let dy = CGFloat(p.y) * size.height - location.y
            let d = dx * dx + dy * dy
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }

    private func nearestPower(to location: CGPoint, in size: CGSize) -> Int? {
        var best: Int? = nil
        var bestDist: CGFloat = 14 * 14 // hit radius ~14pt
        for i in powerHandleIndices {
            let pos = powerPosition(index: i)
            let dx = CGFloat(pos.x) * size.width - location.x
            let dy = CGFloat(pos.y) * size.height - location.y
            let d = dx * dx + dy * dy
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }
}
