//
//  ImageConverter.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 25/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

struct ImageConverter{
	enum Error: Swift.Error {
		case shellError(String)
	}
	
	typealias Size = (UInt?, UInt?)
	
	let target: URL
	let directory: URL
	let format: ImageFormat
	let size: ImageConverter.Size
	let filename: String
	
	init?(
		target: URL,
		directory: URL,
		format: ImageFormat,
		size: ImageConverter.Size,
		filename: String
	) {
		if !FileManager.default.fileExists(atPath: target.path) {
			return nil
		}
		self.target = target
		self.directory = directory
		self.format = format
		self.size = size
		self.filename = filename
	}
	
	var destination: URL {
		return self.directory.appendingPathComponent(self.filename).deletingPathExtension().appendingPathExtension(self.format.ext)
	}
	
	func getCmdArgs() -> [String] {
		var parts: [String] = ["/usr/local/bin/convert"]
		
		switch self.size {
		case (let width?, let height?):
			parts.append("-resize")
			parts.append("\(width)x\(height)")
		case (let width?, nil):
			parts.append("-resize")
			parts.append("\(width)x")
		case (nil, let height?):
			parts.append("-resize")
			parts.append("x\(height)")
		default:
			break
		}
		
		parts.append("-strip")
		
		switch self.format {
		case .Tiff(let opts):
			parts.append("-compress")
			parts.append(opts.compression.rawValue.lowercased())
			if opts.preserveTransparency {
				parts.append("-background")
				parts.append("none")
				parts.append("-flatten")
			} else {
				parts.append("-background")
				parts.append("white")
				parts.append("-alpha")
				parts.append("remove")
				parts.append("-flatten")
			}
		case .JPG(let opts):
			parts.append("-quality")
			parts.append("\(opts.quality)")
			parts.append("-alpha")
			parts.append("remove")
			parts.append("-background")
			parts.append("white")
			parts.append("-flatten")
		case .PNG(let opts):
			if opts.preserveTransparency {
				parts.append("-background")
				parts.append("none")
				parts.append("-flatten")
			} else {
				parts.append("-background")
				parts.append("white")
				parts.append("-flatten")
			}
			if opts.mode == 8 {
				parts.append("-format")
				parts.append("PNG8")
				parts.append("-colors")
				parts.append("256")
			} else if opts.mode == 24 {
				parts.append("-format")
				parts.append(opts.preserveTransparency ? "PNG32" : "PNG24")
			}
		default:
			break
		}
		
		if item(self.target.pathExtension, in: ["psd", "tiff", "tif"]) {
			parts.append(self.target.path + "[0]")
		} else {
			parts.append(self.target.path)
		}
		
		parts.append(self.destination.path)
		
		if case .PNG(let opts) = self.format {
			if opts.optimize {
				parts.append("&&")
				parts.append("/usr/local/bin/pngcrush")
				parts.append("-reduce")
				parts.append("-brute")
				parts.append("-ow")
				parts.append(self.destination.path)
			}
		}
		
		return parts
	}
	
	func convert(_ terminateSignal: Event<Any?>?) throws {
		let output = terminateSignal != nil ? shell(self.getCmdArgs(), terminate: terminateSignal!) : shell(self.getCmdArgs());
//		let output = terminateSignal != nil ? shell(["sleep", "1"], terminate: terminateSignal!) : shell("sleep", "1");
//		print(output.0)
		if output.1 != 0 {
			throw ImageConverter.Error.shellError(output.0)
		}
	}
}
