//
//  Boxed.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 26/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation

class Boxed<Element>{
	var value: Element
	init(_ value: Element){
		self.value = value
	}
}

#if swift(>=4.2)
extension Boxed: Equatable where Element: Equatable {
	static func ==(lhs: Boxed<Element>, rhs: Boxed<Element>) -> Bool {
		return lhs.value == rhs.value
	}
}
#else
	extension Boxed where Element: Equatable {
		static func ==(lhs: Boxed<Element>, rhs: Boxed<Element>) -> Bool {
			return lhs.value == rhs.value
		}
	}
#endif

