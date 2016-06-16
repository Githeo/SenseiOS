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
import CoreMotion
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate {
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
    
    //var audioRecorder: AVAudioRecorder = AVAudioRecorder()
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    //let motionManager: CMMotionManager = CMMotionManager()
    var motionManager: CMMotionManager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.sharedApplication().idleTimerDisabled = true // Keep screen on
        
        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = samplingFrequency
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        print("Permission granted to record audio")
                    } else {
                        print("Permission denied to record audio!")
                    }
                }
            }
        } catch {
            // failed to record!
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startCollection(){
        print("EXPERIMENT: \(experimentName)")
        
        if motionManager.deviceMotionAvailable{
            let queue = NSOperationQueue()
            motionManager.startDeviceMotionUpdatesToQueue(queue, withHandler:
                {data, error in
                    
                    guard let data = data else{
                        return
                    }
                    self.writeDataToFile("IOS DM Linear Acceleration\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(data.userAcceleration.x * self.GRAVITY)\(self.DATA_SEP) \(data.userAcceleration.y * self.GRAVITY)\(self.DATA_SEP) \(data.userAcceleration.z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n ")
                    print("DM acceleration \(data.userAcceleration.x) \(data.userAcceleration.y) \(data.userAcceleration.z)")
                }
            )
        } else {
            print("Accelerometer is not available")
        }
        
        // --------- LINEAR ACCELERATION ----- //
        // Unit = m/s^2 (G originally) without gravity
        motionKit.getAccelerationFromDeviceMotion(samplingFrequency) { (x, y, z) in
            print("DM acceleration \(x) \(y) \(z)")
            self.writeDataToFile("IOS DM Linear Acceleration\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP) \(y * self.GRAVITY)\(self.DATA_SEP) \(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n ")
        }
        
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

        // ------ ROTATION MATRIX -------- //
        // 3x3 [11, 12, 13, 21, 22, 23, 31, 32, 33]
        motionKit.getAttitudeFromDeviceMotion(samplingFrequency) { (attitude) in
            self.writeDataToFile("IOS Rotation Matrix\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(attitude.rotationMatrix.m11)\(self.DATA_SEP) \(attitude.rotationMatrix.m12)\(self.DATA_SEP) \(attitude.rotationMatrix.m13)\(self.DATA_SEP) \(attitude.rotationMatrix.m21)\(self.DATA_SEP) \(attitude.rotationMatrix.m22)\(self.DATA_SEP) \(attitude.rotationMatrix.m23)\(self.DATA_SEP) \(attitude.rotationMatrix.m31)\(self.DATA_SEP) \(attitude.rotationMatrix.m32)\(self.DATA_SEP) \(attitude.rotationMatrix.m33)\(self.CLOSE_DATA_ARRAY)\n ")
            self.writeDataToFile("IOS PITCH-ROLL-YAW\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(attitude.pitch)\(self.DATA_SEP) \(attitude.roll)\(self.DATA_SEP) \(attitude.yaw)\(self.CLOSE_DATA_ARRAY)\n ")
            // print("PITCH: \(attitude.pitch) \(attitude.roll) \(attitude.yaw))")
        }
        
        // ------------ GRAVITY --------------- //
        // Unit = m/s^2 (G originally)
        motionKit.getGravityAccelerationFromDeviceMotion(samplingFrequency) { (x, y, z) in
            print("IOS DM GRAVITY \(x) \(y) \(z)")
            self.writeDataToFile("IOS DM Gravity\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP) \(y * self.GRAVITY)\(self.DATA_SEP) \(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n ")
            
        }
        
        // ------------ ROTATION RATE --------- //
        motionKit.getRotationRateFromDeviceMotion(samplingFrequency) { (x, y, z) in
            //print("DM Rotation rate")
            self.writeDataToFile("IOS DM Gravity\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate())\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP) \(y)\(self.DATA_SEP) \(z)\(self.CLOSE_DATA_ARRAY)\n ")
        }

    }
    
    func stopCollection(){
        motionKit.stopGyroUpdates()
        motionKit.stopAccelerometerUpdates()
        motionKit.stopmagnetometerUpdates()
        motionKit.stopDeviceMotionUpdates()
        if motionManager.deviceMotionAvailable{
            motionManager.stopDeviceMotionUpdates()
        }
        //motionManager.stopDeviceMotionUpdates()
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
        
    }
    
    func startAudioRecording(){
        let settings: [String : AnyObject] = [
            AVFormatIDKey:Int(kAudioFormatAppleIMA4), //Int required in Swift2
            AVSampleRateKey:44100.0,
            AVNumberOfChannelsKey:2,
            AVEncoderBitRateKey:12800,
            AVLinearPCMBitDepthKey:16,
            AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue
        ]
        let audioFileUrl = NSURL(fileURLWithPath: audioOutputFilePath) // or let fileUrl = NSURL(string: filePath)
        do {
            audioRecorder = try AVAudioRecorder(URL: audioFileUrl, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.record()
        } catch {
            finishAudioRecording(success: false)
        }
    }
    
    func finishAudioRecording(success success: Bool) {
        audioRecorder.stop()
        //audioRecorder = nil
        if success {
            print("Audio recording - Stopped")
        } else {
            print("Audio recording - Failed")
        }
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishAudioRecording(success: false)
        }
    }
    
    // MARK: Actions
    @IBAction func startStopButtonAction(sender: UIButton) {
        if (isRecording){ // STOPPING COLLECTION
            isRecording = false
            startButton.backgroundColor = UIColor.greenColor()
            stopCollection()
            fileHandle.closeFile()
            monitorTextView.text = ""
            //finishAudioRecording(success: true)
        } else { // STARTING COLLECTION
            isRecording = true
            setOutputFileName(getExperimentDate())
            startButton.backgroundColor = UIColor.redColor()
            startCollection()
            //startAudioRecording()
            //motionManager.startDeviceMotionUpdates()
        }
    }

}
