import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    if let screen = self.screen ?? NSScreen.main {
      self.setFrame(screen.visibleFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    if let icon = NSImage(named: "AppIcon") {
      NSApplication.shared.applicationIconImage = icon
    }

    super.awakeFromNib()
  }
}
