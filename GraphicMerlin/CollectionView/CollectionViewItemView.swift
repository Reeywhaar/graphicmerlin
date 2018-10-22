//
//  CollectionViewItem.swift
//  GraphicMerlin
//
//  Created by Vyrtsev Mikhail on 23/05/2018.
//  Copyright © 2018 Vyrtsev Mikhail. All rights reserved.
//

import Cocoa
import QuickLook

class CollectionViewItemView: NSView {
	override func hitTest(_ point: NSPoint) -> NSView? {
		let view = super.hitTest(point)
		if view == self {
			return self.superview
		}
		return view
	}
}
