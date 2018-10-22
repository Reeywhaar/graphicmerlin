//
//  PreferencesController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 27/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class PresetViewController: NSViewController {
	@IBOutlet weak var widthLabel: NSTextField!;
	@IBOutlet weak var heightLabel: NSTextField!;
	@IBOutlet weak var formatSelect: NSPopUpButton!;
	@IBOutlet weak var formatOptionsButton: NSButton!;
	@IBOutlet weak var existStrategySelect: NSPopUpButton!;
	@IBOutlet weak var renamePatternLabel: NSTextField!;
	@IBOutlet weak var renamePatternPopUp: NSPopUpButton!;
	
	let numberFieldDelegate = OnlyNumberFormatter();
	let sizeChangeDelegate = TextChangeDelegate()
	let renamePatternDelegate = TextChangeDelegate()
	
	private var disposables: [Disposable] = []
	
	var target: ExportTarget?
	
	override func viewDidLoad() {
		self.disposables.append(
			self.target!.changed.addListener(target: self, handler: PresetViewController.onTargetChange)
		)
		
		self.disposables.append(
			self.sizeChangeDelegate.changed.addListener(target: self, handler: PresetViewController.onSizeLabelChange)
		)
		
		self.widthLabel.stringValue = target!.size.0 == nil ? "" : String(target!.size.0!)
		self.widthLabel.formatter = self.numberFieldDelegate;
		self.widthLabel.delegate = self.sizeChangeDelegate
		
		self.heightLabel.stringValue = target!.size.1 == nil ? "" : String(target!.size.1!)
		self.heightLabel.formatter = self.numberFieldDelegate;
		self.heightLabel.delegate = sizeChangeDelegate
		
		self.formatSelect.removeAllItems()
		self.formatSelect.addItems(withTitles: ImageFormat.list())
		self.formatSelect.selectItem(withTitle: self.target!.format.rawValue)
		
		self.formatOptionsButton.isEnabled = item(self.target!.format.rawValue, in: ["Tiff", "JPG", "PNG"])
		
		self.existStrategySelect.removeAllItems()
		self.existStrategySelect.addItems(withTitles: ExistsStrategy.allCasesString)
		self.existStrategySelect.selectItem(withTitle: self.target!.existsStrategy.rawValue)
		self.existStrategySelect.toolTip = "Action if exported file already exists"
		
		self.renamePatternPopUp.removeAllItems()
		self.renamePatternPopUp.addItems(withTitles: ExportData.Substitutes.allCases.map({$0.substitute()}))
		
		self.disposables.append(
			self.renamePatternDelegate.changed.addListener(target: self, handler: PresetViewController.onRenamePatternLabelChange)
		)
		self.renamePatternLabel.stringValue = self.target!.renamePattern
		self.renamePatternLabel.delegate = self.renamePatternDelegate
	}
	
	func onTargetChange(_ data: ([ExportTarget.Keys], ExportTarget)){
		if data.0.contains(.format) {
			if self.formatSelect.selectedItem?.title != data.1.format.rawValue {
				self.formatSelect.selectItem(withTitle: data.1.format.rawValue)
			}
			self.formatOptionsButton.isEnabled = item(data.1.format.rawValue, in: ["Tiff", "JPG", "PNG"])
		}
		if data.0.contains(.existsStrategy) {
			if self.existStrategySelect.selectedItem?.title != data.1.existsStrategy.rawValue {
				self.existStrategySelect.selectItem(withTitle: data.1.existsStrategy.rawValue)
			}
		}
		if data.0.contains(.size) {
			let w = data.1.size.0 == nil ? "" : "\(data.1.size.0!)"
			if self.widthLabel.stringValue != w {
				self.widthLabel.stringValue = w
			}
			let h = data.1.size.1 == nil ? "" : "\(data.1.size.1!)"
			if self.heightLabel.stringValue != h {
				self.heightLabel.stringValue = h
			}
		}
		if data.0.contains(.renamePattern) {
			if self.renamePatternLabel.stringValue != data.1.renamePattern {
				self.renamePatternLabel.stringValue = data.1.renamePattern
			}
		}
	}
	
	@IBAction func selectFormat(_ sender: AnyObject) {
		if let title = (sender as? NSPopUpButton)?.selectedItem?.title {
			if title == self.target!.format.rawValue {
				return
			}
			if let prefs = try? Preferences.shared.getFormatPreset(forRawValue: title) {
				self.target!.format = prefs
				return
			}
			
			self.target!.format = ImageFormat.init(rawValue: title)
		}
	}
	
	@IBAction func onSizeLabelChange(_ sender: Any?) {
		var a: UInt? = UInt(self.widthLabel.intValue)
		if a == 0 {
			a = nil
		}
		var b: UInt? = UInt(self.heightLabel.intValue)
		if b == 0 {
			b = nil
		}
		self.target!.size = (a, b)
	}
	
	@IBAction func existsStrategyChange(_ sender: Any?){
		if self.existStrategySelect.selectedItem?.title == self.target!.existsStrategy.rawValue {
			return;
		}
		if let value: ExistsStrategy = ExistsStrategy(rawValue: self.existStrategySelect.selectedItem!.title) {
			self.target!.existsStrategy = value
		}
	}
	
	@IBAction func onRenamePatternLabelChange(_ sender: Any?){
		if self.renamePatternLabel.stringValue != self.target!.renamePattern {
			self.target!.renamePattern = self.renamePatternLabel.stringValue
		}
	}
	
	@IBAction func onRenamePatternPopUpCHange(_ sender: Any?){
		let p = self.renamePatternPopUp.selectedItem?.title ?? ""
		if let cd = self.renamePatternLabel.currentEditor() {
			cd.insertText(p)
		} else {
			self.renamePatternLabel.stringValue = self.renamePatternLabel.stringValue + p
		}
		self.onRenamePatternLabelChange(self)
	}
	
	private func onFormatOptionsChange<T: ImageFormatProtocol>(_ opts: T){
		self.target!.format = ImageFormat.from(format: opts)!
	}
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		if segue is OptionsSegue {
			if let cnt = segue.destinationController as? TIFFOptionsController {
				cnt.changed.addListener(target: self, handler: PresetViewController.onFormatOptionsChange)
			}
			if let cnt = segue.destinationController as? JPEGOptionsController {
				cnt.changed.addListener(target: self, handler: PresetViewController.onFormatOptionsChange)
			}
			if let cnt = segue.destinationController as? PNGOptionsController {
				cnt.changed.addListener(target: self, handler: PresetViewController.onFormatOptionsChange)
			}
		}
	}
	
	deinit {
		for d in disposables {
			d.dispose()
		}
	}
}
