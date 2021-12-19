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
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = CpuCalculatedViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = GpuCalculatedViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }
}
