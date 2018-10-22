//
//  FormatOptionsProtocol.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 28/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Foundation
import Cocoa

protocol FormatOptionsControllerProtocol {
	associatedtype DataItem = ImageFormatProtocol
	var data: DataItem? {get set}
	var changed: Event<DataItem> {get}
	var view: NSView {get set}
	func loadView() -> Void
}
