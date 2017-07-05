//
//  ViewController.swift
//  BLEConnectivityBG
//
//  Created by Prajwal Lobo on 04/07/17.
//  Copyright © 2017 Prajwal Lobo. All rights reserved.
//

import UIKit
import CoreBluetooth
import  UserNotifications
import UserNotificationsUI


let requestIdentifier = "SampleRequest"

class ViewController: UIViewController, CBCentralManagerDelegate,CBPeripheralDelegate {
    
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    var scanAfterDisconnecting = true

    
    //MARK:- IBOutlets
    
    @IBOutlet weak var rssiLabel: UILabel! //To show singal strength
    @IBOutlet weak var statusLabel: UILabel! //Connection status
    @IBOutlet weak var connectionStatusView: UIView! //Connect/Disconnect view
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! //Scan indicator
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        scanAfterDisconnecting = false
        disconnect()
    }
    
    @IBAction func startScanAction(_ sender: Any) {
        startScanning()
    }
    @IBAction func stopScanAction(_ sender: Any) {
        stopScanning()
    }
    
 
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alertWith(_ title : String, message : String){
        let alertController = UIAlertController(title: "Hey!", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel
            , handler: nil)
        alertController .addAction(alertAction)
        dismiss(animated: true, completion: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    
       //MARK:- CBCentralManagerDelegate Delegate
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let deviceName = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) else{return}
            print("Bluetooth device name : \(String(describing: deviceName))")

        
        if RSSI.intValue < -30 {
            rssiLabel.textColor = UIColor.red
           // return; //Uncomment to ignore device with less signal strength
        }
        
        rssiLabel.text = RSSI.stringValue
        if peripheral.name == Device.B_NAME{ //Here i'm trying to connect to the specific device which im intrested
            self.peripheral = peripheral //Remembering the last connected device.
            manager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let UUID = peripheral.identifier.uuidString
        let name = peripheral.name
       // alertWith("Disconnected", message: "Device with name:\(String(describing: name)) identifier : \(UUID) disconnected")
        connectionStatusView.backgroundColor = UIColor.red
       // self.peripheral = nil
        print("Disconnected from : \(name!, UUID)")
        if scanAfterDisconnecting {
            startScanning()
        }
        statusLabel.text = "Disconnected"
        triggerNotificationWith("Disconnected", message: "Disconnected from : \(name!, UUID)") //Local notification

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let UUID = peripheral.identifier.uuidString
        let name = peripheral.name
        //alertWith("Connected", message: "Device with name:\(String(describing: name)) identifier : \(UUID) connected")
        connectionStatusView.backgroundColor = UIColor.green
        statusLabel.text = "Connected to : \(name!)"
        print("Connected to : \(name!, UUID)")
        peripheral.delegate = self
        activityIndicator.stopAnimating()
        manager.stopScan()
        triggerNotificationWith("Connected", message: statusLabel.text!)
    }
    
    func startScanning() {
        if manager.isScanning {
            print("Central Manager is already scanning!!")
            return
        }
        let lastPeripherals = manager.retrieveConnectedPeripherals(withServices: [CBUUID(string: Device.peripheralDevice)])
        if lastPeripherals.count > 0{
            let device = lastPeripherals.last!
            peripheral = device
            manager.connect(peripheral!, options: nil)
        }
        else if self.peripheral != nil {
            print("Connected to last discovered peripheral from the rembered instance")
            manager.connect(peripheral!, options: nil)
        }
        else {
            print("Last connected peripheral not found")
           // manager.scanForPeripherals(withServices: [CBUUID(string: Device.peripheralDevice)], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            manager.scanForPeripherals(withServices: [CBUUID(string: Device.peripheralDevice)], options:nil)

        }
        print("Scanning Started!")
        triggerNotificationWith("Scan started", message: "Fasten your seat belt")
    }
    
    
    func stopScanning() {
        manager.stopScan()
    }
    
    func disconnect() {
        // verify we have a peripheral
        guard let peripheral = self.peripheral else {
            print("Peripheral object has not been created yet.")
            return
        }
        
        // check to see if the peripheral is connected
        if peripheral.state != .connected {
            print("Peripheral exists but is not connected.")
            self.peripheral = nil
            return
        }
        
        guard let services = peripheral.services else {
            // disconnect directly
            manager.cancelPeripheralConnection(peripheral)
            return
        }
        
//        for service in services {
//            // iterate through characteristics
//            if let characteristics = service.characteristics {
//                for characteristic in characteristics {
//                    // find the Transfer Characteristic we defined in our Device struct
//                    if characteristic.uuid == CBUUID.init(string: Device.peipheralChar) {
//                        // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
//                        // didUpdateNotificationStateForCharacteristic method will be called automatically
//                        peripheral.setNotifyValue(false, for: characteristic)
//                        return
//                    }
//                }
//            }
//        }
        
        // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
        // Therefore, we will just disconnect from the peripheral
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral) (\(String(describing: error?.localizedDescription)))")
        connectionStatusView.backgroundColor = UIColor.red
        disconnect()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            self.peripheral = nil
            return
        }
        switch central.state {
        case .poweredOn:
            startScanning()
        default:
            break
        }
        activityIndicator.startAnimating()
        guard let peripheral = self.peripheral else {
            return
        }
        
        // see if that peripheral is connected
        guard peripheral.state == .connected else {
            return
        }

    }
    
    func triggerNotificationWith(_ title : String, message : String){
        
        print("Firing the notification")
        let content = UNMutableNotificationContent()
       // content.title = title;
        content.subtitle = title
        content.body = message
        content.sound = UNNotificationSound.default()

//        
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request){(error) in
            
            if (error != nil){
                
                print(error?.localizedDescription ?? "")
            }
        }
    }

}

extension ViewController:UNUserNotificationCenterDelegate{
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Tapped in notification")
    }
    
    //This is key callback to present notification while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notification  triggered")
        if notification.request.identifier == requestIdentifier{
            
            completionHandler( [.alert,.sound,.badge])
            
        }
    }
}

