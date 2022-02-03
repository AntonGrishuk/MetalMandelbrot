//
//  Vertex.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 12.12.2021.
//

import Foundation

struct Vertex {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
}

struct FragmentUniforms {
    var zoom: Float
    var position: SIMD2<Float>
    var translation: SIMD2<Float>
}
