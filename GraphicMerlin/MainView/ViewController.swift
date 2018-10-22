//
//  ViewController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa
import Quartz

class ViewController: NSViewController {
	@IBOutlet weak var collectionView: CollectionViewController!
	@IBOutlet weak var addItemsLabel: NSTextField!
	@IBOutlet weak var tabView: PresetTabView!
	@IBOutlet weak var exportButton: NSButton!
	@IBOutlet weak var directoryLabel: NSTextField!
	@IBOutlet weak var presetAddRemoveButtons: NSSegmentedControl!
	lazy var collectionViewDataSource: CollectionViewDataSource = {
		return CollectionViewDataSource(self.data)
	}()
	var data: ExportData = ExportData()
	var exportWindow: ExportWindowController? {
		didSet {
			self.updateExportState()
		}
	}
	var inProgress: Bool {
		return self.exportWindow != nil
	}
	
	private var disposables: [Disposable] = []
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		self.disposables.append(
			self.data.changed.addListener(target: self, handler: ViewController.onDataChange)
		)
		
		self.collectionView.dataSource = self.collectionViewDataSource
		
		self.tabView.load(with: self.data)
		
		let gesture = NSClickGestureRecognizer()
		gesture.buttonMask = 0b01
		gesture.numberOfClicksRequired = 1
		gesture.target = self
		gesture.action = #selector(selectDirectory(_:))
		self.directoryLabel.addGestureRecognizer(gesture)
		
		let rightClickGesture = NSClickGestureRecognizer()
		rightClickGesture.buttonMask = 0b10
		rightClickGesture.numberOfClicksRequired = 1
		rightClickGesture.target = self
		rightClickGesture.action = #selector(showDirectoryMenu(_:))
		self.directoryLabel.addGestureRecognizer(rightClickGesture)
		
		let area = NSTrackingArea(rect: self.directoryLabel.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: ["target":self.directoryLabel])
		self.directoryLabel.addTrackingArea(area)
		self.directoryLabel.layer?.cornerRadius = 4.0
		
