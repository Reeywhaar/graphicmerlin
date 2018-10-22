//
//  FileWatcher.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 31/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

class FileWatcher {
	enum Error: Swift.Error {
		case wrongURL
		case cantCreateStream
	}
	
	class Item {
		let handler: ([URL]) -> Void
		let urls: [URL]
		
		init(urls: [URL], handler: @escaping ([URL]) -> Void) throws{
			for url in urls {
				if !FileManager.default.fileExists(atPath: url.path){
					throw FileWatcher.Error.wrongURL
				}
			}
			self.urls = urls
			self.handler = handler
		}
	}

	private static var instance: FileWatcher?
	private var items: [FileWatcher.Item] = []
	private var stream: FSEventStreamRef?
	static var shared: FileWatcher {
		get {
			if FileWatcher.instance == nil {
				FileWatcher.instance = FileWatcher.init()
			}
			return FileWatcher.instance!
		}
	}
	
	private init(){

	}
	
	private func reset() throws {
		if self.stream != nil {
			FSEventStreamStop(self.stream!)
			FSEventStreamInvalidate(self.stream!)
			FSEventStreamRelease(self.stream!)
			self.stream = nil
		}
		var directories: [URL] = [];
		for item in self.items
			.map({$0.urls})
			.joined()
			.map({$0.deletingLastPathComponent()})
		{
			if !directories.contains(item){
				directories.append(item)
			}
		}
		var context = FSEventStreamContext.init(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
		self.stream = FSEventStreamCreate(
			kCFAllocatorDefault,
			{
				(
				streamRef: ConstFSEventStreamRef,
				contextInfo: UnsafeMutableRawPointer?,
				numEvents: Int,
				eventPaths: UnsafeMutableRawPointer,
				eventFlags: UnsafePointer<FSEventStreamEventFlags>,
				eventIds: UnsafePointer<FSEventStreamEventId>
				) in
				let s: FileWatcher = unsafeBitCast(contextInfo, to: FileWatcher.self)
				guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
				let urls = paths.map({URL(fileURLWithPath: $0)})
				for item in s.items{
					var intersection: [URL] = []
					for url in urls {
						if item.urls.contains(url) {
							intersection.append(url)
						}
					}
					if intersection.count > 0 {
						item.handler(intersection)
					}
				}
		},
			&context,
			directories.map({$0.path}) as CFArray,
			FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
			CFTimeInterval(3.0),
			UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
		)
		if self.stream != nil {
			FSEventStreamScheduleWithRunLoop(self.stream!, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
			FSEventStreamStart(self.stream!)
		} else {
			throw DirectoryWatcher.DirectoryWatcherError.cantCreateStream
		}
	}

	func add(_ item: FileWatcher.Item){
		if !self.items.contains(where: {$0 === item}) {
			self.items.append(item)
		}
		do {
			try self.reset()
		} catch {
			self.remove(item)
		}
	}

	func remove(_ item: FileWatcher.Item){
		let index = self.items.index(where: {$0 === item})
		if index != nil {
			self.items.remove(at: index!)
		}
		try! self.reset()
	}
	
	deinit {
		if self.stream != nil {
			FSEventStreamStop(self.stream!)
			FSEventStreamInvalidate(self.stream!)
			FSEventStreamRelease(self.stream!)
			self.stream = nil
		}
	}
}

