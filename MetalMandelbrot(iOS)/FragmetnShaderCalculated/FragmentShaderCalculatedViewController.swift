//
//  FragmetnShaderCalculatedViewController.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 26.12.2021.
//

import UIKit
import MetalKit
import FractalLibrary

class FragmentShaderCalculatedViewController: UIViewController {
    
    private let metalView: MTKView = {
        let mv = MTKView()
        mv.clearColor = MTLClearColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        mv.colorPixelFormat = .bgra8Unorm
        mv.depthStencilPixelFormat = .depth32Float
        mv.translatesAutoresizingMaskIntoConstraints = false

        return mv
    }()
    private var panStartPoint: CGPoint = .zero
    private lazy var renderer = FragmenShaderCalculatedRenderer(view: self.metalView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        renderer.update()
    }

    private func configureUI() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
        view.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.maximumNumberOfTouches = 2
        metalView.addGestureRecognizer(pan)
        view.addSubview(metalView)
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
        
    @objc private func onPinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            renderer.zoom = renderer.zoom * Float(gesture.scale)
            let pinchPoint = gesture.location(in: metalView)
            gesture.scale = 1
            renderer.pinch(pinchPoint)
            renderer.update()
        default:
            break
        }
    }
            
    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panStartPoint = gesture.location(in: metalView) + renderer.translation
        case .changed:
            let pinchPoint = gesture.location(in: metalView)
            let delta = panStartPoint - pinchPoint
            renderer.translation = delta
            renderer.update()
        default:
            break
        }
    }
}
