//
//  ChapterOne.swift
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/26/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import MetalKit
import SwiftUI

final class ChapterOneView: NSView {
    let mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())

    init() {
        super.init(frame: .zero)
        self.addSubview(mtkView)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        mtkView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        mtkView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mtkView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        mtkView.delegate = self

        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setClearColor(_ color: NSColor) {
        mtkView.clearColor = MTLClearColor(red: Double(color.redComponent), green: Double(color.greenComponent), blue: Double(color.blueComponent), alpha: 1)
        mtkView.setNeedsDisplay(mtkView.bounds)
    }
}

extension ChapterOneView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Drawable size changed to: \(size)")
    }

    func draw(in view: MTKView) {
        guard let device = view.device else {
            print("Error: no metal device")
            return
        }

        guard let commandQueue = device.makeCommandQueue() else {
            print("Error: unable to make command queue")
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Error: unable to make command buffer")
            return
        }

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("Error: no render pass descriptor")
            return
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Error: no encoder")
            return
        }

        encoder.endEncoding()

        if let currentDrawable = view.currentDrawable {
            commandBuffer.present(currentDrawable)
        }

        commandBuffer.commit()
    }
}

struct ChapterOneRepresentable: NSViewRepresentable {
    let color: NSColor

    func makeNSView(context: NSViewRepresentableContext<ChapterOneRepresentable>) -> ChapterOneView {
        return ChapterOneView()
    }

    func updateNSView(_ nsView: ChapterOneView, context: NSViewRepresentableContext<ChapterOneRepresentable>) {
        nsView.setClearColor(color)
    }
}

struct ChapterOne: View {
    @State var color: NSColor = .red

    var body: some View {
        VStack(spacing: 0) {
            ChapterOneRepresentable(color: color)
            HStack(spacing: 10) {
                ForEach(Array([
                    NSColor.red,
                    NSColor.blue,
                    NSColor.green
                ].enumerated()), id: \.0) { (index, color) in
                    Rectangle().frame(width: 50, height: 50).foregroundColor(Color(color)).padding(8)
                        .onTapGesture {
                            self.color = color
                        }
                }
                Spacer()
            }.padding()
        }
    }
}
