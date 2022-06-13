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
        
    private lazy var renderer = FragmenShaderCalculatedRenderer(view: self.metalView)
    private lazy var pinch = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
    
    var translation: CGPoint = .zero {
        didSet {
            print("---TRANSLATION \(translation)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        pinch.delegate = self
        view.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        view.addGestureRecognizer(pan)
        pan.maximumNumberOfTouches = 2
//        pan.canPrevent(pinch)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.metalView.enableSetNeedsDisplay = true
        self.metalView.isPaused = true
        
        renderer.update()
    }

    private func configureUI() {
        metalView.isUserInteractionEnabled = false
        self.view.addSubview(metalView)
        
        metalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
        
    @objc private func onPinch(_ gesture: UIPinchGestureRecognizer) {

        guard gesture.numberOfTouches > 1 else { return }
        switch gesture.state {
        case .changed:
            renderer.oldZoom = renderer.zoom
            renderer.zoom = renderer.zoom * Float(gesture.scale)

            let pinchPoint = gesture.location(in: self.view)

            gesture.scale = 1
            
            let anchor = (pinchPoint + renderer.translation - CGPoint(x: view.bounds.width, y: view.bounds.height) * 0.5) * (1 - renderer.zoom / renderer.oldZoom)
            
            renderer.anchor = pinchPoint
            renderer.translation = renderer.translation - anchor
            renderer.update()
            
        default:
            break

        }
    }
        
    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {

        switch gesture.state {
        case .began:
            self.panStartPoint = gesture.location(in: self.view) + renderer.translation
        case .changed:
            let pinchPoint = gesture.location(in: self.view)
            let delta = self.panStartPoint - pinchPoint
            renderer.translation = delta
            renderer.update()

        default:
            break
        }
    }
}

extension FragmentShaderCalculatedViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

}
