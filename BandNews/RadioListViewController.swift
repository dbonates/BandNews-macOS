//
//  RadioListViewController.swift
//  BandNews
//
//  Created by Daniel Bonates on 06/06/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Cocoa

class RadioListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var delegate: AppDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    
    var stations: [Station] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }


    func numberOfRows(in tableView: NSTableView) -> Int {
        return stations.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard let identifier = tableColumn?.identifier else { return nil}
        
        if identifier == "RadioName" {
            return stations[row].name
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        delegate?.selectRadio(stations[tableView.selectedRow])
    }
    
}

