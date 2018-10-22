//
//  JPEGOptionsController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 28/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class TIFFOptionsController: NSViewController, FormatOptionsControllerProtocol {
	typealias DataItem = TiffFormat
	@IBOutlet weak var algoSelect: NSPopUpButton!
	@IBOutlet weak var preserveTransparencyButton: NSButton!
	
	var data: DataItem?
	var changed = Event<DataItem>()
		
	override func viewDidLoad() {
		self.algoSelect.removeAllItems()
		for item in TiffCompression.list() {
			self.algoSelect.addItem(withTitle: item)
		}
		self.algoSelect.selectItem(withTitle: self.data!.compression.rawValue)
		self.preserveTransparencyButton.state = self.data!.preserveTransparency ? .on : .off;
	}
	
	@IBAction func algoChanged(_ sender: Any?){
		if let c = TiffCompression(rawValue: self.algoSelect.selectedItem?.title ?? "") {
			self.data!.compression = c
			self.changed.emit(data: self.data!)
		}
	}
	
	@IBAction func transparencyChanged(_ sender: Any?){
		self.data!.preserveTransparency = self.preserveTransparencyButton.state == .on ? true : false;
		self.changed.emit(data: self.data!)
	}
}
