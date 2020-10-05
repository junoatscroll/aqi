//
//  AppDelegate.swift
//  AQI
//
//  Created by Juno Suárez on 9/23/20.
//

import Cocoa
import SwiftUI

// EDIT THIS VALUE TO THE SENSOR YOU WANT
let SENSOR_ID: Int = 43023
// How often to fetch data from the API
let REFRESH_INTERVAL_SECONDS: TimeInterval = 600

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var timer: Timer?
    var lastFetched: Date?
    

//    let url = URL(string: "http://127.0.0.1:8080/sample.json")!
    let url = URL(string: "https://www.purpleair.com/json?show=\(SENSOR_ID)")!
    
    var lat: String?
    var lon: String?
    var mapUrl: String?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(onClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self
        
        updateAqi(nil)
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    @objc func onClick(sender: NSStatusItem) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseUp {
            // right click, show quit menu
            statusItem.menu = menu;
            menu.popUp(positioning: nil,
                       at: NSPoint(x: 0, y: statusItem.statusBar!.thickness),
                       in: statusItem.button)
        } else {
            // open map in bowser
            if let mapUrl = mapUrl {
                if let url = URL(string: mapUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    @objc func menuDidClose(_ menu: NSMenu) {
        // remove menu when closed so we can override left click behavior
        statusItem.menu = nil
    }
    
    func updateAqi(_ aqi: Int?) {
        var text: String
        var color: NSColor
        if let aqi = aqi {
            text = "\(aqi)ª"
            if (aqi > 150) {
                color = .red
            } else if (aqi > 100) {
                color = .orange
            } else if (aqi > 50) {
                color = .yellow
            } else if (aqi > 0) {
                color = .green
            } else {
                color = .textColor
            }
            
        } else {
            text = "AQI"
            color = .textColor
        }
        
        DispatchQueue.main.async(execute: {
            self.statusItem?.button?.title = text
            self.statusItem?.button?.contentTintColor = color
            
        })
    }
    
    @objc func tick() {
        if (lastFetched != nil && Date().timeIntervalSince(lastFetched!) < REFRESH_INTERVAL_SECONDS) {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                return
            }
            do {
                self.lastFetched = Date()
                if let data = data,
                   let obj = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary,
                   let results = obj["results"] as? NSArray {
                    print(self.url, results)
                    // each station has 2 sensors. we want to get the average reading between the two sensors
                    let values = results.compactMap({ (data) -> Float? in
                        let PM2_5Value = ((data as? NSDictionary)?["PM2_5Value"] as? NSString)?.floatValue
                        return PM2_5Value
                    })
                    let avgPM25 = values.reduce(0.0, +) / Float(values.count)
                        
                    let aqi = self.calculateAqi(pm25: avgPM25)
                    print("pm25 \(avgPM25), aqi \(String(describing: aqi))")
                            
                    // also grab the lat/lon (they're the same for both sensors, so get the first)
                    if self.mapUrl == nil,
                       results.count > 0,
                        let lat = (results[0] as? NSDictionary)?["Lat"] as? Double,
                        let lon = (results[0] as? NSDictionary)?["Lon"] as? Double {
                        // make map url
                        self.mapUrl = "https://www.purpleair.com/map?opt=1/mAQI/a10/cC0#10/\(lat)/\(lon)"
                    }
                            
                    self.updateAqi(aqi)
                }
            } catch {
                // handle err
            }
        }
        task.resume()
    }

    func calcAQI(_ Cp: Float, _ Ih: Float, _ Il: Float, _ BPh: Float, _ BPl: Float) -> Int {
        let a = (Ih - Il)
        let b = (BPh - BPl)
        let c = (Cp - BPl)
        return Int((a/b) * c + Il)
    }
    
    func calculateAqi(pm25: Float) -> Int? {
        // from https://docs.google.com/document/d/15ijz94dXJ-YAZLi9iZ_RaBwrZ4KtYeCy08goGBwnbCU/edit
        if (pm25 > 350.5) {
            return calcAQI(pm25, 500, 401, 500, 350.5)
        } else if (pm25 > 250.5) {
            return calcAQI(pm25, 400, 301, 350.4, 250.5)
        } else if (pm25 > 150.5) {
            return calcAQI(pm25, 300, 201, 250.4, 150.5)
        } else if (pm25 > 55.5) {
            return calcAQI(pm25, 200, 151, 150.4, 55.5)
        } else if (pm25 > 35.5) {
            return calcAQI(pm25, 150, 101, 55.4, 35.5)
        } else if (pm25 > 12.1) {
            return calcAQI(pm25, 100, 51, 35.4, 12.1)
        } else if (pm25 >= 0) {
            return calcAQI(pm25, 50, 0, 12, 0)
        }
        return nil
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

