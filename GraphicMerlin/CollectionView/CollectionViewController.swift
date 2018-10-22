//
//  CollectionViewDelegate.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa
import Quartz

class CollectionViewController: NSCollectionView {
	let changed = Event<[URL]>()
	static let pasteboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType");
	var extensions = [
		"jpg",
		"jpeg",
		"png",
		"gif",
		"tiff",
		"tif",
		"psd",
	]
	let colors = [
		NSColor.white.cgColor,
		NSColor.selectedControlColor.cgColor
	]
	
	private func initShared(){
		self.wantsLayer = true
		self.layer?.backgroundColor = self.colors[0]
	
		let cItem = NSNib(nibNamed: "CollectionViewItem", bundle: nil);
		self.register(cItem, forItemWithIdentifier: NSUserInterfaceItemIdentifier("CollectionViewItem"))
	
		self.registerForDraggedTypes([
			CollectionViewController.pasteboardType
		])
		self.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true);
		self.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false);
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.initShared()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder);
		self.initShared()
	}
	
	func select(url: URL){
		if let index = (self.dataSource as! CollectionViewDataSource).data.items.index(where: {$0 == url}) {
			let ip = IndexPath(item: index, section: 0)
			if self.selectionIndexPaths.contains(ip) {
				return
			}
			self.deselectAll(self)
			self.selectItems(at: [ip], scrollPosition: [])
		}
	}
			
	func remove(_ url: URL){
		let dataSource = (self.dataSource as! CollectionViewDataSource);
		if dataSource.data.items.contains(url) {
			dataSource.data.remove(item: url)
		}
	}
	
	func getDropURLs(_ sender: NSDraggingInfo) -> [URL] {
		let items = sender.draggingPasteboard.propertyList(forType: CollectionViewController.pasteboardType) as? NSArray ?? nil;
		if items == nil {
			return [];
		}
		return items!.map({
			(item: Any) -> URL? in
			let str = item as? String
			if str == nil {
				return nil
			}
			return URL(fileURLWithPath: str!)
		}).filter({$0 != nil}).map({$0!})
	}
	
	func checkExtension(_ file: URL) -> Bool {
		return self.extensions.contains(file.pathExtension.lowercased())
	}
	
	func checkExtension(_ sender: NSDraggingInfo) -> Bool {
		let items = self.getDropURLs(sender)
		return items.contains(where: {self.checkExtension($0)})
	}

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if self.checkExtension(sender) {
			self.layer?.backgroundColor = self.colors[1]
			return NSDragOperation.copy
		}
		
		return NSDragOperation()
	}

	override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
		return self.draggingEntered(sender)
	}

	override func draggingExited(_ sender: NSDraggingInfo?) {
		self.layer?.backgroundColor = self.colors[0]
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		let files = self.getDropURLs(sender).filter({checkExtension($0)})
		let dataSource = (self.dataSource as! CollectionViewDataSource)
		for file in files {
			dataSource.data.add(item: file)
		}
		self.layer?.backgroundColor = self.colors[0]
		return true
	}
	
	override func responds(to aSelector: Selector!) -> Bool {
		switch aSelector {
		case #selector(quickLookPreviewItems(_:)):
			return self.selectionIndexes.count > 0
		case #selector(selectAll(_:)):
			return self.selectionIndexes.count < self.numberOfItems(inSection: 0)
		case #selector(deselectAll(_:)):
			return self.selectionIndexes.count > 0
		case #selector(locateSelected(_:)), #selector(openSelected(_:)):
			let dataSource = self.dataSource as! CollectionViewDataSource
			let items = self.selectionIndexes
				.map({dataSource.data.items[$0]})
				.filter({
					FileManager.default.fileExists(atPath: $0.path)
				})
			return self.selectionIndexes.count > 0 && items.count > 0
		case #selector(removeSelected(_:)):
			return self.selectionIndexes.count > 0
		default:
			return super.responds(to: aSelector);
		}
	}
	
	@IBAction func locateSelected(_ sender: Any?){
		let dataSource = self.dataSource as! CollectionViewDataSource
		let urls = self.selectionIndexes.map({
			dataSource.data.items[$0]
		}).filter({
			FileManager.default.fileExists(atPath: $0.path)
		})
		NSWorkspace.shared.activateFileViewerSelecting(urls)
	}
	
	@IBAction func openSelected(_ sender: Any?){
		let dataSource = self.dataSource as! CollectionViewDataSource
		let urls = self.selectionIndexes.map({
			dataSource.data.items[$0]
		}).filter({
			FileManager.default.fileExists(atPath: $0.path)
		})
		for url in urls {
			DispatchQueue.global(qos: .background).async {
				NSWorkspace.shared.open(url)
			}
		}
	}
	
	@IBAction func removeSelected(_ sender: Any?){
		let dataSource = (self.dataSource as! CollectionViewDataSource);
		if self.selectionIndexes.count > 0 {
			dataSource.data.replace(
				items: dataSource.data.items.enumerated().filter({
					return !self.selectionIndexes.contains($0.offset)
				}).map({$0.element})
			)
			return;
		}
	}
	
	@IBAction func paste(_ sender: Any?){
		let items = NSPasteboard.general.propertyList(forType: CollectionViewController.pasteboardType) as? NSArray ?? nil
		if items == nil {
			return
		}
		let urls = items!.map({
			(item: Any) -> URL? in
			let str = item as? String
			if str == nil {
				return nil
			}
			return URL(fileURLWithPath: str!)
		}).filter({$0 != nil}).map({$0!})
		let dataSource = (self.dataSource as! CollectionViewDataSource)
		for url in urls {
			dataSource.data.add(item: url)
		}
	}
	
	override func keyDown(with event: NSEvent) {
		if event.characters == " " {
			if self.responds(to: #selector(quickLookPreviewItems(_:))) {
				self.quickLookPreviewItems(self)
			} else {
				self.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: [])
			}
		} else {
			super.keyDown(with: event)
		}
	}
}

extension CollectionViewController: QLPreviewPanelDataSource, QLPreviewPanelDelegate{
	override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.nextResponder = self
		panel.delegate = self
		panel.dataSource = self
	}
	
	override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.nextResponder = nil
		panel.delegate = nil
		panel.dataSource = nil
	}
	
	func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
		return self.selectionIndexes.count
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		let item = self.selectionIndexes.map({
			(self.dataSource as! CollectionViewDataSource).data.items[$0]
		})[index]
		return item as QLPreviewItem
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
		if QLPreviewPanel.sharedPreviewPanelExists() && event.type == NSEvent.EventType.keyDown {
			panel?.reloadData()
		}
		return false
	}
	
	func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: QLPreviewItem!) -> NSRect {
		let item = self.item(at: self.selectionIndexes.first!) as! CollectionViewItem
		let image = item.imageView!
		let winLoc = image.convert(image.visibleRect, to: nil)
		return self.window?.convertToScreen(winLoc) ?? NSRect(x: 0, y: 0, width: 10, height: 10)
	}
	
	@IBAction override func quickLookPreviewItems(_ sender: Any?) {
		let panel = QLPreviewPanel.shared()
		panel?.makeKey()
		panel?.orderFront(self)
	}
}
