//
//  PreferencesController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 27/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class PreferencesController: NSViewController {
	@IBOutlet weak var openDirectoryButton: NSButton!;
	@IBOutlet weak var formatsBox: NSBox!;
	@IBOutlet weak var formatsContainer: NSView!;
	private lazy var controllers: [(NSViewController, String, UInt16)] = {
		return [
			("JPG", 44 as UInt16),
			("Tiff", 48 as UInt16),
			("PNG", 69 as UInt16),
		].map({
			var cnt = self.storyboard!.instantiateController(withIdentifier: "\($0.0) Options") as! NSViewController
			let opts = try! Preferences.shared.getFormatPreset(forRawValue: $0.0)
			if let cntp = cnt as? TIFFOptionsController {
				cntp.data = opts.getOptions()
				cntp.changed.addListener(target: self, handler: PreferencesController.onChange)
			}
			if let cntp = cnt as? JPEGOptionsController {
				cntp.data = opts.getOptions()
				cntp.changed.addListener(target: self, handler: PreferencesController.onChange)
			}
			if let cntp = cnt as? PNGOptionsController {
				cntp.data = opts.getOptions()
				cntp.changed.addListener(target: self, handler: PreferencesController.onChange)
			}
			return (cnt, $0.0, $0.1);
		})
	}()
	
	func onChange<U: ImageFormatProtocol>(_ data: U){
		if let fmt = ImageFormat.from(format: data) {
			try? Preferences.shared.setFormatPreset(for: fmt)
		}
	}
	
	func createHorizontalLine() -> NSView {
		let box = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
		box.translatesAutoresizingMaskIntoConstraints = false
		box.wantsLayer = true
		box.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor
		box.addConstraint(
			NSLayoutConstraint(item: box, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1)
		)
		return box
	}
	
	override func viewDidLoad() {
		let padding: CGFloat = 2.0;
		
		for (index, (cnt, name, height)) in self.controllers.enumerated() {
			let label = NSTextField.init(string: name)
			label.isEditable = false
			label.drawsBackground = false;
			label.backgroundColor = NSColor.clear
			label.translatesAutoresizingMaskIntoConstraints = false
			label.cell?.isBordered = false
			
			var hLine: NSView? = nil
			if index > 0 {
				hLine = self.createHorizontalLine()
				self.formatsContainer.addSubview(hLine!)
			}
			self.formatsContainer.addSubview(label)
			
			cnt.loadView()
			self.formatsContainer.addSubview(cnt.view)
			cnt.view.translatesAutoresizingMaskIntoConstraints = false
			
			if index == 0 {
				self.formatsContainer.addConstraints([
					NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self.formatsContainer, attribute: .top, multiplier: 1.0, constant: padding),
				])
			} else {
				self.formatsContainer.addConstraints([
					NSLayoutConstraint(item: hLine!, attribute: .top, relatedBy: .equal, toItem: self.controllers[index - 1].0.view, attribute: .bottom, multiplier: 1.0, constant: padding + 10.0),
					NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: hLine!, attribute: .top, multiplier: 1.0, constant: padding + 2.0),
					NSLayoutConstraint(item: hLine!, attribute: .leading, relatedBy: .equal, toItem: self.formatsContainer, attribute: .leading, multiplier: 1.0, constant: padding + 5.0),
					NSLayoutConstraint(item: hLine!, attribute: .trailing, relatedBy: .equal, toItem: self.formatsContainer, attribute: .trailing, multiplier: 1.0, constant: -padding - 5.0),
				])
			}
			
			self.formatsContainer.addConstraints([
				NSLayoutConstraint(item: cnt.view, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1.0, constant: -4.0),
				NSLayoutConstraint(item: cnt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(height)),
				NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: self.formatsContainer, attribute: .leading, multiplier: 1.0, constant: padding + 5.0),
				NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: self.formatsContainer, attribute: .trailing, multiplier: 1.0, constant: -padding - 5.0),
				NSLayoutConstraint(item: cnt.view, attribute: .leading, relatedBy: .equal, toItem: self.formatsContainer, attribute: .leading, multiplier: 1.0, constant: padding),
				NSLayoutConstraint(item: cnt.view, attribute: .trailing, relatedBy: .equal, toItem: self.formatsContainer, attribute: .trailing, multiplier: 1.0, constant: -padding),
			])
		}
		
		self.formatsBox.addConstraints([
			NSLayoutConstraint(item: self.formatsContainer, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: self.controllers[self.controllers.count - 1].0.view, attribute: .bottom, multiplier: 1.0, constant: padding),
		])
		
		let state: NSControl.StateValue = Preferences.shared.openDirectoryAfterExport ? .on : .off;
		
		self.openDirectoryButton.cell?.state = state;
	}
	
	@IBAction func takeOpenDirectoryValue(_ sender: Any){
		let value = (sender as! NSButton).cell!.state == .on ? true : false;
		return Preferences.shared.openDirectoryAfterExport = value;
	}
}
