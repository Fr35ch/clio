// HoverCursor.swift
// Clio
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// `.hoverCursor()` — pointing-hand cursor while hovering, arrow when not.
// Use this on every clickable surface so the cursor affordance is
// consistent. Replaces 12+ inline `NSCursor.pointingHand.set()` / `.arrow.set()`
// patterns sprinkled across views.

import AppKit
import SwiftUI

extension View {
    /// Shows `NSCursor.pointingHand` while the cursor is over the view,
    /// reverts to `NSCursor.arrow` on exit. Apply to any interactive
    /// surface that doesn't already use a SwiftUI Button with a default
    /// macOS button style.
    func hoverCursor() -> some View {
        self.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}
