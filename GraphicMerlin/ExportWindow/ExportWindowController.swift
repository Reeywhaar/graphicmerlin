//
//  ExportWindow.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 24/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa

class ExportWindowController: NSWindowController {
	enum Status {
		case Ok
		case Aborted
	}
	
	@IBOutlet weak var _contentViewController: NSViewController?
	let complete = Event<ExportWindowController.Status>();
	
	override var contentViewController: NSViewController? {
		get {
			return self._contentViewController;
		}
		set {
			self._contentViewController = newValue;
		}
	}
	
	override var windowNibName: NSNib.Name? {
		return "ExportWindow"
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		
		(self.contentViewController as! ExportViewController)
			.complete
			.addListener(target: self, handler: ExportWindowController.onProgressComplete)
		
		self.window?.delegate = self;
    }
	
	func onProgressComplete(_ s: ExportViewController.Status){
		self.complete.emit(data: .Ok)
	}
}

extension ExportWindowController: NSWindowDelegate {
	func windowWillClose(_ notification: Notification) {
		self.complete.emit(data: .Aborted)
	}
}
