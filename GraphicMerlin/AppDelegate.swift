//
//  AppDelegate.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ aNotification: Notification) {
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true;
	}	
}

