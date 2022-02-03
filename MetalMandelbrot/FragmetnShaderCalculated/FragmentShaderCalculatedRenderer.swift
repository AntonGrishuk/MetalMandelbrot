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
    var zoom: Float = 1
    var location: CGPoint = .zero
    
    var translation: CGPoint = .zero
    
    var resultBuffer: MTLBuffer?
    var points: [SIMD3<Float>] = [[-1, -1, 1], [-1, 1, 1], [1, -1, 1], [1, 1, 1]]
    let indices: [UInt32] = [0, 1, 2, 2, 1, 3]
    var uniformsBuffer: MTLBuffer
    var isComplete: Bool = true
    
    init(view: MTKView) {
        self.metalView = view
        var uniforms = FragmentUniforms(zoom: zoom, position: [1, 1], translation: [0, 0])
        uniformsBuffer = device!.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.size, options: [])!
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

}


extension FragmenShaderCalculatedRenderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.draw()
    }
    
    func draw(in view: MTKView) {
        
        guard isComplete else { return }
        isComplete = false
        
        let ptr = uniformsBuffer.contents().bindMemory(to: FragmentUniforms.self, capacity: 1)
        
        ptr.pointee.zoom = zoom
        let screenScale = UIScreen.main.scale
        ptr.pointee.position = [Float(location.x * screenScale),
                                Float(location.y * screenScale)]
        ptr.pointee.translation = [Float(translation.x * screenScale),
                                   Float(translation.y * screenScale)]
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "My Command"
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            fatalError("renderPassDescriptor is null")
        }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        guard let pipelineState = self.pipelineState else { return }
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setViewport(MTLViewport.init(originX: 0, originY: 0, width: view.drawableSize.width, height: view.drawableSize.height, znear: 0.0, zfar: 1.0))
        
        let verticesBuffer = device?.makeBuffer(bytes: points,
            length: points.count * MemoryLayout.size(ofValue: points[0]), options: [])
        
        guard let buff = device?.makeBuffer(bytes: indices,
                length: indices.count * MemoryLayout.size(ofValue:  indices[0]),
                                            options: .cpuCacheModeWriteCombined)
        else {
            fatalError("Indices Buffer didn't create")
        }
        
        renderEncoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        
        let size = view.drawableSize
        let viewSize: [Float] = [Float(size.width), Float(size.height)]
        guard let sizeBuff = self.device?.makeBuffer(bytes: viewSize,
                length: MemoryLayout.size(ofValue: viewSize[0]) * viewSize.count,
                options: .cpuCacheModeWriteCombined) else {
            return
        }
        
        renderEncoder?.setFragmentBuffer(sizeBuff, offset: 0, index: 0)
        renderEncoder?.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)

        renderEncoder?.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint32,
                                             indexBuffer: buff,
                                             indexBufferOffset: 0)
        
        renderEncoder?.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer?.present(drawable)
        }
        
        commandBuffer?.addCompletedHandler({ _ in
            self.isComplete = true
        })
                
        commandBuffer?.commit()
    }
}
