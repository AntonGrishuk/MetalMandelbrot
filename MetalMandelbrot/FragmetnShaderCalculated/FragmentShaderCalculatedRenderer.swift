//
//  FragmentShaderCalculatedRenderer.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 26.12.2021.
//

import Foundation

import Foundation
import MetalKit
import simd

class FragmenShaderCalculatedRenderer: NSObject {
    let metalView: MTKView
    let device = MTLCreateSystemDefaultDevice()
    private var pipelineState: MTLRenderPipelineState?

    private var commandQueue: MTLCommandQueue?
    
    var resultBuffer: MTLBuffer?
    let points: [SIMD3<Float>] = [[-1, -1, 1], [-1, 1, 1], [1, -1, 1], [1, 1, 1]]
    let indices: [UInt32] = [0, 1, 2, 2, 1, 3]
    
    init(view: MTKView) {
        self.metalView = view
        super.init()
        
        self.metalView.device = self.device

        guard let library = self.device?.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "fragCalculatedVertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentCalculatedShader")
        else { return }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Simple Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
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


extension FragmenShaderCalculatedRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.draw()
    }
    
    func draw(in view: MTKView) {
        let size = view.drawableSize
        let viewSize: [Float] = [Float(size.width), Float(size.height)]
        guard let sizeBuff = self.device?.makeBuffer(bytes: viewSize,
                length: MemoryLayout.size(ofValue: viewSize[0]) * viewSize.count,
                options: .cpuCacheModeWriteCombined) else {
            return
        }

        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "My Command"
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            fatalError("renderPassDescriptor is null")
        }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        if let pipelineState = self.pipelineState {
            renderEncoder?.setRenderPipelineState(pipelineState)
        }
        
//        guard let indicesBuffer = self.device?.makeBuffer(bytes: indices, length: indices.count * MemoryLayout.size(ofValue: indices[0]), options: .cpuCacheModeWriteCombined) else {
//            fatalError("Indices Buffer didn't create")
//        }
//
//        let verticesBuffer = self.device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout.size(ofValue: vertices[0]), options: [])
        
        let verticesBuffer = device?.makeBuffer(bytes: points,
            length: points.count * MemoryLayout.size(ofValue: points[0]), options: [])
        
        guard let buff = device?.makeBuffer(bytes: indices,
                length: indices.count * MemoryLayout.size(ofValue:  indices[0]),
                                            options: .cpuCacheModeWriteCombined)
        else {
            fatalError("Indices Buffer didn't create")
        }
        
        renderEncoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentBuffer(sizeBuff, offset: 0, index: 0)

        renderEncoder?.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint32,
                                             indexBuffer: buff,
                                             indexBufferOffset: 0)
        
        renderEncoder?.endEncoding()
        
        if let drawable = view.currentDrawable {
            let duration = 1.0 / Double(view.preferredFramesPerSecond)
            commandBuffer?.present(drawable, atTime: duration)
        }
        
        commandBuffer?.commit()
    }
}
