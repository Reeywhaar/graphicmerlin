//
//  ImageFormat.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 26/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

protocol ImageFormatProtocol: Codable, Equatable {}

struct JPEGFormat: ImageFormatProtocol{
	var quality: UInt8 = 75
	
	fileprivate enum CodingKeys: String, CodingKey{
		case quality
	}
	
	init(){}
	
	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: JPEGFormat.CodingKeys.self)
		try c.encode(self.quality, forKey: .quality)
	}
	
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: JPEGFormat.CodingKeys.self)
		self.quality = try c.decode(UInt8.self, forKey: JPEGFormat.CodingKeys.quality)
	}
	
	static func ==(lhs: JPEGFormat, rhs: JPEGFormat) -> Bool {
		if lhs.quality == rhs.quality {
			return true
		}
		
		return false
	}
}

enum TiffCompression: String {
	case None
	case ZIP
	case LZW
	
	static var def: TiffCompression {
		return .ZIP
	}
	
	static func list() -> [String] {
		return ["None", "ZIP", "LZW"]
	}
}

struct TiffFormat: ImageFormatProtocol{
	var compression: TiffCompression = TiffCompression.def
	var preserveTransparency: Bool = true
	fileprivate enum CodingKeys: String, CodingKey{
		case compression
		case preserveTransparency
	}
	
	init(){}
	
	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: TiffFormat.CodingKeys.self)
		try c.encode(self.preserveTransparency, forKey: .preserveTransparency)
		try c.encode(self.compression.rawValue, forKey: .compression)
	}
	
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: TiffFormat.CodingKeys.self)
		self.compression = TiffCompression.init(rawValue: try c.decode(String.self, forKey: TiffFormat.CodingKeys.compression)) ?? TiffCompression.def
		self.preserveTransparency = try c.decode(Bool.self, forKey: TiffFormat.CodingKeys.preserveTransparency)
	}
	
	static func ==(lhs: TiffFormat, rhs: TiffFormat) -> Bool {
		if lhs.compression.rawValue == rhs.compression.rawValue && lhs.preserveTransparency == rhs.preserveTransparency {
			return true
		}
		
		return false
	}
}

struct PNGFormat: ImageFormatProtocol{
	var preserveTransparency: Bool = true
	var optimize: Bool = true
	var mode: UInt8 = 24
	fileprivate enum CodingKeys: String, CodingKey{
		case preserveTransparency
		case mode
		case optimize
	}
	
	init(){}
	
	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: PNGFormat.CodingKeys.self)
		try c.encode(self.preserveTransparency, forKey: .preserveTransparency)
		try c.encode(self.mode, forKey: .mode)
		try c.encode(self.optimize, forKey: .optimize)
	}
	
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: PNGFormat.CodingKeys.self)
		self.preserveTransparency = try c.decode(Bool.self, forKey: .preserveTransparency)
		self.mode = try c.decode(UInt8.self, forKey: .mode)
		self.optimize = try c.decode(Bool.self, forKey: .optimize)
	}
	
	static func ==(lhs: PNGFormat, rhs: PNGFormat) -> Bool {
		if lhs.mode == rhs.mode && lhs.optimize == rhs.optimize && lhs.preserveTransparency == rhs.preserveTransparency {
			return true
		}
		
		return false
	}
}

struct GIFFormat: ImageFormatProtocol{
	init(){}
	
	func encode(to encoder: Encoder) throws {
	}
	
	init(from decoder: Decoder) throws {
	}
	
	static func ==(lhs: GIFFormat, rhs: GIFFormat) -> Bool {
		return true
	}
}

enum ImageFormat: Codable, Equatable, ProvidesDefault {
	case Tiff(TiffFormat)
	case JPG(JPEGFormat)
	case PNG(PNGFormat)
	case GIF(GIFFormat)
	
	private enum CodingKeys: String, CodingKey {
		case type
		case options
	}
	
	enum FormatsError: Error {
		case unknownFormat
	}
	
	var rawValue: String {
		switch self {
		case .Tiff:
			return "Tiff"
		case .JPG:
			return "JPG"
		case .PNG:
			return "PNG"
		case .GIF:
			return "GIF"
		}
	}
	
	var ext: String {
		return self.rawValue.lowercased();
	}
	
	static var def: ImageFormat {
		return .JPG(JPEGFormat())
	}
	
	static func list() -> [String]{
		return ["JPG", "Tiff", "PNG", "GIF"]
	}
	
