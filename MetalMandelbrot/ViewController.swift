//
//  ViewController.swift
//  MetalMandelbrot
//
//  Created by Anton Hryshchuk on 09.08.2021.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    @IBOutlet weak var metalView: MTKView!
    private var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.metalView.enableSetNeedsDisplay = false
//        self.metalView.isPaused = true
        
        self.renderer = Renderer(view: self.metalView)
    }


}

