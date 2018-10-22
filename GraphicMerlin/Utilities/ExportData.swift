//
//  ExportData.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 24/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

enum ExistsStrategy: String, CaseIterable, ProvidesDefault {
	case Pass = "Pass"
	case OverwriteIfOlder = "Overwrite if older"
	case Overwrite = "Overwrite"
	case KeepBoth = "Keep Both"
	
	static var allCasesString: [String] {
		return ExistsStrategy.allCases.map({$0.rawValue})
	}
	
	static var def: ExistsStrategy {
		get {
			return ExistsStrategy.Overwrite
		}
	}
}

enum DirectoryLocation: Codable {
	case None
	case BindToFile
	case BindToFileInSubDirectory(String)
	case Custom(URL)
	
	private enum CodingKeys: String, CodingKey{
		case type
		case appendix
	}
	
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: DirectoryLocation.CodingKeys.self)
		let type = try c.decode(String.self, forKey: DirectoryLocation.CodingKeys.type)
		switch type {
		case "bindToFile":
			self = .BindToFile
			return
		case "bindToFileInSubdirectory":
			let subdir = try c.decode(String.self, forKey: DirectoryLocation.CodingKeys.appendix)
			self = .BindToFileInSubDirectory(subdir)
			return
		case "custom":
			let url = try c.decode(URL.self, forKey: DirectoryLocation.CodingKeys.appendix)
			self = .Custom(url)
			return
		default:
			self = .None
			return
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: DirectoryLocation.CodingKeys.self)
		switch self{
		case .None:
			try c.encode("none", forKey: DirectoryLocation.CodingKeys.type)
		case .BindToFile:
			try c.encode("bindToFile", forKey: DirectoryLocation.CodingKeys.type)
		case .BindToFileInSubDirectory(let subdir):
			try c.encode("bindToFileInSubdirectory", forKey: DirectoryLocation.CodingKeys.type)
			try c.encode(subdir, forKey: DirectoryLocation.CodingKeys.appendix)
		case .Custom(let url):
			try c.encode("custom", forKey: DirectoryLocation.CodingKeys.type)
			try c.encode(url, forKey: DirectoryLocation.CodingKeys.appendix)
		}
	}
}

class ExportTarget: NSObject, Codable{
	typealias Size = (UInt?, UInt?);
	
	enum Keys: String, CaseIterable, CodingKey {
		case format
		case size
		case renamePattern
		case existsStrategy
	}
	
	private var tracked: Bool = false
	
	let changed = Event<([ExportTarget.Keys], ExportTarget)>();
	
	var format: ImageFormat {
		didSet {
			if !tracked {
				return
			}
			if self.format == oldValue {
				return
			}
			self.changed.emit(data: ([.format], self))
		}
	}
	var size: ExportTarget.Size {
		didSet {
			if !tracked {
				return
			}
			if self.size.0 == oldValue.0 && self.size.1 == oldValue.1 {
				return
			}
			self.changed.emit(data: ([.size], self))
		}
	}
	var sizeString: String {
		switch self.size {
		case (let w?, nil):
			return "\(w)x"
		case (nil, let h?):
			return "x\(h)"
		case (let w?, let h?):
			return "\(w)x\(h)"
		default:
			return ""
		}
	}
	
	var renamePattern: String {
		didSet {
			if !tracked {
				return
			}
			if self.renamePattern == oldValue {
				return
			}
			self.changed.emit(data: ([.renamePattern], self))
		}
	}
	var existsStrategy: ExistsStrategy {
		didSet {
			if !tracked {
				return
			}
			if self.existsStrategy.rawValue == oldValue.rawValue {
				return
			}
			self.changed.emit(data: ([.existsStrategy], self))
		}
	}
	
	override init(){
		self.format = ImageFormat.def
		self.size = (nil, nil)
		self.renamePattern = ""
		self.existsStrategy = .def
		self.tracked = true
		super.init()
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: ExportTarget.Keys.self)
		try container.encode(self.format, forKey: .format)
		let size: [UInt?] = [self.size.0, self.size.1]
		try container.encode(size, forKey: .size)
		try container.encode(renamePattern, forKey: .renamePattern)
		try container.encode(existsStrategy.rawValue, forKey: .existsStrategy)
	}
	
	required init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: ExportTarget.Keys.self)
		
		if let format = try? c.decode(ImageFormat.self, forKey: .format) {
			self.format = format
		} else {
			self.format = ImageFormat.def
		}
		
		if let size: [UInt?] = try? c.decode([UInt?].self, forKey: .size) {
			self.size = (size[0], size[1])
		} else {
			self.size = (nil, nil)
		}
		
		if let rp = try? c.decode(String.self, forKey: .renamePattern)
		{
			self.renamePattern = rp
		} else {
			self.renamePattern = ""
		}
		
		if let es = try? c.decode(String.self, forKey: .existsStrategy) {
			if let ese = ExistsStrategy.init(rawValue: es) {
				self.existsStrategy = ese
			} else {
				self.existsStrategy = .def
			}
		} else {
			self.existsStrategy = .def
		}
		self.tracked = true
	}
	
	func clone() -> ExportTarget {
		let t = ExportTarget()
		t.tracked = false
		t.format = self.format
		t.size = self.size
		t.renamePattern = self.renamePattern
		t.existsStrategy = self.existsStrategy
		t.tracked = true
		return t
	}
}

