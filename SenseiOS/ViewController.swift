//
//  ViewController.swift
//  SenseiOS
//
//  Created by Axa on 08/06/16.
//  Copyright © 2016 Axa. All rights reserved.
//

import UIKit
import MotionKit

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var monitorTextView: UITextView!
    @IBOutlet weak var switchSwitch: UISwitch!
    @IBOutlet weak var startButton: UIButton!
    
    let motionKit = MotionKit();
    let samplingFrequency = 0.1 //0.1=10Hz, 0.01=100Hz
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startCollection(){
        motionKit.getAccelerometerValues(samplingFrequency) { (x, y, z) in
            print("ACCELEROMETER X: \(x) Y: \(y) Z \(z)")
            // Unit=G, gravitation force equal to that exerted by the earth’s gravitational field (9.81 m s−2)
        }
        motionKit.getGyroValues(samplingFrequency){ (x, y, z) in
            print("GYRO X: \(x) Y: \(y) Z \(z)")
            // Unit=radiant/sec
        }
        motionKit.getMagnetometerValues(samplingFrequency){
            (x, y, z) in
            print("MAGNETOMETER X: \(x) Y: \(y) Z \(z)")
        }
        
    }
    
    func stopCollection(){
        motionKit.stopGyroUpdates()
        motionKit.stopAccelerometerUpdates()
        motionKit.stopmagnetometerUpdates()
        motionKit.stopDeviceMotionUpdates()
    }
    
    // MARK: Actions
    @IBAction func startStopButtonAction(sender: UIButton) {
        if (isRecording){
            print("Button: is recording. Stopping")
            isRecording = false
            startButton.backgroundColor = UIColor.greenColor()
            stopCollection()
        } else {
            print("Button: not recording. Starting")
            isRecording = true
            startButton.backgroundColor = UIColor.redColor()
            startCollection()
        }
    }
    
    @IBAction func startStopSwitchAction(sender: UISwitch) {
        print("Switch pressed")
    }
}
