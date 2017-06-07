//
//  AppDelegate.swift
//  BandNews
//
//  Created by Daniel Bonates on 06/06/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Cocoa

import MediaPlayer
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var isRadioOn = false {
        didSet {
            if isRadioOn {
                player.play()
            } else {
                player.pause()
            }
        }
    }
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let player = AVPlayer(url: URL(string: "http://evp.mm.uol.com.br:1935/bnewsfm_rj/bnewsfm_rj.sdp/playlist.m3u8")!)
    
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let icon = NSImage(named: "radio")
        statusItem.image = icon
        statusItem.highlightMode = false
        statusItem.toolTip = "• click to turn on/off\n• alt+click to quit ;)"
        statusItem.action = #selector(printQuote(sender:))
        
        eventMonitor = EventMonitor(mask: .leftMouseDown) { [unowned self] event in
            if self.popover.isShown {
                self.closePopup()
            }
        }
        eventMonitor?.start()
        
    }

    func printQuote(sender: AnyObject) {
        
        
        if let wannaQuit = NSApplication.shared().currentEvent?.modifierFlags.contains(.option), wannaQuit {
            player.pause()
            NSApplication.shared().terminate(self)
            return
        }
        
        if let wannaRadioList = NSApplication.shared().currentEvent?.modifierFlags.contains(.control), wannaRadioList {
            openStationsList()
            return
        }
        
        
        isRadioOn = !isRadioOn
        statusItem.image = isRadioOn ? NSImage(named: "radio-on") : NSImage(named: "radio")
        
    }
    
    func closePopup() {
        popover.close()
        eventMonitor?.stop()
    }

    func openStationsList() {
        
        let url = URL(string: "http://webservice.bandradios.onebrasilmedia.com.br:8087/bandradios-api/retrieve-radio-list")!
        
        DataCache().getRadioList(from: url, completion: { stations in
            guard let stations = stations else { return }
            DispatchQueue.main.async {
                self.showStationsList(with: stations)
            }
        })
    }
    
    func showStationsList(with stations: [Station]) {
        if popover.isShown {
            closePopup()
            return
        }
        
        let sb = NSStoryboard(name: "Main", bundle: nil)
        let stationsViewController = sb.instantiateController(withIdentifier: "RadioListViewController") as! RadioListViewController
        
        stationsViewController.stations = stations
        stationsViewController.delegate = self
        
        if let button = statusItem.button {
            popover.contentViewController = stationsViewController
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    
    func selectRadio(_ station: Station) {
        print("loadURL for id: \(station.id)")
        closePopup()
    }
}


