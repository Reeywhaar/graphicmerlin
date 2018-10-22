//
//  NumberFieldDelegate.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 24/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class OnlyNumberFormatter: NumberFormatter {
	override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		if partialString.isEmpty {
			return true
		}
		
		return Int(partialString) != nil
	}
}