class ExportData: NSObject, Codable{
	enum ExportDataError: Error {
		case directoryNotExists
		case directoryNotWritable
	}
	
	enum Keys: String, CaseIterable, CodingKey {
		case items
		case targets
		case targetIndex
		case directory
	}
	
	enum Substitutes: String, CaseIterable {
		case name
		case slugName = "slug-name"
		case titleName = "Title Name"
		case width
		case height
		case size
		case year
		case month
		case day
		case hour
		case minutes
		case seconds
		case date
		case time
		case datetime
		
		func substitute() -> String {
			return "$(\(self.rawValue))"
		}
	}
	
	let changed = Event<([ExportData.Keys], ExportData)>();
	private var tracked: Bool = false
	
	private func emit(_ keys: [ExportData.Keys]) {
		if tracked {
			self.changed.emit(data: (keys, self))
		}
	}
	
	private var _items: [URL] = []
	var items: [URL] {
		get {
			return self._items
		}
	}
	
	func add(item: URL){
		if self.items.contains(item) {
			return;
		}
		self._items.append(item);
		self.emit([.items])
	}
	
	func remove(item: URL){
		if !self.items.contains(item) {
			return;
		}
		let index = self.items.index(where: {$0 == item})
		self._items.remove(at: index!);
		self.emit([.items])
	}
	
	func replace(items: [URL]){
		self._items = items;
		self.emit([.items])
	}
	
	private var _targets: [ExportTarget] = []
	var targets: [ExportTarget] {
		return self._targets
	}
	
	func add(target: ExportTarget){
		if self._targets.contains(target) {
			return;
		}
		target.changed.addListener(target: self, handler: ExportData.onTargetChange)
		self._targets.append(target);
		self.emit([.targets])
	}
	
	private func onTargetChange(data: ([ExportTarget.Keys], ExportTarget)) {
		self.emit([.targets])
	}
	
	func remove(target: ExportTarget){
		if self._targets.count == 1 {
			return
		}
		if let index = self._targets.index(of: target) {
			self._targets.remove(at: index)
			self.changed.emit(data: ([.targets], self))
			if index == self._targets.count - 1 && index == self._targetIndex {
				self.targetIndex = self._targetIndex - 1;
				self.emit([.targets, .targetIndex])
			} else {
				self.emit([.targets])
			}
		}
	}
	
	func replace(targets: [ExportTarget]){
		if targets.count == 0 {
			return;
		}
		self._targets = targets;
		if self._targetIndex >= targets.count {
			self._targetIndex = targets.count - 1
			self.emit([.targets, .targetIndex])
		} else {
			self.emit([.targets])
		}
		for target in self._targets {
			target.changed.addListener(target: self, handler: ExportData.onTargetChange)
		}
	}
	
	private var _targetIndex: Int = 0
	var targetIndex: Int {
		get {
			return self._targetIndex
		}
		set {
			if newValue < 0 || newValue >= self._targets.count {
				return
			}
			if newValue == self._targetIndex {
				return
			}
			self._targetIndex = newValue
			self.emit([.targetIndex])
		}
	}
	
	var currentTarget: ExportTarget {
		get {
			return self.targets[self.targetIndex]
		}
	}
	
	private var _directory: URL? = nil {
		didSet {
			self.emit([.directory])
		}
	}
	var directory: URL? {
		get {
			return self._directory
		}
		set(dir) {
			if dir == self.directory {
				return
			}
			if dir == nil {return}
			let fm = FileManager.default
			if !fm.directoryExists(dir!) {
				self.directory = nil
				return
			}
			if !fm.isWritableFile(atPath: dir!.path) {
				self.directory = nil
				return
			}
			self._directory = dir;
		}
	}
	
