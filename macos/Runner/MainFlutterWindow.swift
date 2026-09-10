import Cocoa
import FlutterMacOS

/// Hosts the Flutter view on top of a system vibrancy layer so the desktop
/// shows through the app's paper tint (frosted-glass window).
class GlassViewController: NSViewController {
  let flutterViewController = FlutterViewController()

  override func loadView() {
    let glass = NSVisualEffectView()
    glass.autoresizingMask = [.width, .height]
    glass.blendingMode = .behindWindow
    glass.state = .followsWindowActiveState
    glass.material = .sidebar
    view = glass
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    addChild(flutterViewController)
    flutterViewController.view.frame = view.bounds
    flutterViewController.view.autoresizingMask = [.width, .height]
    // Flutter paints an opaque black background by default; clear it so the
    // vibrancy layer underneath is visible wherever Dart paints translucently.
    flutterViewController.backgroundColor = .clear
    view.addSubview(flutterViewController.view)
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let glassViewController = GlassViewController()
    let windowFrame = self.frame
    self.contentViewController = glassViewController
    self.setFrame(windowFrame, display: true)

    isOpaque = false
    backgroundColor = .clear

    RegisterGeneratedPlugins(registry: glassViewController.flutterViewController)

    super.awakeFromNib()
  }
}
