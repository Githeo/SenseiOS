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
    let GRAVITY = 9.81
    let CSV_SEP = ";"
    let OPEN_DATA_ARRAY = "["   // to group arrays. e.g., [x, y, z]
    let CLOSE_DATA_ARRAY = "]"  // to group arrays. e.g., [x, y, z]
    let DATA_SEP = ", "         // separator for data in an array. e.g., x, y, z
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
        
        // ------- ACCELEROMETER ---------//
        // Unit = normally is in G, I convert in m/s^2. This includes gravity.
        // Timestamp unit is milliseconds. e.g., 1466001929014.57
        motionKit.getAccelerometerValues(samplingFrequency) { (x, y, z) in
            self.writeDataToFile("IOS Accelerometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP) \(y * self.GRAVITY)\(self.DATA_SEP) \(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n" )
            //print("IOS Accelerometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP)\(y * self.GRAVITY)\(self.DATA_SEP)\(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)")
        }
        // --------- GYROSCOPE -----------//
        // Unit = radiant/sec
        motionKit.getGyroValues(samplingFrequency){ (x, y, z) in
            self.writeDataToFile("IOS Gyroscope\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP) \(y)\(self.DATA_SEP) \(z)\(self.CLOSE_DATA_ARRAY)\n")
            //print("IOS Gyroscope\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP)\(y)\(self.DATA_SEP)\(z)\(self.CLOSE_DATA_ARRAY)\n")
        }
        // -------- MAGNETOMETER ---------//
        // Unit = microTesla
        motionKit.getMagnetometerValues(samplingFrequency){
            (x, y, z) in
            self.writeDataToFile("IOS Magnetometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP) \(y)\(self.DATA_SEP) \(z)\(self.CLOSE_DATA_ARRAY)\n")
            // print("IOS Magnetometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP)\(y * self.GRAVITY)\(self.DATA_SEP)\(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n")
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
            
            print("IOS Pitch-roll-yawn \(deviceMotion.attitude.pitch) \(deviceMotion.attitude.roll) \(deviceMotion.attitude.yaw)")
            //var magneticFieldX = deviceMotion.magneticField.x
            //var attitideYaw = deviceMotion.attitude.yaw
        }
        // ------ ROTATION MATRIX -------- //
        // 3x3 [11, 12, 13, 21, 22, 23, 31, 32, 33]
        motionKit.getAttitudeFromDeviceMotion(samplingFrequency) { (attitude) in
            self.writeDataToFile("IOS Rotation Matrix\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(attitude.rotationMatrix.m11)\(self.DATA_SEP) \(attitude.rotationMatrix.m12)\(self.DATA_SEP) \(attitude.rotationMatrix.m13)\(self.DATA_SEP) \(attitude.rotationMatrix.m21)\(self.DATA_SEP) \(attitude.rotationMatrix.m22)\(self.DATA_SEP) \(attitude.rotationMatrix.m23)\(self.DATA_SEP) \(attitude.rotationMatrix.m31)\(self.DATA_SEP) \(attitude.rotationMatrix.m32)\(self.DATA_SEP) \(attitude.rotationMatrix.m33)\(self.CLOSE_DATA_ARRAY)")
            self.writeDataToFile("IOS PITCH-ROLL-YAW\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(attitude.pitch)\(self.DATA_SEP) \(attitude.roll)\(self.DATA_SEP) \(attitude.yaw)\(self.CLOSE_DATA_ARRAY)")
            // print("PITCH: \(attitude.pitch) \(attitude.roll) \(attitude.yaw))")
        }
        motionKit.getAccelerationFromDeviceMotion(samplingFrequency) { (x, y, z) in
            print("DM acceleration \(x) \(y) \(z)")
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
