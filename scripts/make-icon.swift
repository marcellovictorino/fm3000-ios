// swiftc -o /tmp/make-icon scripts/make-icon.swift && /tmp/make-icon App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import AppKit
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(calibratedRed: 0.09, green: 0.16, blue: 0.30, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
let style = NSMutableParagraphStyle(); style.alignment = .center
let text = NSAttributedString(string: "FM", attributes: [
    .font: NSFont.systemFont(ofSize: 480, weight: .heavy), .foregroundColor: NSColor.white, .paragraphStyle: style,
])
text.draw(in: NSRect(x: 0, y: 250, width: size, height: 560))
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
