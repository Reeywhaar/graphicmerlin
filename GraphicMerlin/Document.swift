//
//  Document.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 25/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa

class Document: NSDocument {
	enum DocumentError: Error{
		case cantRevert
	}
	
	var documentData: ExportData = {
		let d = ExportData()
		if let prefs = try? Preferences.shared.getFormatPreset(forRawValue: d.currentTarget.format.rawValue){
			d.currentTarget.format = prefs
		}
		return d;
	}();
	lazy private var fileMTime: Date? = {
		if self.fileURL != nil {
			if let attrs = try? self.fileURL?.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey]) {
				return attrs?.contentModificationDate
			}
		}
		return nil
	}()
	
	private var docMTime: Date = Date.distantPast {
		didSet{
			self.invalidateRestorableState()
			self.windowControllers[0].setDocumentEdited(self._edited)
		}
	}
	
	private var _edited: Bool {
		get{
			if self.fileMTime == nil {
				return false
			}
			let a = self.docMTime
			let b = self.fileMTime!.addingTimeInterval(1)
			return a > b
		}
	}
	
	override class var autosavesInPlace: Bool {
		return false
	}
	
	override func makeWindowControllers() {
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
		(windowController.contentViewController as! ViewController).data = self.documentData
		self.documentData.changed.addListener(target: self, handler: Document.onDocumentChange)
		self.addWindowController(windowController)
	}
	
	override func responds(to aSelector: Selector!) -> Bool {
		if aSelector == #selector(revertToSaved(_:)) {
			return self._edited
		}
		if aSelector == #selector(save(_:)) {
			if self.fileMTime == nil {
				return true;
			}
			return self._edited
		}
		return super.responds(to: aSelector)
	}
	
	private func onDocumentChange(_ sender: Any?){
		self.docMTime = Date()
	}
	
	override func revert(toContentsOf url: URL, ofType typeName: String) throws {
		if let file = try String(contentsOf: url, encoding: String.Encoding.utf8).data(using: String.Encoding.utf8) {
			let data = try JSONDecoder().decode(ExportData.self, from: file)
			self.documentData.copyFrom(data)
			self.docMTime = self.fileMTime!
			return;
		} else {
			throw Document.DocumentError.cantRevert
		}
	}
	
	override func data(ofType typeName: String) throws -> Data {
		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let data = try encoder.encode(self.documentData)
			let date = Date()
			self.fileMTime = date
			self.docMTime = date
			return data
		} catch {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		do {
			let doc = try JSONDecoder().decode(ExportData.self, from: data)
			self.documentData.copyFrom(doc);
		} catch {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(self.docMTime, forKey: "documentMTime")
		if let json = try? JSONEncoder().encode(self.documentData) {
			coder.encode(json, forKey: "documentData")
		}
	}
	
	override func restoreState(with coder: NSCoder) {
		super.restoreState(with: coder)
		if let doc = coder.decodeObject(forKey: "documentData") as? Data {
			if let ed = try? JSONDecoder().decode(ExportData.self, from: doc) {
				self.documentData.copyFrom(ed)
			}
		}
		if let docMTime = coder.decodeObject(forKey: "documentMTime") as? Date {
			self.docMTime = docMTime
			self.windowControllers[0].setDocumentEdited(self._edited)
		}
	}
}


