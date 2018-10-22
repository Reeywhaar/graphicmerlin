//
//  shell.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 25/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

@discardableResult
func shell(bin: String, args: [String], terminate: Event<Any?>?) -> (String, Int32) {
	if args.contains("&&"){
		let pipe = Pipe()
		let stopped = Boxed(false)
		if terminate != nil {
			terminate!.addListener(target: pipe, handler: {
				(in: Pipe) in
				return {
					(in: Any?) in
					stopped.value = true;
				}
			})
		}
		let subargs = args.split(separator: "&&")
		var output = ""
		for args in subargs {
			let o = shell(bin: bin, args: Array(args), terminate: terminate)
			if stopped.value {
				break
			}
			if o.1 != 0 {
				output += o.0
				return (output, o.1)
			}
			output += o.0
		}
		return (output, 0)
	}
	
	let pipe = Pipe()
	let stopped = Boxed(false)
	
	if terminate != nil {
		terminate!.addListener(target: pipe, handler: {
			(in: Pipe) in
			return {
				(in: Any?) in
				stopped.value = true;
			}
		})
	}
	
	
	let task = Process()
	task.launchPath = bin
	task.arguments = args
	task.standardOutput = pipe
	task.launch()
	if terminate != nil {
		DispatchQueue.global(qos: .utility).async {
			while true {
				if task.isRunning && stopped.value {
					task.terminate()
				}
				if !task.isRunning {
					return;
				}
				usleep(20 * 1000)
			}
		}
	}
	task.waitUntilExit()
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: String.Encoding.utf8) ?? "";
	return (output, task.terminationStatus)
}

func shell(bin: String, args: [String]) -> (String, Int32) {
	return shell(bin: bin, args: args, terminate: nil)
}


func shell(_ args: [String]) -> (String, Int32) {
	return shell(bin: "/usr/bin/env", args: args)
}

func shell(_ args: [String], terminate: Event<Any?>) -> (String, Int32) {
	return shell(bin: "/usr/bin/env", args: args, terminate: terminate)
}

func shell(_ args: String...) -> (String, Int32) {
	return shell(args)
}

func item<T: Comparable>(_ value: T, in items: [T]) -> Bool{
	if items.contains(value) {
		return true;
	}
	return false;
}
