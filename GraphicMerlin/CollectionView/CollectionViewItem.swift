//
//  CollectionViewItem.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa
import QuickLook

class CollectionViewItem: NSCollectionViewItem {
	private weak var observedWindow: NSWindow? = nil
	private var fileWatcherItem: FileWatcher.Item?
	private var _url: URL? {
		didSet {
			if self._url == oldValue || self._url == nil {
				return
			}
			if self.fileWatcherItem != nil {
				FileWatcher.shared.remove(self.fileWatcherItem!)
				self.fileWatcherItem = nil
			}
			if !FileManager.default.fileExists(atPath: self._url!.path) {
				return
			}
			self.fileWatcherItem = try? FileWatcher.Item(urls: [self._url!], handler: {
				(paths: [URL]) in
				if self._url != nil && paths.contains(self._url!){
					self.url = self._url
				}
			})
			if self.fileWatcherItem == nil {
				return
			}
			
			FileWatcher.shared.add(self.fileWatcherItem!)
		}
	}
	
	private var colors: (image: CGColor, label: CGColor) {
		var colors = (image: CGColor.clear, label: CGColor.clear)
		switch self.highlightState {
		case .forSelection:
			colors = (image: NSColor.controlHighlightColor.cgColor, label: NSColor.alternateSelectedControlColor.cgColor)
		case .forDeselection:
			break
		default:
			if self.view.window != nil && self.isSelected {
				colors = (
					image: NSColor.controlHighlightColor.cgColor,
					label: self.view.window!.isMainWindow
						? NSColor.alternateSelectedControlColor.cgColor
						: NSColor.controlHighlightColor.cgColor
				)
			}
		}
		return colors
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.backgroundColor = CGColor.clear
		self.view.layer?.cornerRadius = 4.0
		
		self.imageView?.wantsLayer = true
		self.textField?.wantsLayer = true
		self.imageView?.layer?.cornerRadius = 4.0
		self.textField?.layer?.cornerRadius = 3.0
		
		self.updateColors()
    }
	
	override func viewDidAppear() {
		if self.view.window != nil && self.view.window != self.observedWindow {
			NotificationCenter.default.addObserver(self, selector: #selector(windowFocusChanged(_:)), name: NSWindow.didBecomeMainNotification, object: self.view.window!)
			NotificationCenter.default.addObserver(self, selector: #selector(windowFocusChanged(_:)), name: NSWindow.didResignMainNotification, object: self.view.window!)
			self.observedWindow = self.view.window
		}
	}
	
	@IBAction func windowFocusChanged(_ sender: Any?){
		self.updateColors()
	}
	
	private func updateColors(){
		let colors = self.colors
		self.imageView?.animator().layer?.backgroundColor = colors.image
		self.textField?.animator().layer?.backgroundColor = colors.label;
		if let textColor = NSColor.init(cgColor: colors.label)?.usingColorSpace(NSColorSpace.deviceRGB) {
			self.textField?.textColor = textColor.brightnessComponent <= 0.87 && textColor.alphaComponent != 0.0 ? NSColor.white : NSColor.black
		}
	}
		
	override var isSelected: Bool {
		didSet{
			if self.isSelected != oldValue {
				self.updateColors()
			}
		}
	}
	
	override var highlightState: NSCollectionViewItem.HighlightState {
		didSet{
			if self.highlightState != oldValue {
				self.updateColors()
			}
		}
	}
	
	override var representedObject: Any? {
		get {
			return self._url;
		}
		set {
			self.url = representedObject as? URL;
		}
	}
	
	override func rightMouseDown(with event: NSEvent) {
		let view = self.collectionView as! CollectionViewController
		view.select(url: self._url!)
		let menu = NSMenu.init(title: "Menu");
		let items = [
			NSMenuItem(title: "Export Selected...", action: #selector(ViewController.exportSelected(_:)), keyEquivalent: ""),
			NSMenuItem(title: "Open Selected...", action: #selector(view.openSelected(_:)), keyEquivalent: ""),
			NSMenuItem(title: "Show in Finder", action: #selector(view.locateSelected(_:)), keyEquivalent: ""),
			NSMenuItem(title: "Delete", action: #selector(view.removeSelected(_:)), keyEquivalent: ""),
		]
		for item in items {
			menu.addItem(item)
		}
		menu.popUp(positioning: nil, at: event.locationInWindow, in: self.collectionView?.window?.contentView)
	}
	
	func imageForFile(_ url: URL) -> NSImage {
		let size = CGSize(width: 100.0, height: 100.0)
		let dict = [kQLThumbnailOptionIconModeKey: true]
		let ref = QLThumbnailImageCreate(
			kCFAllocatorDefault,
			url as CFURL,
			size,
			dict as CFDictionary
		)
		
		if ref == nil {
			return NSWorkspace.shared.icon(forFile: url.path)
		}
		
		let image = NSImage(cgImage: ref!.takeUnretainedValue(), size: size)
		ref?.release()
		return image;
	}
	
	var url: URL? {
		get {
			return self._url;
		}
		set(value) {
			if value == nil {
				return;
			}
			self._url = value;
			self.textField?.cell?.title = self._url!.lastPathComponent
			self.view.toolTip = self._url!.path
			self.imageView?.cell?.image = self.imageForFile(self._url!)
			
		}
	}
	
	deinit {
		if self.fileWatcherItem != nil {
			FileWatcher.shared.remove(self.fileWatcherItem!)
			self.fileWatcherItem = nil
		}
		if self.observedWindow != nil {
			NotificationCenter.default.removeObserver(self)
		}
	}
}
