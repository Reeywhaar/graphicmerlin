//
//  WindowController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 25/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class WindowController: NSWindowController {
	override var shouldCascadeWindows: Bool {
		get {
			return true;
		}
		set {}
	}
}
