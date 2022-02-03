//
//  FragmetnShaderCalculatedViewController.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 26.12.2021.
//

import UIKit
import MetalKit

class FragmentShaderCalculatedViewController: UIViewController {
    
    private let metalView: MTKView = {
        let mv = MTKView()
        mv.clearColor = MTLClearColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        mv.colorPixelFormat = .bgra8Unorm
        mv.depthStencilPixelFormat = .depth32Float
        return mv
    }()
    
    private var panStartPoint: CGPoint = .zero
        
    private var renderer: FragmenShaderCalculatedRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
        metalView.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        metalView.addGestureRecognizer(pan)
        
        self.metalView.enableSetNeedsDisplay = true
        self.metalView.isPaused = true
        
        self.renderer = FragmenShaderCalculatedRenderer(view: self.metalView)
        self.metalView.setNeedsDisplay()
    }

    private func configureUI() {
        self.view.addSubview(metalView)
        
        metalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    var oldZoom: Float = 1
    
    @objc private func onPinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.panStartPoint = gesture.location(in: self.metalView) + renderer!.translation
        case .changed:
            let p = self.panStartPoint - gesture.location(in: self.metalView)
            renderer?.translation = p
            self.renderer?.zoom = oldZoom / Float( gesture.scale)
            self.metalView.setNeedsDisplay()
        case .ended:
            oldZoom /= Float(gesture.scale)
        default:
            break
        }
    }
        
    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.panStartPoint = gesture.translation(in: self.metalView) + renderer!.translation
        case .changed:
            let p = self.panStartPoint - gesture.translation(in: self.metalView)
            renderer?.translation = p
            self.metalView.setNeedsDisplay()
        default:
            break
        }
    }
}

extension CGPoint {
    static func - (lhs: Self, rhs: Self) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func + (lhs: Self, rhs: Self) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
