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

    let kSavedStation = "savedStation"
    
    var helpInfo =  "• Click to turn on/off\n• ⎇ + Click to open radio list\n• Control + Click to quit"
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
    let player = AVPlayer()
    
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    var currentStream: Stream?
    var currentStation: Station? {
        didSet {
            saveCurrentStation()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let icon = NSImage(named: "radio")
        statusItem.image = icon
        statusItem.highlightMode = false
        statusItem.toolTip = helpInfo
        statusItem.action = #selector(radioAction(sender:))
        
        eventMonitor = EventMonitor(mask: .leftMouseDown) { [unowned self] event in
            if self.popover.isShown {
                self.closePopup()
            }
        }
        eventMonitor?.start()
        
        if let savedStation = getSavedStation() {
            selectRadio(savedStation)
        }
    }

    func getSavedStation() -> Station? {
        
        if let data = UserDefaults.standard.value(forKey:kSavedStation) as? Data {
            return try? PropertyListDecoder().decode(Station.self, from: data)
        }
        
        return nil
    }
    
    func saveCurrentStation() {
        guard let currentStation = self.currentStation else {
            print("nothing to persist")
            return
        }
        UserDefaults.standard.set(try? PropertyListEncoder().encode(currentStation), forKey: kSavedStation)
        UserDefaults.standard.synchronize()
    }
    
    func radioAction(sender: Any) {
        
        if let wannaRadioList = NSApplication.shared().currentEvent?.modifierFlags.contains(.option), wannaRadioList {
            openStationsList()
            return
        }
        
        
        if let wannaQuit = NSApplication.shared().currentEvent?.modifierFlags.contains(.control), wannaQuit {
            player.pause()
            NSApplication.shared().terminate(self)
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
                
                
                let hackedStations = self.addExtraRadios(to: stations)
                self.showStationsList(with: hackedStations)
            }
        })
    }
    
    func addExtraRadios(to stations: [Station]) -> [Station] {
        
        var result = stations
        
        guard
            let extraRadiosPath = Bundle.main.path(forResource: "extraradios", ofType: "json")
            else {
        
                print("uops1")
                return stations
        
        }
        guard
            let extraRadiosURL = URL(string: "file:///\(extraRadiosPath)")
            else {
                
                print("uops2")
                return stations
                
        }
        guard
            let extraRadiosData = try? Data.init(contentsOf: extraRadiosURL)
            else {
                
                print("uops3")
                return stations
                
        }
        
        let decoder = JSONDecoder()
        
        do {
            let extraRadios = try decoder.decode([Station].self, from: extraRadiosData)
            
            for radio in extraRadios {
                result.insert(radio, at: 0)
            }
            
            return result
            
        } catch let error {
            print(error.localizedDescription)
            return stations
        }
        
        
    }
    
    func showStationsList(with stations: [Station]) {
        if popover.isShown {
            closePopup()
            return
        }
        
        let sb = NSStoryboard(name: "Main", bundle: nil)
        let stationsViewController = sb.instantiateController(withIdentifier: "RadioListViewController") as! RadioListViewController
        if let cs = currentStream {
            stationsViewController.currentStreamId = cs.id
        }
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
        self.currentStation = station
        
        if station.id < 0 {
            let stream = Stream(id: station.id, path: station.streamingURL!.absoluteString, name: "Rádio Sergio Lopes")
            setupStream(stream)
        } else {
            getStreamInfo(for: station.id)
        }
        closePopup()
        
        
    }
    
    func getStreamInfo(for id: Int) {
        let streamUrlPath = "http://webservice.bandradios.onebrasilmedia.com.br:8087/bandradios-api/retrieve-radio?1=1&rid=\(id)&auc=29E2A48D-BDD2-4589-9710-18A446A19B83"
        
        guard let streamUrl = URL(string: streamUrlPath) else { return }
        
        DataCache().getStreamInfo(for: streamUrl, id: id) { streamInfo in
            guard let streamInfo = streamInfo else { return }
            DispatchQueue.main.async {
                self.setupStream(streamInfo)
            }
        }
    }
    
    func setupStream(_ streamInfo: Stream) {
        
        self.currentStream = streamInfo
        guard let streamUrl = URL(string: streamInfo.path) else { return }
        let newStreamItem = AVPlayerItem(url: streamUrl)
        player.replaceCurrentItem(with: newStreamItem)
        if let cs = self.currentStream {
            let playingInfo = "• Playing \(cs.name)"
            statusItem.toolTip = helpInfo + "\n\(String(repeating: "-", count: playingInfo.count))\n\(playingInfo)"
        }
    }
}


