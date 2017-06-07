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
    
    var currentStreamId: Int = -1
    
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
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        
        guard let cell = cell as? NSTextFieldCell else { return }
        if stations[row].id == currentStreamId {
            cell.textColor = .red
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        delegate?.selectRadio(stations[tableView.selectedRow])
    }
    
}

