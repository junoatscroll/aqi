//
//  AppDelegate.swift
//  AQI
//
//  Created by Juno Suárez on 9/23/20.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    var timer: Timer?
    
    let url = URL(string: "https://www.purpleair.com/json?show=43023")!
//    let url = URL(string: "http://127.0.0.1:8080/sample.json")!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.toolTip = "AQI"
        
        updateAqi(aqi: nil)
        
        timer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func updateAqi(aqi: Int?) {
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
        print("tick")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                return
            }
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                
                do {
                    if let obj = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        let results = obj["results"] as? NSArray
                        if let results = results {
                            // each station has 2 sensors. we want to get the average reading between the two sensors
                            let values = results.compactMap({ (data) -> Float? in
                                let PM2_5Value = ((data as? NSDictionary)?["PM2_5Value"] as? NSString)?.floatValue
                                return PM2_5Value
                            })
                            let avgPM25 = values.reduce(0.0, +) / Float(values.count)
                            
                            let aqi = self.calculateAqi(pm25: avgPM25)
                            print("pm25 \(avgPM25), aqi \(aqi)")
                            
                            self.updateAqi(aqi: aqi)
                        }
                    }
                    
                } catch {
                    // handle err
                }
            }
            
            
        }
        task.resume()
        
    }

    func calcAQI(_ Cp: Float, _ Ih: Float, _ Il: Float, _ BPh: Float, _ BPl: Float) -> Int {
        let a = (Ih - Il);
        let b = (BPh - BPl);
        let c = (Cp - BPl);
        return Int((a/b) * c + Il);
    }
    
    func calculateAqi(pm25: Float) -> Int? {
        // from https://docs.google.com/document/d/15ijz94dXJ-YAZLi9iZ_RaBwrZ4KtYeCy08goGBwnbCU/edit
        if (pm25 > 350.5) {
                 return calcAQI(pm25, 500, 401, 500, 350.5);
               } else if (pm25 > 250.5) {
                 return calcAQI(pm25, 400, 301, 350.4, 250.5);
               } else if (pm25 > 150.5) {
                 return calcAQI(pm25, 300, 201, 250.4, 150.5);
               } else if (pm25 > 55.5) {
                 return calcAQI(pm25, 200, 151, 150.4, 55.5);
               } else if (pm25 > 35.5) {
                 return calcAQI(pm25, 150, 101, 55.4, 35.5);
               } else if (pm25 > 12.1) {
                 return calcAQI(pm25, 100, 51, 35.4, 12.1);
               } else if (pm25 >= 0) {
                 return calcAQI(pm25, 50, 0, 12, 0);
               }
        return nil
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

