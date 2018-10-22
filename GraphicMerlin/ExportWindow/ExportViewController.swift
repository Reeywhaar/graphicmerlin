//
//  ViewController.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa

class ExportViewController: NSViewController {
	enum Status {
		case Ok
		case Aborted
	}
	@IBOutlet weak var targetLabel: NSTextField!;
	@IBOutlet weak var destinationLabel: NSTextField!;
	@IBOutlet weak var sizeLabel: NSTextField!;
	@IBOutlet weak var progressLabel: NSTextField!;
	@IBOutlet weak var progressElement: NSProgressIndicator!;
	private let abort = Event<Any?>();
	let complete = Event<ExportViewController.Status>();
	let terminate = Event<Any?>();
	private var itemsDone: Int = 0 {
		didSet{
			self.updateView()
		}
	}
	
	private var itemIndex: Int {
		let count = self.data!.items.count;
		return self.itemsDone >= count ? count - 1 : self.itemsDone;
	}
	
	var percentReady: Double {
		return Double(self.itemsDone) / Double(self.data!.items.count) * 100.0
	}
	
	var target: URL {
		return self.data!.items[Int(self.itemIndex)]
	}
	
	var sizeText: String {
		if self.data == nil {
			return ""
		}
		switch self.data!.currentTarget.size {
		case (let width?, let height?):
			return "\(width)✕\(height)"
		case (let width?, nil):
			return "\(width)✕"
		case (nil, let height?):
			return "✕\(height)"
		default:
			return "unchanged"
		}
	}
	
	private func updateView(){
		if self.data == nil {
			return;
		}
		self.targetLabel.cell?.title = self.target.path
		self.destinationLabel.cell?.title = self.data?.getDestination(forItemAt: self.itemIndex)?.path ?? ""
		self.sizeLabel.cell?.title = self.sizeText
		self.progressElement.doubleValue = self.percentReady
		self.progressLabel.cell?.title = "\(self.itemsDone) of \(self.data!.items.count) \(Int(self.percentReady))%"
	}
	
	var data: ExportData? {
		didSet {
			self.updateView()
		}
	}
	
	private func processItem(withIndex index: Int, terminate: Event<Any?>){
		var src = self.data!.items[index]
		var dst = self.data!.getDestination(forItemAt: index)!
		if FileManager.default.fileExists(atPath: dst.path) {
			switch self.data!.currentTarget.existsStrategy {
			case .Pass:
				return
			case .OverwriteIfOlder:
				src.removeCachedResourceValue(forKey: URLResourceKey.contentModificationDateKey)
				dst.removeCachedResourceValue(forKey: URLResourceKey.contentModificationDateKey)
				
				let getMDate = {
					(url: URL) -> Date? in
					if let attrs = try? url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey]) {
						return attrs.contentModificationDate
					}
					return nil
				}
				
				let srcDate: Date? = getMDate(src)
				let dstDate: Date? = getMDate(dst)
				
				if srcDate != nil && dstDate != nil {
					if srcDate! < dstDate! {
						return
					}
				}
			case .Overwrite:
				break
			case .KeepBoth:
				let filename = dst.deletingPathExtension().lastPathComponent
				let ext = dst.pathExtension
				var counter = 1
				while FileManager.default.fileExists(atPath: dst.path) {
					counter += 1
					let newName = "\(filename)-\(counter).\(ext)"
					dst = dst.deletingLastPathComponent().appendingPathComponent(newName)
				}
			}
		}
		
		if let converter = ImageConverter(
			target: src,
			directory: self.data!.directory!,
			format: self.data!.currentTarget.format,
			size: self.data!.currentTarget.size,
			filename: dst.deletingPathExtension().lastPathComponent
		) {
			try? converter.convert(terminate)
		}
	}
	
	@IBAction func stop(_ sender: Any?){
		self.abort.emit(data: nil);
		usleep(500 * 1000)
		self.complete.emit(data: .Aborted)
		self.terminate.emit(data: nil)
	}
	
	func startExport() {
		let stopped = Boxed(false)
		self.abort.addListener(target: self, handler: {
			(i: ExportViewController) in
			return {
				(s: Any?) in
				stopped.value = true;
			}
		})
		
		DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
			[weak self] in
			if self == nil || stopped.value {
				return;
			}
			let count = self!.data!.items.count;
			for index in 0 ..< count {
				if self == nil || stopped.value {
					return;
				}
				self!.processItem(withIndex: index, terminate: self!.terminate)
				DispatchQueue.main.async {
					self!.itemsDone = index + 1;
				}
			}
			usleep(200 * 1000)
			DispatchQueue.main.async {
				if self == nil {
					return;
				}
				self?.complete.emit(data: .Ok)
			}
		}
	}
}