	static func from(rawValue: String) -> ImageFormat? {
		switch rawValue {
		case "JPG":
			return .JPG(JPEGFormat())
		case "Tiff":
			return .Tiff(TiffFormat())
		case "PNG":
			return .PNG(PNGFormat())
		case "GIF":
			return .GIF(GIFFormat())
		default:
			return nil
		}
	}
	
	init(rawValue: String) {
		switch rawValue {
		case "Tiff":
			self = .Tiff(TiffFormat())
		case "JPG":
			self = .JPG(JPEGFormat())
		case "PNG":
			self = .PNG(PNGFormat())
		case "GIF":
			self = .GIF(GIFFormat())
		default:
			self = ImageFormat.def
		}
	}
	
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: ImageFormat.CodingKeys.self)
		let type = try c.decode(String.self, forKey: ImageFormat.CodingKeys.type)
		switch type {
		case "JPG":
			let opts = try c.decode(JPEGFormat.self, forKey: ImageFormat.CodingKeys.options)
			self = .JPG(opts)
		case "Tiff":
			let opts = try c.decode(TiffFormat.self, forKey: ImageFormat.CodingKeys.options)
			self = .Tiff(opts)
		case "PNG":
			let opts = try c.decode(PNGFormat.self, forKey: ImageFormat.CodingKeys.options)
			self = .PNG(opts)
		case "GIF":
			let opts = try c.decode(GIFFormat.self, forKey: ImageFormat.CodingKeys.options)
			self = .GIF(opts)
		default:
			throw ImageFormat.FormatsError.unknownFormat
		}
	}
	
	static func from<T: ImageFormatProtocol>(type: T.Type) -> ImageFormat? {
		if type == JPEGFormat.self {
			return .JPG(JPEGFormat())
		}
		if type == TiffFormat.self {
			return .Tiff(TiffFormat())
		}
		if type == PNGFormat.self {
			return .PNG(PNGFormat())
		}
		if type == GIFFormat.self {
			return .GIF(GIFFormat())
		}
		return nil
	}
	
	static func from<T: ImageFormatProtocol>(format: T) -> ImageFormat? {
		if format is JPEGFormat {
			return .JPG(format as! JPEGFormat)
		}
		if format is TiffFormat {
			return .Tiff(format as! TiffFormat)
		}
		if format is PNGFormat {
			return .PNG(format as! PNGFormat)
		}
		if format is GIFFormat {
			return .GIF(format as! GIFFormat)
		}
		return nil
	}
	
	func getOptions<T: ImageFormatProtocol>() -> T {
		switch self {
		case .Tiff(let opts):
			return opts as! T
		case .JPG(let opts):
			return opts as! T
		case .PNG(let opts):
			return opts as! T
		case .GIF(let opts):
			return opts as! T
		}
	}
	
	func encode(to encoder: Encoder) throws {
		switch self {
		case .Tiff(let opts):
			var c = encoder.container(keyedBy: ImageFormat.CodingKeys.self)
			try c.encode(self.rawValue, forKey: .type)
			try c.encode(opts, forKey: .options)
		case .JPG(let opts):
			var c = encoder.container(keyedBy: ImageFormat.CodingKeys.self)
			try c.encode(self.rawValue, forKey: .type)
			try c.encode(opts, forKey: .options)
		case .PNG(let opts):
			var c = encoder.container(keyedBy: ImageFormat.CodingKeys.self)
			try c.encode(self.rawValue, forKey: .type)
			try c.encode(opts, forKey: .options)
		case .GIF(let opts):
			var c = encoder.container(keyedBy: ImageFormat.CodingKeys.self)
			try c.encode(self.rawValue, forKey: .type)
			try c.encode(opts, forKey: .options)
		}
	}
	
	static func ==(lhs: ImageFormat, rhs: ImageFormat) -> Bool {
		if lhs.ext != rhs.ext {
			return false
		}
		if case .Tiff(let optsa) = lhs, case .Tiff(let optsb) = rhs {
			if optsa == optsb {
				return true
			}
		}
		if case .JPG(let optsa) = lhs, case .JPG(let optsb) = rhs {
			if optsa == optsb {
				return true
			}
		}
		if case .PNG(let optsa) = lhs, case .PNG(let optsb) = rhs {
			if optsa == optsb {
				return true
			}
		}
		if case .GIF(let optsa) = lhs, case .GIF(let optsb) = rhs {
			if optsa == optsb {
				return true
			}
		}
		return false
	}
}
