//
//  ChapterFour.swift
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI
import ModelIO

/// Goal of Chapter Four is to make a pulsating, rotating cube with colors interpolated through its corners.

final class ChapterFourView: NSView {
    private let mtkView: MTKView
    private let renderer: ChapterFourRenderer

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("This doesn't have a suitable GPU!")
        }
        let mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8

        self.renderer = ChapterFourRenderer(device: device, mtkView: mtkView)
        self.mtkView = mtkView

        super.init(frame: .zero)
        self.addSubview(mtkView)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        mtkView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        mtkView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mtkView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        mtkView.delegate = self.renderer

//        mtkView.presentsWithTransaction = true
        mtkView.clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
//        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChapterFourRenderer: NSObject {
    private let vertices: [ChapterFourVertexInOut]
    private let indices: [UInt16]
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let uniformsBuffer: MTLBuffer
    private let pipelineState: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private var worldToView: matrix_float4x4
    private let camera: MDLCamera
    private let commandQueue: MTLCommandQueue
    var offsetInViewCoordinates: CGPoint = .zero

    var projectionType: MDLCameraProjection {
        get {
            return self.camera.projection
        }
        set {
            self.camera.projection = self.projectionType
        }
    }

    init(device: MTLDevice, mtkView: MTKView) {
        self.commandQueue = device.makeCommandQueue()!

        let vertices = [
            ChapterFourVertexInOut(position: SIMD4<Float>(-1, 1, 1, 1), color: SIMD4<Float>(0, 1, 1, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(-1, -1, 1, 1), color: SIMD4<Float>(0, 0, 1, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(1, -1, 1, 1), color: SIMD4<Float>(1, 0, 1, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(1, 1, 1, 1), color: SIMD4<Float>(1, 1, 1, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(-1, 1, -1, 1), color: SIMD4<Float>(0, 1, 0, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(-1, -1, -1, 1), color: SIMD4<Float>(0, 0, 0, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(1, -1, -1, 1), color: SIMD4<Float>(1, 0, 0, 1)),
            ChapterFourVertexInOut(position: SIMD4<Float>(1, 1, -1, 1), color: SIMD4<Float>(1, 1, 0, 1))
        ]
        guard let vertexBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(mutating: vertices), length: MemoryLayout<ChapterThreeVertexInOut>.size * vertices.count, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate vertex buffer")
        }
        self.vertexBuffer = vertexBuffer
        self.vertices = vertices // we need to retain this since we're passing in a raw unsafe pointer

        let indices: [UInt16] = [
            3,2,6,6,7,3,
            4,5,1,1,0,4,
            4,0,3,3,7,4,
            1,5,6,6,2,1,
            0,1,2,2,3,0,
            7,6,5,5,4,7
        ]
        guard let indexBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(mutating: indices), length: MemoryLayout<UInt16>.size * indices.count, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate index buffer")
        }
        self.indexBuffer = indexBuffer
        self.indices = indices

        guard let uniformsBuffer = device.makeBuffer(length: MemoryLayout<ChapterFourUniforms>.size * 1, options: [.cpuCacheModeWriteCombined]) else {
            fatalError("Unable to allocate uniforms buffer")
        }
        self.uniformsBuffer = uniformsBuffer

        guard let shaderLibrary = device.makeDefaultLibrary() else {
            fatalError("Unable to find device library. Maybe bundle issue?")
        }
        guard let vertexFunction = shaderLibrary.makeFunction(name: "chapter_four_vertex_shader") else {
            fatalError("Unable to find vertex function. Are you sure you defined it and spelled the name right?")
        }
        guard let fragmentFunction = shaderLibrary.makeFunction(name: "chapter_four_fragment_shader") else {
            fatalError("Unable to find fragment function. Are you sure you defined it and spelled the name right?")
        }

        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let depthState = device.makeDepthStencilState(descriptor: depthStateDesciptor) else {
            fatalError("Could not create depth stencil state")
        }
        self.depthState = depthState

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("Could not create pipeline state!")
        }
        self.pipelineState = pipelineState

        let size = mtkView.drawableSize
        let aspect = Float(size.width) / Float(size.height)

        let camera = MDLCamera()
        camera.projection = .perspective
        camera.nearVisibilityDistance = 0.1
        camera.farVisibilityDistance = 1000
        camera.fieldOfView = 60
        camera.look(at: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(8, 0, 0))
        self.camera = camera

        self.worldToView = camera.projectionMatrix

        super.init()
        self.updateUniformsForView(aspectRatio: aspect)
    }

    func updateUniformsForView(aspectRatio: Float) {
        self.camera.sensorAspect = aspectRatio
        let transform = MDLTransform()
        transform.setTranslation(SIMD3<Float>(0, 0, -5), forTime: 0)
        transform.setRotation(SIMD3<Float>(radians_from_degrees(45), radians_from_degrees(45), 0), forTime: 0)
        let modelToWorld = transform.localTransform(atTime: 0)
        self.worldToView = self.camera.projectionMatrix
        let uniforms = [ChapterFourUniforms(modelViewProjection: self.worldToView * modelToWorld)]
        memcpy(self.uniformsBuffer.contents(), UnsafeRawPointer(uniforms), MemoryLayout<ChapterFourUniforms>.size)
    }
}

extension ChapterFourRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

        let aspect = Float(size.width) / Float(size.height)
        self.updateUniformsForView(aspectRatio: aspect)
        view.setNeedsDisplay(view.bounds)
    }

    func draw(in view: MTKView) {
        guard let device = view.device else {
            print("Error: no metal device")
            return
        }

        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
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
        encoder.setDepthStencilState(self.depthState)
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(self.uniformsBuffer, offset: 0, index: 1)
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: self.indices.count, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
        encoder.popDebugGroup()
        encoder.endEncoding()

        if let currentDrawable = view.currentDrawable {
            commandBuffer.present(currentDrawable)
        }

        commandBuffer.commit()
    }
}

struct ChapterFourRepresentable: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<ChapterFourRepresentable>) -> ChapterFourView {
        return ChapterFourView()
    }

    func updateNSView(_ nsView: ChapterFourView, context: NSViewRepresentableContext<ChapterFourRepresentable>) {
        // nothing
        print("Update for some reason")
    }
}

struct ChapterFour: View {
    var body: some View {
        let gesture = DragGesture()
            .onChanged { value in
                print("Drag: x: \(value.location.x - value.startLocation.x), y: \(value.location.y - value.startLocation.y)")
            }
        return VStack(spacing: 0) {
            ChapterFourRepresentable().gesture(gesture)
        }
    }
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
