//
//  PresetTebView.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 06/06/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class PresetTabView: NSTabView {
	weak var data: ExportData?
	private var controllers: [PresetViewController] = []
	private lazy var storyboard = {
		return NSStoryboard.init(name: "Main", bundle: nil)
	}()
	private var loaded = false
	
	private func addTabViewItem(for item: ExportTarget){
		let cnt = self.storyboard.instantiateController(withIdentifier: "PresetController") as! PresetViewController
		item.changed.addListener(target: self, handler: PresetTabView.onTargetChange)
		cnt.target = item
		cnt.loadView()
		let tabViewItem = NSTabViewItem()
		tabViewItem.label = "\(item.format.ext) \(item.sizeString)"
		self.addTabViewItem(tabViewItem)
		let tviv = tabViewItem.view!
		tviv.addSubview(cnt.view)
		cnt.view.translatesAutoresizingMaskIntoConstraints = false
		tviv.addConstraints([
			NSLayoutConstraint(item: cnt.view, attribute: .centerX, relatedBy: .equal, toItem: tviv, attribute: .centerX, multiplier: 1.0, constant: 0.0),
			NSLayoutConstraint(item: cnt.view, attribute: .width, relatedBy: .equal, toItem: tviv, attribute: .width, multiplier: 1.0, constant: 4.0),
			NSLayoutConstraint(item: cnt.view, attribute: .top, relatedBy: .equal, toItem: tviv, attribute: .top, multiplier: 1.0, constant: 0.0),
			NSLayoutConstraint(item: tviv, attribute: .bottom, relatedBy: .equal, toItem: cnt.view, attribute: .bottom, multiplier: 1.0, constant: 0.0),
		])
		self.controllers.append(cnt)
	}
	
	private func replaceTabViewItem(at index: Int, with item: ExportTarget){
		if index >= self.controllers.count {
			return
		}
		if self.controllers[index].target == item {
			return
		}
		let cnt = self.storyboard.instantiateController(withIdentifier: "PresetController") as! PresetViewController
		item.changed.addListener(target: self, handler: PresetTabView.onTargetChange)
		cnt.target = item
		cnt.loadView()
		let tabViewItem = self.tabViewItems[index]
		tabViewItem.label = "\(item.format.ext) \(item.sizeString)"
		let tviv = tabViewItem.view!
		tviv.subviews.removeAll()
		tviv.addSubview(cnt.view)
		cnt.view.translatesAutoresizingMaskIntoConstraints = false
		tviv.addConstraints([
			NSLayoutConstraint(item: cnt.view, attribute: .leading, relatedBy: .equal, toItem: tviv, attribute: .leading, multiplier: 1.0, constant: 0.0),
			NSLayoutConstraint(item: cnt.view, attribute: .trailing, relatedBy: .equal, toItem: tviv, attribute: .trailing, multiplier: 1.0, constant: 0.0),
			NSLayoutConstraint(item: cnt.view, attribute: .top, relatedBy: .equal, toItem: tviv, attribute: .top, multiplier: 1.0, constant: 0.0),
			NSLayoutConstraint(item: tviv, attribute: .bottom, relatedBy: .equal, toItem: cnt.view, attribute: .bottom, multiplier: 1.0, constant: 0.0),
		])
		self.controllers[index] = cnt
	}
	
	private func removeTabViewItem(at n: Int){
		if n >= self.tabViewItems.count {
			return
		}
		self.removeTabViewItem(self.tabViewItems[n])
		if n < self.controllers.count {
			self.controllers.remove(at: n)
		}
	}
	
	private func onTargetChange(_ data: ([ExportTarget.Keys], ExportTarget)) {
		if let index = self.controllers.index(where: {$0.target === data.1}) {
			let tv = self.tabViewItem(at: index)
			tv.label = "\(data.1.format.ext) \(data.1.sizeString)"
		}
	}
	
	private func onDataChange(_ data: ([ExportData.Keys], ExportData)) {
		if data.0.contains(.targets) {
			self.relayout()
		}
		if data.0.contains(.targetIndex) {
			self.selectTabViewItem(at: self.data!.targetIndex)
		}
	}
	
	private func relayout(){
		while (self.tabViewItems.count > self.data!.targets.count){
			self.removeTabViewItem(at: self.tabViewItems.count - 1)
		}
		for (index, target) in self.data!.targets.enumerated() {
			if index < self.tabViewItems.count {
				self.replaceTabViewItem(at: index, with: target)
			} else {
				self.addTabViewItem(for: target)
			}
		}
	}
	
	func load(with data: ExportData){
		self.loaded = false
		for item in self.tabViewItems {
			self.removeTabViewItem(item)
		}
		self.data = data
		self.data!.changed.addListener(target: self, handler: PresetTabView.onDataChange)
		self.onDataChange((ExportData.Keys.allCases, self.data!))
		self.loaded = true
	}
	
	override func selectTabViewItem(_ tabViewItem: NSTabViewItem?) {
		super.selectTabViewItem(tabViewItem)
		if tabViewItem != nil && self.loaded {
			self.data?.targetIndex = self.tabViewItems.index(of: tabViewItem!) ?? 0
		}
	}
	
	override func selectTabViewItem(at index: Int) {
		super.selectTabViewItem(at: index)
		if self.loaded {
			self.data?.targetIndex = index
		}
	}
}
