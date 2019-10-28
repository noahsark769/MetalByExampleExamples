//
//  ChapterTwo.swift
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI

/// Goal of Chapter Three is to create a triangle on screen whose pixels are interpolated between red/blue/green based on their distance
/// from the points of the triangle.

final class ChapterThreeView: NSView {
    private let mtkView: MTKView
    private let vertices: [ChapterThreeVertexInOut]
    private let vertexBuffer: MTLBuffer
    private let pipelineState: MTLRenderPipelineState

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("This doesn't have a suitable GPU!")
        }
        self.mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())

        let vertices = [
            ChapterThreeVertexInOut(position: SIMD4<Float>(0, 0.5, 0, 1), color: SIMD4<Float>(1, 0, 0, 1)),
            ChapterThreeVertexInOut(position: SIMD4<Float>(-0.5, -0.5, 0, 1), color: SIMD4<Float>(0, 1, 0, 1)),
            ChapterThreeVertexInOut(position: SIMD4<Float>(0.5, -0.5, 0, 1), color: SIMD4<Float>(0, 0, 1, 1)),
        ]
        guard let vertexBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(mutating: vertices), length: MemoryLayout<ChapterThreeVertexInOut>.size * vertices.count, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate vertex buffer")
        }
        self.vertexBuffer = vertexBuffer
        self.vertices = vertices // we need to retain this since we're passing in a raw unsafe pointer

        guard let shaderLibrary = device.makeDefaultLibrary() else {
            fatalError("Unable to find device library. Maybe bundle issue?")
        }
        guard let vertexFunction = shaderLibrary.makeFunction(name: "chapter_three_vertex_shader") else {
            fatalError("Unable to find vertex function. Are you sure you defined it and spelled the name right?")
        }
        guard let fragmentFunction = shaderLibrary.makeFunction(name: "chapter_three_fragment_shader") else {
            fatalError("Unable to find fragment function. Are you sure you defined it and spelled the name right?")
        }

//        mtkView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("Could not create pipeline state!")
        }
        self.pipelineState = pipelineState

        super.init(frame: .zero)
        self.addSubview(mtkView)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        mtkView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        mtkView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mtkView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        mtkView.delegate = self

        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
//        mtkView.framebufferOnly = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChapterThreeView: MTKViewDelegate {
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

        encoder.pushDebugGroup("Render")
        encoder.setRenderPipelineState(self.pipelineState)
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.popDebugGroup()
        encoder.endEncoding()

        if let currentDrawable = view.currentDrawable {
            commandBuffer.present(currentDrawable)
        }

        commandBuffer.commit()
    }
}

struct ChapterThreeRepresentable: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<ChapterThreeRepresentable>) -> ChapterThreeView {
        return ChapterThreeView()
    }

    func updateNSView(_ nsView: ChapterThreeView, context: NSViewRepresentableContext<ChapterThreeRepresentable>) {
        // nothing
        print("Update for some reason")
    }
}

struct ChapterThree: View {
    var body: some View {
        VStack(spacing: 0) {
            ChapterThreeRepresentable()
        }
    }
}

