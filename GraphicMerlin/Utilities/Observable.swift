//
//  File.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 05/06/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

protocol ObservableProtocol {
	associatedtype T
	var value: T { get set }
	func subscribe(
		_ observer: AnyObject,
		_ handler: @escaping (_ newValue: T, _ oldValue: T) -> ()
	)
	func unsubscribe(_ observer: AnyObject)
}

class Observable<T>: ObservableProtocol {
	typealias ObserverHandler = (_ newValue: T, _ oldValue: T) -> ()
	typealias ObserverEntry = (observer: AnyObject?, handler: ObserverHandler)
	private var observers: [ObserverEntry]
	
	var value: T {
		didSet {
			for observer in self.observers {
				if observer.observer == nil {
					continue
				}
				observer.handler(value, oldValue)
			}
		}
	}
	
	init(_ value: T) {
		self.value = value
		self.observers = []
	}
	
	func subscribe(_ observer: AnyObject, _ handler: @escaping ObserverHandler) {
		observers.append((observer: observer, handler: handler))
	}
	
	func unsubscribe(_ observer: AnyObject) {
		observers = observers.filter { entry in
			return entry.observer !== observer
		}
	}
}
