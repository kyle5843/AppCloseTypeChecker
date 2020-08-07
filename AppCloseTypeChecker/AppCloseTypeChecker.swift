//
//  AppCloseTypeChecker.swift
//  AppCloseTypeChecker
//
//  Created by Kyle on 2020/8/7.
//  Copyright © 2020 Kyle.peng. All rights reserved.
//

import UIKit

enum AppCloseType:UInt {
    case UnDefined       = 0
    case AppUrade        = 1
    case OSUrade         = 2
    case Crashed         = 3
    case ForceQuit       = 4
    case Intentionally   = 5
    case BackgroundKill  = 6
    case FOOM            = 7
    case NewUser         = 8
}

typealias CheckerCaseBlock = () -> AppCloseType

@objc @objcMembers class AppCloseTypeChecker: NSObject {
    
    public static let sharedInstance = AppCloseTypeChecker()
    private let kCheckerAppTerminate = "kCheckerAppTerminate"
    private let kCheckerAppEnterBackground = "kCheckerAppEnterBackground"
    private let kCheckerActionStack = "kCheckerActionStack"
    private let kCheckerReferenceCount = "kCheckerReferenceCount"
    private var closeType = AppCloseType.FOOM
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *
     *  Set the version of the supported app to filter the old version cases.
     *
     * ------------------------------------------------------------*/
    internal let supportVersion = "1.0.0"
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *
     *  Setup checker at AppDelegate, but after the Crashlytics init
     *
     * ------------------------------------------------------------*/
    public func setup() {
        self.setCrashlytics()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification
            , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification
            , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification
            , object: nil)
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Start check at AppDelegate.
    *
    * ------------------------------------------------------------*/
    public func check() {
        let checkList:Array<CheckerCaseBlock> = [
            // Crash type case has been updated by delegate
            { return self.isNewUser()       },
            { return self.isUnsupported()   },
            { return self.isForceQuit()     },
            { return self.isIntentionally() },
            { return self.isBackgroundKill()},
        ]
        
        for block:CheckerCaseBlock in checkList {
            if self.closeType != .FOOM {
                break;
            }
            self.closeType = block()
        }
        
        self.report()
        self.resetAllStates()
        
    }

    private func resetAllStates() {
        UserDefaults.standard.set(false, forKey: kCheckerAppTerminate)
        UserDefaults.standard.set(false, forKey: kCheckerAppEnterBackground)
        UserDefaults.standard.set("", forKey: kCheckerActionStack)
        UserDefaults.standard.set(Dictionary<String, Int>(), forKey: kCheckerReferenceCount)
    }

    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Import Crashlytics to your project, or use your own crash detector.
    *
    * ------------------------------------------------------------*/
    private func setCrashlytics() {
        //Crashlytics.sharedInstance().delegate = self
    }
    
    //MARK: - Check detail functions
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *
     *  Check here if it is a new user.
     *
     * ------------------------------------------------------------*/
    private func isNewUser() -> AppCloseType{
        let isNewUser = false
        return isNewUser ? .NewUser : self.closeType
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *
     *  Check unsupport version here.
     *
     * ------------------------------------------------------------*/
    private func isUnsupported() -> AppCloseType{
        return self.checkUnSupportVersion() ? .UnDefined : self.closeType
    }

    private func checkUnSupportVersion() -> Bool{
        // check your version.
        return false
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     *
     *  User close app manually.
     *
     * ------------------------------------------------------------*/
    private func isForceQuit() -> AppCloseType{
        let isTerminated = UserDefaults.standard.bool(forKey: kCheckerAppTerminate)
        return isTerminated ? .ForceQuit : self.closeType
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  App closed by system and in the background.
    *
    * ------------------------------------------------------------*/
    private func isBackgroundKill() -> AppCloseType{
        let isBackgroundKill = UserDefaults.standard.bool(forKey: kCheckerAppEnterBackground)
        return isBackgroundKill ? .BackgroundKill : self.closeType
    }
    
    private func isIntentionally() -> AppCloseType{
        // we do not use exec or abort
        return self.closeType
    }
    
    //MARK: - States
    @objc private func appWillTerminate() {
        UserDefaults.standard.set(true, forKey: kCheckerAppTerminate)
    }
    
    @objc private func appDidEnterBackground() {
        UserDefaults.standard.set(true, forKey: kCheckerAppEnterBackground)
    }
    
    @objc private func appWillEnterForeground() {
        UserDefaults.standard.set(false, forKey: kCheckerAppEnterBackground)
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Method Swizzling the ViewDidLoad will help you to trace.
    *
    * ------------------------------------------------------------*/
    public func updateStack(_ action:String){
        var actionStack:String = UserDefaults.standard.object(forKey: kCheckerActionStack) as? String ?? ""
        actionStack.append("# \(action) #")
        UserDefaults.standard.set(actionStack, forKey: kCheckerActionStack)
    }
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Trace the class reference count if need.
    *
    * ------------------------------------------------------------*/
    public func increaseReferenceCount(_ className:String) {
        var referenceCountDict: Dictionary<String, Int> = UserDefaults.standard.object(forKey: kCheckerReferenceCount) as? Dictionary<String, Int> ?? Dictionary<String, Int>()
        if let referenceCount = referenceCountDict[className] {
            referenceCountDict[className] = referenceCount + 1
        } else {
            referenceCountDict[className] = 1
        }
        
        UserDefaults.standard.set(referenceCountDict, forKey: kCheckerReferenceCount)
    }
    
    public func decreaseReferenceCount(_ className:String) {
        var referenceCountDict: Dictionary<String, Int> = UserDefaults.standard.object(forKey: kCheckerReferenceCount) as? Dictionary<String, Int> ?? Dictionary<String, Int>()
        if let referenceCount = referenceCountDict[className], referenceCount > 0 {
            referenceCountDict[className] = referenceCount - 1
        } else {
            referenceCountDict[className] = 0
        }
        UserDefaults.standard.set(referenceCountDict, forKey: kCheckerReferenceCount)
    }
}

extension AppCloseTypeChecker:CrashlyticsDelegate {
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Record the crash type leave.
    *
    * ------------------------------------------------------------*/
    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (Bool) -> Void) {
        
        if report.isCrash {
            self.closeType = .Crashed
        }
        completionHandler(true)
    }
}

extension AppCloseTypeChecker:Report {
    
    /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    *
    *  Do your report item here.
    *
    * ------------------------------------------------------------*/
    func report(){
        
    }
    
    func actionStack() -> String{
        if self.closeType == .FOOM || self.closeType == .Crashed {
            let stack = UserDefaults.standard.object(forKey: kCheckerActionStack) as? String ?? ""
            return String(stack.suffix(2048))
        } else {
            return ""
        }
    }
    
    func referenceCount() ->String {
        if self.closeType == .FOOM, let referenceCountDict = UserDefaults.standard.object(forKey: kCheckerReferenceCount) as? Dictionary<String, Int> {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: referenceCountDict, options: .prettyPrinted)
                if let referenceCountString = String(data: jsonData, encoding: .ascii) {
                    return referenceCountString
                }
            } catch {
                
            }
        }
        
        return ""
    }
}
