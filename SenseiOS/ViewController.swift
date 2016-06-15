//
//  ViewController.swift
//  SenseiOS
//
//  Created by Axa on 08/06/16.
//  Copyright © 2016 Axa. All rights reserved.
//
// // NSDate().timeIntervalSince1970 * 1000 =  time in milliseconds since the UNIX epoch (January 1, 1970 00:00:00 UTC)

import UIKit
import MotionKit

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var monitorTextView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    
    let motionKit = MotionKit();
    let samplingFrequency = 0.1 // 0.1 = 10Hz, 0.01 = 100Hz
    let gravity = 9.81
    let CSV_SEP = ";"
    var isRecording = false
    var experimentName:String = "" // Should be like this 2016_04_15-16_52.csv
    var csvOutputFileName = ""
    var audioOutputFileName = ""
    var csvOutputFilePath = ""
    var audioOutputFilePath = ""
    var fileHandle: NSFileHandle = NSFileHandle.init()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.sharedApplication().idleTimerDisabled = true // Keep screen on
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startCollection(){
        print("EXPERIMENT: \(experimentName)")
        
        motionKit.getAccelerometerValues(samplingFrequency) { (x, y, z) in
            print(" IOS ACCELEROMETER X: \(x) Y: \(y) Z: \(z)")
            // Unit=G, gravitation force equal to that exerted by the earth’s gravitational field (9.81 m s−2)
        }
        motionKit.getGyroValues(samplingFrequency){ (x, y, z) in
            print("IOS GYRO\(self.CSV_SEP)\((NSDate().timeIntervalSince1970 * 1000))\(self.CSV_SEP) X: \(x) Y: \(y) Z: \(z)")
            // Unit=radiant/sec
        }
        motionKit.getMagnetometerValues(samplingFrequency){
            (x, y, z) in
            print("IOS MAGNETOMETER X:\(x) Y: \(y) Z: \(z)")
            self.writeDataToFile("IOS MAGNETOMETER X: \(x) Y: \(y) Z: \(z)\n")
            // Unit:
        }
        motionKit.getDeviceMotionObject(samplingFrequency){
            (deviceMotion) -> () in
            let accelerationX = deviceMotion.userAcceleration.x
            let accelerationY = deviceMotion.userAcceleration.y
            let accelerationZ = deviceMotion.userAcceleration.z
            print("IOS DM ACCELERATION X: \(accelerationX) Y: \(accelerationY) Z: \(accelerationZ)")
            // Unit = G. It's the linear acceleration
            
            let gravityX = deviceMotion.gravity.x
            let gravityY = deviceMotion.gravity.y
            let gravityZ = deviceMotion.gravity.z
            print("IOS GRAVITY X: \(gravityX) Y: \(gravityY) Z: \(gravityZ)")
            // Unity = G
            
            let rotationX = deviceMotion.rotationRate.x
            let rotationY = deviceMotion.rotationRate.y
            let rotationZ = deviceMotion.rotationRate.z
            print("IOS ROTATION X: \(rotationX) Y: \(rotationY) Z: \(rotationZ)")
            
            //var magneticFieldX = deviceMotion.magneticField.x
            //var attitideYaw = deviceMotion.attitude.yaw
        }
        motionKit.getAttitudeFromDeviceMotion(samplingFrequency) { (attitude) in
            print ("IOS ROTATION MATRIX: \(attitude.rotationMatrix)") // 3x3 matrix
        }
    }
    
    func stopCollection(){
        motionKit.stopGyroUpdates()
        motionKit.stopAccelerometerUpdates()
        motionKit.stopmagnetometerUpdates()
        motionKit.stopDeviceMotionUpdates()
    }
    
    func getExperimentDate() -> String{
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd-HH_mm_ss"
        let dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        return dateInFormat
    }
    
    func writeDataToFile(dataString:String)-> Bool{
        let dataToWrite = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        fileHandle.seekToEndOfFile()
        fileHandle.writeData(dataToWrite)
        return true
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func setOutputFileName(expName:String){
        experimentName = expName
        monitorTextView.text = expName
        csvOutputFileName = "\(expName).csv"
        audioOutputFileName = "\(expName).mp3"
        csvOutputFilePath = getDocumentsDirectory().stringByAppendingPathComponent(csvOutputFileName)
        audioOutputFilePath = getDocumentsDirectory().stringByAppendingPathComponent(audioOutputFileName)

        if !NSFileManager.defaultManager().fileExistsAtPath(csvOutputFilePath){
            NSFileManager.defaultManager().createFileAtPath(csvOutputFilePath, contents: nil, attributes: nil)
        }
        fileHandle = NSFileHandle(forUpdatingAtPath: csvOutputFilePath)!
        
        /*
        for index in 1...10{
            // let string = "\(NSDate())\n"
            let stringToWrite = "Ciao \(index)\n"
            let dataToWrite = stringToWrite.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

            // stringToWrite.writeToFile(csvOutputFilePath, atomically: true, encoding: NSUTF8StringEncoding)

            
            if NSFileManager.defaultManager().fileExistsAtPath(csvOutputFilePath) {
                if let fileHandle = NSFileHandle(forUpdatingAtPath: csvOutputFilePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.writeData(dataToWrite)
                    fileHandle.closeFile()
                }
                else {
                    print("Can't write")
                }
            }
            else {
                NSFileManager.defaultManager().createFileAtPath(csvOutputFilePath, contents: dataToWrite, attributes: nil)
            }

        }
         */
        
        /*
        csvOutputFileName = documentsDirectory.stringByAppendingPathComponent(expName + ".csv")
        audioOutputFileName = documentsDirectory.stringByAppendingPathComponent(expName + ".mp3")
        */
    }
    
    // MARK: Actions
    @IBAction func startStopButtonAction(sender: UIButton) {
        if (isRecording){ // STOPPING COLLECTION
            isRecording = false
            startButton.backgroundColor = UIColor.greenColor()
            stopCollection()
            fileHandle.closeFile()
            monitorTextView.text = ""
        } else { // STARTING COLLECTION
            isRecording = true
            setOutputFileName(getExperimentDate())
            startButton.backgroundColor = UIColor.redColor()
            startCollection()
        }
    }

}
