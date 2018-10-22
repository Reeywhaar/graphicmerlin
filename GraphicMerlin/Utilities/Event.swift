//
//  Event.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 24/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

public protocol Disposable {
	func dispose()
}

fileprivate protocol Invocable: class {
	func invoke(_ data: Any)
}

private class EventHandlerWrapper<T: AnyObject, U>
: Invocable, Disposable {
	weak var target: T?
	let handler: (T) -> (U) -> ()
	let event: Event<U>
	
	init(target: T?, handler: @escaping (T) -> (U) -> (), event: Event<U>) {
		self.target = target
		self.handler = handler
		self.event = event;
	}
	
	func invoke(_ data: Any) -> () {
		if let t = target {
			handler(t)(data as! U)
		}
	}
	
	func dispose() {
		event.eventHandlers =
			event.eventHandlers.filter { $0 !== self }
	}
}

public class Event<T> {
	
	public typealias EventHandler = (T) -> ()
	
	fileprivate var eventHandlers = [Invocable]()
	
	public func emit(data: T) {
		for handler in self.eventHandlers {
			handler.invoke(data)
		}
	}
	
	@discardableResult public func addListener<U: AnyObject>(
		target: U,
		handler: @escaping (U) -> EventHandler
	) -> Disposable {
		let wrapper = EventHandlerWrapper(
			target: target,
			handler: handler,
			event: self
		)
		eventHandlers.append(wrapper)
		return wrapper
	}
}
