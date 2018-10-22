//
//  JPEGOptionsController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 28/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class PNGOptionsController: NSViewController, FormatOptionsControllerProtocol {
	typealias DataItem = PNGFormat
	@IBOutlet weak var preserveTransparencyButton: NSButton!
	@IBOutlet weak var optimizeButton: NSButton!
	@IBOutlet weak var modeSelect: NSPopUpButton!
	
	var data: DataItem?
	var changed = Event<PNGFormat>()
	
	override func viewDidLoad() {
		let modes: [UInt8] = [8, 24]
		self.modeSelect.removeAllItems();
		for (index, rep) in modes.enumerated() {
			self.modeSelect.addItem(withTitle: "\(rep) bit")
			self.modeSelect.item(at: index)?.representedObject = rep
		}
		self.preserveTransparencyButton.state = data!.preserveTransparency ? .on : .off
		self.modeSelect.selectItem(withTitle: "\(self.data!.mode) bit")
		self.optimizeButton.state = self.data!.optimize ? .on : .off
	}
	
	@IBAction func transparencyChanged(_ sender: Any?){
		self.data!.preserveTransparency = self.preserveTransparencyButton.state == .on ? true : false
		self.changed.emit(data: self.data!)
	}
	
	@IBAction func modeChanged(_ sender: Any?){
		self.data!.mode = self.modeSelect.selectedItem?.representedObject as? UInt8 ?? 24
		self.changed.emit(data: self.data!)
	}
	
	@IBAction func optimizeModeChanged(_ sender: Any?){
		self.data!.optimize = self.optimizeButton.state == .on ? true : false;
		self.changed.emit(data: self.data!)
	}
}
