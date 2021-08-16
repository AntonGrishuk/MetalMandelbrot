//
//  Renderer.swift
//  MetalMandelbrot
//
//  Created by Anton Hryshchuk on 09.08.2021.
//

import Foundation
import MetalKit
import simd

struct Vertex {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
}

class Renderer: NSObject {
    let metalView: MTKView
    let device = MTLCreateSystemDefaultDevice()
    private var pipelineState: MTLRenderPipelineState?
    private var computePipelineState: MTLComputePipelineState?

    private var commandQueue: MTLCommandQueue?
    
    var resultBuffer: MTLBuffer?
    var colors: [SIMD3<Float>] = []
    
    init(view: MTKView) {
        self.metalView = view
        super.init()
        
        self.metalView.device = self.device

        guard let library = self.device?.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader"),
              let computeFunction = library.makeFunction(name: "pointColor")
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
               
//        self.metalView.delegate = self
        
        self.computePipelineState = try? self.device?.makeComputePipelineState(function: computeFunction)
        self.calculatePoints()
    }
    
    func calculatePoints() {
        
        guard let computePipelineState = self.computePipelineState else { return }
        
        
        let size = self.metalView.drawableSize
        let width: Float =  Float(size.width)
        let height: Float =  Float(size.height)
        
                
        let xStep: Float = 20 / width
        let yStep: Float = 20 / height
        var i: Int = 0
        var arr: [SIMD2<Float>] = []

        for x in stride(from: Float(-1.5), to: Float(0.5), by: xStep) {
            for y in stride(from: Float(-1), to: Float(1.1), by: yStep) {
                arr.append(SIMD2<Float>(x, y))
                i += 1
            }
        }
    
        
        let arrSize = MemoryLayout.size(ofValue: arr[0]) * arr.count * 2

        let buffer = self.device?.makeBuffer(bytes: arr, length: arrSize, options: .storageModeShared)
        
        resultBuffer = self.device?.makeBuffer(length: arrSize, options: .storageModeShared)
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        commandBuffer?.label = "Compute Command"
        
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(self.computePipelineState!)
        computeEncoder?.setBuffer(buffer, offset: 0, index: 0)
        computeEncoder?.setBuffer(resultBuffer, offset: 0, index: 1)
        
        
        var _threadGroupsSize = computePipelineState.maxTotalThreadsPerThreadgroup
        if _threadGroupsSize > arr.count {
            _threadGroupsSize = arr.count
        }
        
        let threadGroupsSize = MTLSizeMake(_threadGroupsSize, 1, 1)
        let gridSize = MTLSize(width: arr.count / _threadGroupsSize, height: 1, depth: 1)

        
//        computeEncoder?.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupsSize)
        computeEncoder?.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupsSize)
        computeEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.addCompletedHandler({ cmndBuffer in
            guard let buffer = self.resultBuffer else {return}
            self.colors.reserveCapacity(arr.count)
            
            for i in 0..<arr.count {
                self.colors.append(buffer.contents()
                                    .load(fromByteOffset: MemoryLayout<SIMD3<Float>>.size * i,
                                          as: SIMD3<Float>.self))
            }
            self.draw(in: self.metalView)
        })
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

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.draw()
    }
    
    func draw(in view: MTKView) {
        if self.colors.isEmpty {
            return
        }
        
        let size = view.drawableSize
        let width: Float =  Float(size.width)
        let height: Float =  Float(size.height)
        
        let aspectRation = width / height
        
        var vertices:[Vertex] = []
        
        let xStep: Float = 20 / width
        let yStep: Float = 20 / height
        var i: Int = 0
        
        for x in stride(from: Float(-1.5), to: Float(0.5), by: xStep) {
            for y in stride(from: Float(-1), to: Float(1.1), by: yStep) {
                let position: SIMD3<Float> = [x / aspectRation, y, 0]
//                let color = self.mandelbrotPointColor(x: x, y: y)   /* CPU calculated color */
//                let vertex = Vertex(position: position, color: color)
                let color = self.colors[i] /* GPU Calculated color */
                let vertex = Vertex(position: position, color: SIMD4<Float>(color, 1))
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
