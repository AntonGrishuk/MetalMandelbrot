//
//  CGPoint+Extension.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 29.05.2022.
//

import CoreGraphics

public extension CGPoint {
    static func - (lhs: Self, rhs: Self) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func + (lhs: Self, rhs: Self) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func / (lhs: Self, rhs: Float) -> CGPoint {
        return CGPoint(x: lhs.x / CGFloat(rhs), y: lhs.y / CGFloat(rhs))
    }
    
    static func * (lhs: Self, rhs: Float) -> CGPoint {
        return CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
    }
    
    static func * (lhs: Self, rhs: Self) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
}
