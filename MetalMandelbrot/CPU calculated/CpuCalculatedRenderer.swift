//
//  Renderer.swift
//  MetalMandelbrot
//
//  Created by Anton Hryshchuk on 09.08.2021.
//

import Foundation
import MetalKit
import simd

class CpuCalculatedRenderer: NSObject {
    let metalView: MTKView
    let device = MTLCreateSystemDefaultDevice()
    private var pipelineState: MTLRenderPipelineState?

    private var commandQueue: MTLCommandQueue?
    
    var resultBuffer: MTLBuffer?
    var colors: [SIMD3<Float>] = []
    
    init(view: MTKView) {
        self.metalView = view
        super.init()
        
        self.metalView.device = self.device

        guard let library = self.device?.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader")
        else { return }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Simple Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride * 2
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = self.metalView.depthStencilPixelFormat
        
        do {
            self.pipelineState = try self.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
            self.commandQueue = self.device?.makeCommandQueue()
        } catch (let error) {
            print(error)
        }
               
        self.metalView.delegate = self
        
    }
    
/*    CPU calculation mandelbrot point color    */
    func mandelbrotPointColor(x: Float, y: Float) -> SIMD4<Float> {
        var preX: Float = 0
        var preY: Float = 0
        var xn: Float = 0
        var yn: Float = 0

        let max = 100
        
        var color = SIMD4<Float>(arrayLiteral: 0, 0, 0, 1)
        
        for i in 0...max {
            xn = preX * preX - preY * preY + x
            yn = 2 * preY * preX + y
            preY = yn
            preX = xn
            
            if xn*xn + yn*yn > 4 {
                return color
            } else {
                let colorComponent = Float(i) / Float(max)
                color = SIMD4<Float>.init(arrayLiteral: sin(Float.pi * colorComponent), colorComponent, colorComponent, 1)
            }
        }
        
        return color
    }
}

extension CpuCalculatedRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.draw()
    }
    
    func draw(in view: MTKView) {
        
        let size = view.drawableSize
        let width: Float =  Float(size.width)
        let height: Float =  Float(size.height)
        
        let aspectRation = width / height
        
        var vertices:[Vertex] = []
        
        let xStep: Float = 10 / width
        let yStep: Float = 10 / height
        var i: Int = 0
        
        for x in stride(from: Float(-1.5), to: Float(0.5), by: xStep) {
            for y in stride(from: Float(-1), to: Float(1.1), by: yStep) {
                let position: SIMD3<Float> = [x / aspectRation, y, 0]
                let color = self.mandelbrotPointColor(x: x, y: y)   /* CPU calculated color */
                let vertex = Vertex(position: position, color: color)
                vertices.append(vertex)
                i += 1
            }
        }
        
        let indices: [UInt32] = (0..<UInt32(vertices.count)).compactMap{$0}

        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "My Command"
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            fatalError("renderPassDescriptor is null")
        }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        if let pipelineState = self.pipelineState {
            renderEncoder?.setRenderPipelineState(pipelineState)
        }
        
        guard let indicesBuffer = self.device?.makeBuffer(bytes: indices, length: indices.count * MemoryLayout.size(ofValue: indices[0]), options: .cpuCacheModeWriteCombined) else {
            fatalError("Indices Buffer didn't create")
        }
        
        let verticesBuffer = self.device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout.size(ofValue: vertices[0]), options: [])

        renderEncoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)

        renderEncoder?.drawIndexedPrimitives(type: .point, indexCount: indices.count, indexType: .uint32, indexBuffer: indicesBuffer, indexBufferOffset: 0, instanceCount: 2)
        
        renderEncoder?.endEncoding()
        
        if let drawable = view.currentDrawable {
            let duration = 1.0 / Double(view.preferredFramesPerSecond)
            commandBuffer?.present(drawable, atTime: duration)
        }
        
        commandBuffer?.commit()
    }
}
