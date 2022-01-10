//
//  FragmetnShaderCalculatedViewController.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 26.12.2021.
//

import UIKit
import MetalKit

class FragmenShaderCalculatedViewController: UIViewController {
    
    private let metalView: MTKView = {
        let mv = MTKView()
        mv.clearColor = MTLClearColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        mv.colorPixelFormat = .bgra8Unorm
        mv.depthStencilPixelFormat = .depth32Float
        return mv
    }()
    
    private var renderer: FragmenShaderCalculatedRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.metalView.enableSetNeedsDisplay = false
        self.metalView.isPaused = false
        
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

}
