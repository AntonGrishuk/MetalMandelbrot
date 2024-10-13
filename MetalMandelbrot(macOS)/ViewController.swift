//
//  ViewController.swift
//  MetalMandelbrot(macOS)
//
//  Created by Anton Grishuk on 07.09.2024.
//

import Cocoa
import MetalKit
import FractalLibrary

class ViewController: NSViewController {

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
        
    override func viewDidAppear() {
        super.viewDidAppear()
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        renderer.update()
    }

    private func configureUI() {
//        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
//        view.addGestureRecognizer(pinch)
//
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
//        pan.maximumNumberOfTouches = 2
//        metalView.addGestureRecognizer(pan)
        view.addSubview(metalView)
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        panStartPoint = event.locationInWindow
        panStartPoint.x += renderer.translation.x
        panStartPoint.y -= renderer.translation.y
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        let translation = event.locationInWindow
        var delta = panStartPoint - translation
        delta.y = -delta.y
        renderer.translation = delta
        renderer.update()
    }
    
    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        let pinchPoint = event.locationInWindow
//        panStartPoint.x += renderer.translation.x
//        panStartPoint.y -= renderer.translation.y
        renderer.zoom = renderer.zoom * (1 + Float(event.magnification))
        renderer.pinch(pinchPoint)
        renderer.update()
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        let zoom: Float
        if event.deltaY > 0 {
            zoom = 0.01
        } else if event.deltaY < 0 {
            zoom = -0.01
        } else {
            zoom = 0
        }
        var pinchPoint = event.locationInWindow
        pinchPoint.x += renderer.translation.x
        pinchPoint.y -= renderer.translation.y
        renderer.zoom = renderer.zoom * (1 + zoom)
        renderer.pinch(pinchPoint)
        renderer.update()
    }
//    @objc private func onPinch(_ gesture: UIPinchGestureRecognizer) {
//        switch gesture.state {
//        case .changed:
//            renderer.zoom = renderer.zoom * Float(gesture.scale)
//            let pinchPoint = gesture.location(in: metalView)
//            gesture.scale = 1
//            renderer.pinch(pinchPoint)
//            renderer.update()
//        default:
//            break
//        }
//    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

