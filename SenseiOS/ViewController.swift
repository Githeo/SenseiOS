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
    let samplingFrequency = 0.01 // 0.1 = 10Hz, 0.01 = 100Hz
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
    
    var motionManager: CMMotionManager!
    
    let dateFormatter = NSDateFormatter() // yyyy-MM-dd HH:mm:ssSSS

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.sharedApplication().idleTimerDisabled = true // Keep screen on
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
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
        
        // ---------- DEVICE MOTION -------- //
        // Linear acceleration unit = m/s^2 (G originally). DM does not include gravity
        if motionManager.deviceMotionAvailable{
            let queue = NSOperationQueue()
            motionManager.startDeviceMotionUpdatesToQueue(queue, withHandler:
                {data, error in
                    
                    guard let data = data else{
                        return
                    }
                    let date = NSDate()
                    // ---------- LINEAR ACCELERATION --------//
                    self.writeDataToFile("IOS DM Linear Acceleration\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(data.userAcceleration.x * self.GRAVITY)\(self.DATA_SEP) \(data.userAcceleration.y * self.GRAVITY)\(self.DATA_SEP) \(data.userAcceleration.z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n")
                    //print("DM acceleration \(date.timeIntervalSince1970*1000) \(self.dateFormatter.stringFromDate(date)) \(data.userAcceleration.x) \(data.userAcceleration.y) \(data.userAcceleration.z)")
                    
                    // ---------- ROTATION MATRIX ------------//
                    self.writeDataToFile("IOS DM Rotation Matrix\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(data.attitude.rotationMatrix.m11)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m12)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m13)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m21)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m22)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m23)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m31)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m32)\(self.DATA_SEP) \(data.attitude.rotationMatrix.m33)\(self.CLOSE_DATA_ARRAY)\n")
                    //print("DM rotation matrix \(data.attitude.rotationMatrix)")
                    
                    // ----------- ROTATION VECTOR ------------//
                    self.writeDataToFile("IOS DM Pith-Roll-Yaw\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(data.attitude.pitch)\(self.DATA_SEP) \(data.attitude.roll)\(self.DATA_SEP) \(data.attitude.yaw)\(self.CLOSE_DATA_ARRAY)\n")
                    //print("DM rotation vector \(data.attitude.pitch)")
                    
                    // ----------- CALIBRATED Gyroscope -------//
                    self.writeDataToFile("IOS DM Calibrated Gyroscope\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(data.rotationRate.x)\(self.DATA_SEP) \(data.rotationRate.y)\(self.DATA_SEP) \(data.rotationRate.z)\(self.CLOSE_DATA_ARRAY)\n")
                    print("IOS DM Calibrated Gyroscope \(data.rotationRate.x)")
                    
                }
            )
        } else {
            print("Device Motion is not available!")
        }
        
        // ------- ACCELEROMETER ---------//
        // Unit = normally is in G, I convert in m/s^2. This includes gravity.
        // Timestamp unit is milliseconds. e.g., 1466001929014.57
        motionKit.getAccelerometerValues(samplingFrequency) { (x, y, z) in
            let date = NSDate()
            self.writeDataToFile("IOS Accelerometer\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP) \(y * self.GRAVITY)\(self.DATA_SEP) \(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n" )
            //print("IOS Accelerometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP)\(y * self.GRAVITY)\(self.DATA_SEP)\(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)")
        }
        // --------- GYROSCOPE -----------//
        // Unit = radiant/sec
        motionKit.getGyroValues(samplingFrequency){ (x, y, z) in
            let date = NSDate()
            self.writeDataToFile("IOS Gyroscope\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP) \(y)\(self.DATA_SEP) \(z)\(self.CLOSE_DATA_ARRAY)\n")
            //print("IOS Gyroscope\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP)\(y)\(self.DATA_SEP)\(z)\(self.CLOSE_DATA_ARRAY)\n")
        }
        // -------- MAGNETOMETER ---------//
        // Unit = microTesla
        motionKit.getMagnetometerValues(samplingFrequency){
            (x, y, z) in
            let date = NSDate()
            self.writeDataToFile("IOS Magnetometer\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x)\(self.DATA_SEP) \(y)\(self.DATA_SEP) \(z)\(self.CLOSE_DATA_ARRAY)\n")
            // print("IOS Magnetometer\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(NSDate().timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP)\(y * self.GRAVITY)\(self.DATA_SEP)\(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n")
        }
        
        // ------------ GRAVITY --------------- //
        // Unit = m/s^2 (G originally)
        motionKit.getGravityAccelerationFromDeviceMotion(samplingFrequency) { (x, y, z) in
            let date = NSDate()
            //print("IOS DM GRAVITY \(x) \(y) \(z)")
            self.writeDataToFile("IOS DM Gravity\(self.CSV_SEP)\(date.timeIntervalSince1970 * 1000)\(self.CSV_SEP)\(self.dateFormatter.stringFromDate(date))\(self.CSV_SEP)\(self.OPEN_DATA_ARRAY)\(x * self.GRAVITY)\(self.DATA_SEP) \(y * self.GRAVITY)\(self.DATA_SEP) \(z * self.GRAVITY)\(self.CLOSE_DATA_ARRAY)\n")
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
        let settings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
                         AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEGLayer3)),
                         AVNumberOfChannelsKey : NSNumber(int: 1),
                         AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.High.rawValue)),
                         AVEncoderBitRateKey : NSNumber(int: Int32(320000))]
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
