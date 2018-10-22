//
//  Preferences.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 27/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

class Preferences: NSObject {
	enum PreferencesError: Error {
		case unknownFormat
		case cantEncodeFormat
	}
	
	var openDirectoryAfterExport: Bool {
		didSet {
			UserDefaults.standard.set(self.openDirectoryAfterExport, forKey: "openDirectoryAfterExport")
		}
	}
	
	private var formatsPresets: [String: ImageFormat] = [:]
	
	private static let _shared: Preferences? = nil;
	
	static var shared: Preferences {
		if Preferences._shared != nil {
			return Preferences._shared!
		}
		let prefs = Preferences()
		return prefs;
	}
	
	func getFormatPreset(forRawValue v: String) throws -> ImageFormat {
		if self.formatsPresets[v] != nil {
			return self.formatsPresets[v]!
		}
		
		if let i = UserDefaults.standard.object(forKey: "format:\(v)") as? Data {
			if let o = try? JSONDecoder().decode(ImageFormat.self, from: i) {
				self.formatsPresets[v] = o
				return o
			}
		}
		
		if let def = ImageFormat.from(rawValue: v) {
			return def
		}
	
		throw Preferences.PreferencesError.unknownFormat
	}
	
	func setFormatPreset(for v: ImageFormat) throws {
		if let encoded = try? JSONEncoder().encode(v) {
			UserDefaults.standard.set(encoded, forKey: "format:\(v.rawValue)")
			self.formatsPresets[v.rawValue] = v
			return;
		}
		
		throw Preferences.PreferencesError.cantEncodeFormat
	}
	
	override init(){
		self.openDirectoryAfterExport = UserDefaults.standard.bool(forKey: "openDirectoryAfterExport")
	}
}
