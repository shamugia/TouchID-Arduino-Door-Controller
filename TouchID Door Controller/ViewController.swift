//
//  ViewController.swift
//  TouchID Door Controller
//
//  Created by George Shamugia on 23/02/2015.
//  Copyright (c) 2015 George Shamugia. All rights reserved.
//

import UIKit
import LocalAuthentication


class ViewController: UIViewController, BLEDelegate, UIAlertViewDelegate {
    
    let AUTH_PIN:String = "1712"
    
    var ble_device:BLE?
    
    @IBOutlet var statusLabel:UILabel!
    @IBOutlet var actionButton:UIButton!
    
    var preloader:UIActivityIndicatorView!
    var isConnected:Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preloader = UIActivityIndicatorView(frame: CGRectMake(0, 0, 80, 80));
        preloader.layer.cornerRadius = 5 //.5
        preloader.opaque = false
        preloader.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        preloader.center = self.view.center
        preloader.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        preloader.color = UIColor(red: 240/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1.0)
        preloader.hidesWhenStopped = true
        self.view.addSubview(preloader)
        
        connectToBLEDevice()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionButtonClick(sender:AnyObject) {
        if isConnected {
            var context:LAContext = LAContext()
            var error:NSError?
            if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Please verify your identity to open a door", reply: { (success:Bool, error:NSError!) -> Void in
                    if error != nil {
                        if error.code == LAError.UserFallback.rawValue {
                            self.showPinAuthForm()
                        } else {
                            var alert:UIAlertView = UIAlertView(title: "Error", message: "There was a problem verifying your identity. Please try again.", delegate: nil, cancelButtonTitle: "Ok")
                            alert.show()
                        }
                        return
                    }
                    if success {
                        self.openTheDoor()
                    } else {
                        var alert:UIAlertView = UIAlertView(title: "Error", message: "You are not authorized to open this door", delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                })
            } else {
                self.showPinAuthForm()
            }
        }
    }
    
    func showPinAuthForm() {
        var authAlert:UIAlertView = UIAlertView(title: "Please enter the PIN code", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Authenticate")
        authAlert.tag = 1
        // Options: UIAlertViewStyleDefault, UIAlertViewStyleSecureTextInput, UIAlertViewStylePlainTextInput, UIAlertViewStyleLoginAndPasswordInput
        authAlert.alertViewStyle = UIAlertViewStyle.SecureTextInput
        authAlert.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 1 {
            var alertTextField:UITextField = alertView.textFieldAtIndex(0)!
            if AUTH_PIN == alertTextField.text {
                self.openTheDoor()
            } else {
                var alert:UIAlertView = UIAlertView(title: "Error", message: "You are not authorized to open this door", delegate: nil, cancelButtonTitle: "Ok")
                alert.show()
            }
        }
    }
    
    func openTheDoor() {
        // Send random sequence of a digits to arduino, to open a door
        var buf:Array<UInt8> = [0x00, 0x02, 0x01]
        var data:NSData = NSData(bytes: buf, length: 3)
        self.ble_device?.write(data)
    }
    
    func connectToBLEDevice() {
        preloader.startAnimating()
        statusLabel.text = "Connecting..."
        isConnected = false
        
        self.ble_device = BLE()
        self.ble_device?.controlSetup(1)
        self.ble_device?.delegate = self
        tryToConnectToBLEShield()
    }
    
    func tryToConnectToBLEShield() {
        if self.ble_device?.CM.state != CBCentralManagerState.PoweredOn {
            waitAndTryConnectingToBLE()
            return  //@???
        }
        
        if self.ble_device?.peripherals == nil || self.ble_device?.peripherals.count == 0 {
            self.ble_device?.findBLEPeripherals(2)
        } else if !(self.ble_device?.activePeripheral != nil) {
            self.ble_device?.connectPeripheral(self.ble_device?.peripherals[0] as CBPeripheral)
        }
        waitAndTryConnectingToBLE()
    }
    
    func waitAndTryConnectingToBLE() {
        if self.ble_device?.CM.state != CBCentralManagerState.PoweredOn {
            var timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: Selector("tryToConnectToBLEShield"), userInfo: nil, repeats: false)
        } else {
            var timer = NSTimer.scheduledTimerWithTimeInterval(0.20, target: self, selector: Selector("tryToConnectToBLEShield"), userInfo: nil, repeats: false)
        }
    }
    
    func bleDidConnect() {
        statusLabel.text = "Connected..."
        preloader.stopAnimating()
        isConnected = true
        println("Connected to BLE Device")
    }
    
    func bleDidDisconnect() {
        statusLabel.text = "Disconnected... Trying to re-connect..."
        preloader.startAnimating()
        isConnected = false
        println("Disconnected from BLE Device")
    }
    
    func bleDidUpdateRSSI(rssi: NSNumber!) {
        //println("Did RSSI: \(rssi)")
    }
    
    func bleDidReceiveData(data: UnsafeMutablePointer<CChar>, length: Int32) {
        if let str:NSString = String.fromCString(data) {
            var msg:String = "Wrong request.\nUnable to open the door."
            if str == "O" {
                msg = "Success. Door is open."
            }
            var alert:UIAlertView = UIAlertView(title: "Request Status", message: msg, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
}
