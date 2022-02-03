//
//  MainViewController.swift
//  MetalMandelbrot
//
//  Created by Anton Grishuk on 12.12.2021.
//

import UIKit

enum FractalTypeType: CaseIterable {
    case cpuCalculated
    case kernelCalculated
    case fragmentShaderCalculated
}

class MainViewController: UIViewController {
    
        
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.delegate = self
        
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    private func configureUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FractalTypeType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0: cell.textLabel?.text = "CPU calculated"
        case 1: cell.textLabel?.text = "Calculated with kernel function"
        case 2: cell.textLabel?.text = "Fragment Shader calculated"
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewController: UIViewController?
        switch indexPath.row {
        case 0:
            viewController = CpuCalculatedViewController()
        case 1:
            viewController = GpuCalculatedViewController()
        case 2:
            viewController = FragmentShaderCalculatedViewController()
        default:
            return
        }
        
        viewController.map{self.navigationController?.pushViewController($0, animated: true)}
    }
}