		self.onDataChange((ExportData.Keys.allCases, self.data))
	}
	
	override func mouseEntered(with event: NSEvent) {
		if let dict = event.trackingArea?.userInfo as? [String:Any?] {
			if let target = dict["target"] as? NSTextField {
				if target == self.directoryLabel {
					self.directoryLabel.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor
				}
			}
		}
	}
	
	override func mouseExited(with event: NSEvent) {
		if let dict = event.trackingArea?.userInfo as? [String:Any?] {
			if let target = dict["target"] as? NSTextField {
				if target == self.directoryLabel {
					self.directoryLabel.layer?.backgroundColor = NSColor.clear.cgColor
				}
			}
		}
	}
	
	func updateExportState(){
		let predicate = self.data.items.count > 0 && self.data.directory != nil && !self.inProgress
		if self.exportButton.isEnabled != predicate {
			self.exportButton.animator().isEnabled = predicate
		}
	}
	
	@IBAction func showDirectoryMenu(_ sender: Any?) {
		guard let gest = sender as? NSClickGestureRecognizer else {
			return;
		}
		let menu = NSMenu.init(title: "Menu");
		
		let selectItem = NSMenuItem(title: "Select Directory...", action: #selector(self.selectDirectory(_:)), keyEquivalent: "");
		menu.addItem(selectItem);
		
		let showItem = NSMenuItem(title: "Open in Finder", action: #selector(self.openDirectory(_:)), keyEquivalent: "");
		menu.addItem(showItem);
		
		menu.popUp(positioning: nil, at: gest.location(in: self.view), in: self.view)
	}
	
	func onDataChange(_ data: ([ExportData.Keys], ExportData)){
		if (data.0.contains(.items)) {
			self.addItemsLabel.animator().isHidden = data.1.items.count > 0
			self.collectionView.reloadData()
		}
		if (data.0.contains(.directory)) {
			if let dir = data.1.directory {
				self.directoryLabel.stringValue = dir.path;
				self.directoryLabel.toolTip = dir.path;
			} else {
				self.directoryLabel.stringValue = "";
				self.directoryLabel.toolTip = nil;
			}
		}
		
		{
			let predicate = self.data.items.count > 0 && self.data.directory != nil && !self.inProgress
			if self.exportButton.isEnabled != predicate {
				self.exportButton.animator().isEnabled = predicate
			}
		}()
		
		if (data.0.contains(.targets)) {
			self.presetAddRemoveButtons.setEnabled(self.data.targets.count > 1, forSegment: 1)
		}
	}
		
	override func responds(to aSelector: Selector!) -> Bool {
		switch aSelector {
		case #selector(selectDirectory(_:)):
			return true
		case #selector(openDirectory(_:)):
			return self.data.directory != nil
		case #selector(delete(_:)):
			return self.collectionView.selectionIndexes.count > 0
		case #selector(export(_:)):
			return self.exportButton.isEnabled
		case #selector(exportSelected(_:)):
			return self.collectionView.selectionIndexes.count > 0
		default:
			return super.responds(to: aSelector);
		}
	}
	
	@IBAction func delete(_ sender: Any?) {
		self.collectionView.removeSelected(self)
	}
	
	@IBAction func onSegmentClicked(_ sender: Any?) {
		if let cnt = sender as? NSSegmentedControl {
			let action = cnt.selectedSegment == 0 ? self.addPreset : self.removePreset
			action(self)
		}
	}
	
	@IBAction func addPreset(_ sender: Any?) {
		self.data.add(target: self.data.currentTarget.clone())
		self.tabView.selectLastTabViewItem(self)
	}
	
	@IBAction func removePreset(_ sender: Any?) {
		if self.data.targets.count < 2 {
			return
		}
		self.data.remove(target: self.data.targets[self.data.targetIndex])
	}
	
	@IBAction func openDirectory(_ sender: Any?){
		if self.data.directory == nil {
			return;
		}
		NSWorkspace.shared.openFile(self.data.directory!.path)
	}
	
	@IBAction func selectDirectory(_ sender: AnyObject) {
		let dialog = NSOpenPanel()
		dialog.title = "Choose Directory"
		dialog.showsResizeIndicator = true
		dialog.showsHiddenFiles = false
		dialog.canChooseDirectories = true
		dialog.canCreateDirectories = true
		dialog.allowsMultipleSelection = false
		dialog.canChooseFiles = false
		
		if (dialog.runModal() != NSApplication.ModalResponse.OK) {
			return
		}
		
		let result = dialog.url
		
		if result != nil {
			self.data.directory = result!
		}
	}
	
	fileprivate func onExportComplete(_ s: ExportViewController.Status){
		let con = self.exportWindow?.contentViewController
		if con != nil {
			self.dismiss(con!)
		}
		if Preferences.shared.openDirectoryAfterExport {
			self.openDirectory(nil)
		}
		self.exportWindow = nil;
	}
	
	private func export(data: ExportData){
		if self.exportWindow != nil {
			return
		}
		
		let showAlert = {
			(header: String, text: String) -> NSApplication.ModalResponse in
			let alert: NSAlert = NSAlert()
			alert.messageText = "Cannot Export"
			alert.informativeText = "Destination directory doesn't exists"
			alert.alertStyle = NSAlert.Style.critical
			alert.addButton(withTitle: "Ok")
			return alert.runModal()
		}
		
		let fm = FileManager.default
		if !fm.directoryExists(data.directory!){
			let _ = showAlert("Cannot Export", "Destination directory doesn't exists")
			return
		}
		
		if !fm.isWritableFile(atPath: data.directory!.path){
			let _ = showAlert("Cannot Export", "Destination directory is not writable")
			return
		}
		
		self.exportWindow = ExportWindowController()
		self.exportWindow!.loadWindow()
		(self.exportWindow!.contentViewController as! ExportViewController).complete.addListener(target: self, handler: ViewController.onExportComplete)
		self.presentAsSheet(self.exportWindow!.contentViewController!)
		let controller = self.exportWindow?.contentViewController as! ExportViewController
		controller.data = data
		controller.startExport()
	}
	
	@IBAction func exportSelected(_ sender: AnyObject){
		let data = ExportData()
		data.copyFrom(self.data)
		data.replace(items: self.collectionView.selectionIndexes.map({self.data.items[$0]}))
		self.export(data: data)
	}
	
	@IBAction func export(_ sender: AnyObject) {
		self.export(data: self.data)
	}
}

