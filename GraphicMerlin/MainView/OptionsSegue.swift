//
//  OptionsSegue.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 27/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class OptionsSegue: NSStoryboardSegue {
	private let storyBoard = NSStoryboard(name: "Main", bundle: nil)
	private var controller: NSViewController? = nil;
	
	private var target: ExportTarget {
		return (self.sourceController as! PresetViewController).target!
	}
	
	override var destinationController: Any {
		get {
			if self.controller != nil {
				return controller!;
			}
			switch self.target.format {
			case .Tiff(let opts):
				let contr = storyBoard.instantiateController(withIdentifier: "Tiff Options")  as! TIFFOptionsController
				contr.data = opts
				self.controller = contr as NSViewController
				return contr
			case .JPG(let opts):
				let contr = storyBoard.instantiateController(withIdentifier: "JPG Options") as! JPEGOptionsController
				contr.data = opts
				self.controller = contr as NSViewController
				return contr
			case .PNG(let opts):
				let contr = storyBoard.instantiateController(withIdentifier: "PNG Options") as! PNGOptionsController
				contr.data = opts
				self.controller = contr as NSViewController
				return contr
			default:
				self.controller = NSViewController()
				return self.controller!
			}
		}
	}	
}
