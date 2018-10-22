//
//  DirectoryWatcher.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 31/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

class DirectoryWatcher {
	enum DirectoryWatcherError: Error {
		case givenDirectoryIsNotDirectory
		case cantCreateStream
	}
	typealias OnChangeHandler = ([URL]) -> Void
	private let onChange: OnChangeHandler
	private var stream: FSEventStreamRef?
	init(directories: [URL], onChange: @escaping OnChangeHandler) throws {
		if directories.first(where: {
			var isDir = ObjCBool.init(false)
			let e = FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDir)
			if e || !isDir.boolValue {
				return false
			}
			return true
		}) != nil {
			throw DirectoryWatcher.DirectoryWatcherError.givenDirectoryIsNotDirectory
		}
		self.onChange = onChange
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
				let s: DirectoryWatcher = unsafeBitCast(contextInfo, to: DirectoryWatcher.self)
				guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
				s.onChange(
					paths.map({URL(fileURLWithPath: $0)})
				)
			},
			&context,
			directories.map({$0.path}) as CFArray,
			FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
			CFTimeInterval(5.0),
			UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
		)
		if self.stream != nil {
			FSEventStreamScheduleWithRunLoop(self.stream!, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
			FSEventStreamStart(self.stream!)
		} else {
			throw DirectoryWatcher.DirectoryWatcherError.cantCreateStream
		}
	}
	
	convenience init(directory: URL, onChange: @escaping OnChangeHandler) throws {
		try self.init(directories: [directory], onChange: onChange)
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
