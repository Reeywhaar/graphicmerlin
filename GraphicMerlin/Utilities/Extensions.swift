//
//  FIleManager.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 28/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

extension FileManager {
	func directoryExists(_ path: URL) -> Bool {
		var dirBool = ObjCBool.init(false)
		let exists = self.fileExists(atPath: path.path, isDirectory: &dirBool)
		if exists && dirBool.boolValue {
			return true
		}
		return false
	}
}

extension String {
	func slugCased() -> String{
		return self
			.replacingOccurrences(of: " ", with: "-")
			.replacingOccurrences(of: "_", with: "-")
			.lowercased()
	}
	
	func titleCased() -> String{
		return self
			.replacingOccurrences(of: "_", with: " ")
			.split(separator: " ")
			.map({
				return $0.prefix(1).uppercased() + $0.dropFirst()
			})
			.joined(separator: " ")
	}
}

#if !swift(>=4.2)
	public protocol CaseIterable {
		associatedtype AllCases: Collection where AllCases.Element == Self
		static var allCases: AllCases { get }
	}
	extension CaseIterable where Self: Hashable {
		static var allCases: [Self] {
			return [Self](AnySequence({
				() -> AnyIterator<Self> in
				var raw = 0
				return AnyIterator({
					let current = withUnsafeBytes(of: &raw) { $0.load(as: Self.self) }
					guard current.hashValue == raw else {
						return nil
					}
					raw += 1
					return current
				})
			}))
		}
	}
#endif

protocol ProvidesDefault {
	static var def: Self {get}
}


