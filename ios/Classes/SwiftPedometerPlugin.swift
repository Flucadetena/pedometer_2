import Flutter
import UIKit

import CoreMotion

public class SwiftPedometerPlugin: NSObject, FlutterPlugin {
    // Register Plugin
    public static func register(with registrar: FlutterPluginRegistrar) {
        let streamStepDetectionHandler = StreamStepDetector()
        let streamStepDetectionChannel = FlutterEventChannel.init(name: "status_detection", binaryMessenger: registrar.messenger())
        streamStepDetectionChannel.setStreamHandler(streamStepDetectionHandler)
        
        let oldstreamStepCountHandler = OldStreamStepCounter()
        let oldstreamStepCountChannel = FlutterEventChannel.init(name: "step_count", binaryMessenger: registrar.messenger())
        oldstreamStepCountChannel.setStreamHandler(oldstreamStepCountHandler)
        
        let eventChannelName = "step_count_from";
        let eventChannel = FlutterEventChannel.init(name: eventChannelName, binaryMessenger: registrar.messenger())
        let streamStepCountHandler = StreamStepCounter()
        eventChannel.setStreamHandler(streamStepCountHandler)
        
        let methodChannelName = "method_channel";
        let methodChannel = FlutterMethodChannel.init(name: methodChannelName, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SwiftPedometerPlugin(), channel: methodChannel)
    }
    
    private let stepCount = StepCount()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method.elementsEqual("getStepCount") {
            stepCount.getSteps(call: call, channelResult: result)
        }
    }
}

/// StepDetector, handles pedestrian status streaming
public class StreamStepDetector: NSObject, FlutterStreamHandler {
    private let pedometer = CMPedometer()
    private var running = false
    private var eventSink: FlutterEventSink?
    
    private func handleEvent(status: Int) {
        // If no eventSink to emit events to, do nothing (wait)
        if (eventSink == nil) {
            return
        }
        // Emit pedestrian status event to Flutter
        eventSink!(status)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        
        if #available(iOS 10.0, *) {
            if (!CMPedometer.isPedometerEventTrackingAvailable()) {
                eventSink(FlutterError(code: "2", message: "Step Detection is not available", details: nil))
            }
            else if (!running) {
                running = true
                pedometer.startEventUpdates() {
                    pedometerData, error in
                    guard let pedometerData = pedometerData, error == nil else { return }
                    
                    DispatchQueue.main.async {
                        self.handleEvent(status: pedometerData.type.rawValue)
                    }
                }
            }
        } else {
            eventSink(FlutterError(code: "1", message: "Requires iOS 10.0 minimum", details: nil))
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        
        if (running) {
            pedometer.stopUpdates()
            running = false
        }
        return nil
    }
}

/// StepCounter, handles step count streaming
public class OldStreamStepCounter: NSObject, FlutterStreamHandler {
    private let pedometer = CMPedometer()
    private var running = false
    private var eventSink: FlutterEventSink?
    
    private func handleEvent(count: Int) {
        // If no eventSink to emit events to, do nothing (wait)
        if (eventSink == nil) {
            return
        }
        // Emit step count event to Flutter
        eventSink!(count)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        if #available(iOS 10.0, *) {
            if (!CMPedometer.isStepCountingAvailable()) {
                eventSink(FlutterError(code: "3", message: "Step Count is not available", details: nil))
            }
            else if (!running) {
                let systemUptime = ProcessInfo.processInfo.systemUptime;
                let timeNow = Date().timeIntervalSince1970
                let dateOfLastReboot = Date(timeIntervalSince1970: timeNow - systemUptime)
                running = true
                pedometer.startUpdates(from: dateOfLastReboot) {
                    pedometerData, error in
                    guard let pedometerData = pedometerData, error == nil else { return }
                    
                    DispatchQueue.main.async {
                        self.handleEvent(count: pedometerData.numberOfSteps.intValue)
                    }
                }
            }
        } else {
            eventSink(FlutterError(code: "1", message: "Requires iOS 10.0 minimum", details: nil))
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        
        if (running) {
            pedometer.stopUpdates()
            running = false
        }
        return nil
    }
}

public class StreamStepCounter: NSObject, FlutterStreamHandler {
    private let pedometer = CMPedometer()
    private var running = false
    private var eventSink: FlutterEventSink?
    
    private func handleEvent(count: Int) {
        // If no eventSink to emit events to, do nothing (wait)
        if (eventSink == nil) {
            return
        }
        // Emit step count event to Flutter
        eventSink!(count)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        if #available(iOS 10.0, *) {
            if (!CMPedometer.isStepCountingAvailable()) {
                eventSink(FlutterError(code: "3", message: "Step Count is not available", details: nil))
            }
            else if (!running) {
                guard let arguments = arguments as? NSDictionary,
                      let startTime = (arguments["startTime"] as? NSNumber)
                else {
                    eventSink(FlutterError(code: "3", message: "Not arrowed arguments", details: nil))
                    return nil
                }

                let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)

                running = true
                pedometer.startUpdates(from: dateFrom) {
                    pedometerData, error in
                    guard let pedometerData = pedometerData, error == nil else { return }
                    
                    DispatchQueue.main.async {
                        self.handleEvent(count: pedometerData.numberOfSteps.intValue)
                    }
                }
            }
        } else {
            eventSink(FlutterError(code: "1", message: "Requires iOS 10.0 minimum", details: nil))
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        
        if (running) {
            pedometer.stopUpdates()
            running = false
        }
        return nil
    }
}


public class StepCount: NSObject {
    private let pedometer = CMPedometer()
    
    func getSteps(call: FlutterMethodCall, channelResult: @escaping FlutterResult) {
        if (!CMPedometer.isStepCountingAvailable()) {
            channelResult(FlutterError(code: "3", message: "Not isStepCountingAvailable", details: nil))
            return
        }
        guard let arguments = call.arguments as? NSDictionary,
              let startTime = (arguments["startTime"] as? NSNumber),
              let endTime = (arguments["endTime"] as? NSNumber)
        else {
            channelResult(FlutterError(code: "3", message: "Not arrowed arguments", details: nil))
            return
        }
        let dateFrom = Date(timeIntervalSince1970: startTime.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endTime.doubleValue / 1000)
        pedometer.queryPedometerData(from: dateFrom, to: dateTo) { (data, error) in
            if (error == nil) {
                guard let steps = data?.numberOfSteps
                else {
                    channelResult(FlutterError(code: "3", message: "Not get numberOfSteps", details: nil))
                    return
                }
                channelResult(steps.intValue)
            } else {
                channelResult(FlutterError(code: "3", message: "Error: \(error!)", details: nil))
            }
        }
    }
}
