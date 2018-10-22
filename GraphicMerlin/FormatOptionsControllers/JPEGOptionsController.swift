//
//  JPEGOptionsController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 28/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class JPEGOptionsController: NSViewController, FormatOptionsControllerProtocol {
	typealias DataItem = JPEGFormat
	@IBOutlet weak var qualitySlider: NSSlider!
	@IBOutlet weak var qualityLabel: NSTextField!
	
	var data: DataItem?
	var changed = Event<JPEGFormat>()
	
	override func viewDidLoad() {
		self.qualitySlider.cell?.takeIntValueFrom(self.data!.quality)
		self.qualityLabel.cell?.intValue = Int32(self.data!.quality)
	}
	
	@IBAction func qualityChanged(_ sender: Any?){
		let val = self.qualitySlider.cell?.intValue ?? 70
		self.qualityLabel.cell?.intValue = val
		self.data!.quality = UInt8(val)
		self.changed.emit(data: self.data!)
	}
}
