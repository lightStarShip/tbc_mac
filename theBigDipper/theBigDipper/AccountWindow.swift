//
//  AccountWindow.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/7.
//

import Cocoa
import SwiftUI

class AccountWindow<RootView : View>: NSWindowController {

        convenience init(rootView: RootView) {
                let hostingController = NSHostingController(rootView: rootView.frame(width: 400, height: 500))
                let window = NSWindow(contentViewController: hostingController)
                window.setContentSize(NSSize(width: 400, height: 500))
                self.init(window: window)
            }
}