	override init(){
		super.init()
		self.add(target: ExportTarget())
		self.tracked = true
	}
	
	init(
		items: [URL],
		targets: [ExportTarget],
		directory: URL
	) {
		super.init()
		self.replace(items: items)
		self.replace(targets: targets)
		self.tracked = true
	}
	
	func getDestinationFilename(forItemAt index: Int) -> String?{
		if !(index < self.items.count) {
			return nil
		}
		let item = self.items[index]
		if self.directory == nil {
			return nil
		}
		let date = Date()
		let filename = item.deletingPathExtension().lastPathComponent
		let pattern: String = { () -> String in
			var pattern = (self.currentTarget.renamePattern == "" ? "$(name)" : self.currentTarget.renamePattern)
				.replacingOccurrences(of: "$(name)", with: filename)
				.replacingOccurrences(of: "$(width)", with: self.currentTarget.size.0 == nil ? "" : String(self.currentTarget.size.0!))
				.replacingOccurrences(of: "$(height)", with: self.currentTarget.size.1 == nil ? "" : String(self.currentTarget.size.1!))
				.replacingOccurrences(of: "$(size)", with: self.currentTarget.sizeString)
			if pattern.contains("$(slug-name)") {
				pattern = pattern.replacingOccurrences(of: "$(slug-name)", with: filename.slugCased())
			}
			if pattern.contains("$(Title Name)") {
				pattern = pattern.replacingOccurrences(of: "$(Title Name)", with: filename.titleCased())
			}
			let dateFormats: [String:String] = [
				"$(year)": "yyyy",
				"$(month)": "mm",
				"$(day)": "dd",
				"$(hour)": "HH",
				"$(minutes)": "mm",
				"$(seconds)": "ss",
				"$(date)": "yyyy-mm-dd",
				"$(time)": "HH:mm",
				"$(datetime)": "yyyy-mm-dd-HH:mm",
			]
			for (dpattern, replacement) in dateFormats {
				if pattern.contains(dpattern) {
					let f = DateFormatter()
					f.dateFormat = replacement
					pattern = pattern.replacingOccurrences(of: dpattern, with: f.string(from: date))
				}
			}
			return pattern
		}()
		return pattern;
	}
	
	func getDestination(forItemAt index: Int) -> URL?{
		let filename = self.getDestinationFilename(forItemAt: index)
		if filename == nil {
			return nil
		}
		return self.directory!.appendingPathComponent(self.getDestinationFilename(forItemAt: index)!).deletingPathExtension().appendingPathExtension(self.currentTarget.format.ext)
	}
	
	func copyFrom(_ target: ExportData){
		if target == self {
			return
		}
		self.tracked = false
		self.replace(items: target._items)
		self.replace(targets: target._targets)
		self._targetIndex = target._targetIndex
		self._directory = target._directory;
		self.tracked = true
		self.emit([.items, .targets, .targetIndex, .items])
	}
	
	static func ==(lhs: ExportData, rhs: ExportData) -> Bool {
		if	lhs._items == rhs._items
		&& lhs._targets == rhs._targets
		&& lhs._targetIndex == rhs._targetIndex
		&& lhs._directory == rhs._directory {
			return true
		}
		return false
	}
	
	// Mark: Codable
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: ExportData.Keys.self)
		try container.encode(self.items, forKey: .items)
		try container.encodeIfPresent(self.directory, forKey: .directory)
		try container.encode(self._targets, forKey: .targets)
		try container.encode(self._targetIndex, forKey: .targetIndex)
	}
	
	required init(from decoder: Decoder) throws {
		super.init()
		let data = try decoder.container(keyedBy: ExportData.Keys.self)
		if let items = try? data.decode([URL].self, forKey: .items) {
			self.replace(items: items)
		} else {
			self.replace(items: [])
		}
		if let directory = try? data.decode(URL.self, forKey: .directory) {
			self._directory = directory
		} else {
			self._directory = nil
		}
		if let targets = try? data.decode([ExportTarget].self, forKey: .targets) {
			self.replace(targets: targets)
		} else {
			self.replace(targets: [ExportTarget()])
		}
		if let targetIndex = try? data.decode(Int.self, forKey: .targetIndex) {
			self._targetIndex = targetIndex
		} else {
			self._targetIndex = 0
		}
		self.tracked = true
	}
}

extension ExportData {
	override var debugDescription: String {
		return """
			Point(
				items: \(self._items),
				targets: \(String(describing: self._targets)),
				targetIndex: \(String(describing: self._targetIndex)),
				directory: \(String(describing: self._directory)),
			)
		"""
	}
}
