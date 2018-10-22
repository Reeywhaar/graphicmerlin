//
//  TextChangeDelegate.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 25/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class TextChangeDelegate: NSObject, NSTextFieldDelegate {
	let changed = Event<Any?>();
	
	func controlTextDidChange(_ obj: Notification) {
		self.changed.emit(data: nil)
	}
}
