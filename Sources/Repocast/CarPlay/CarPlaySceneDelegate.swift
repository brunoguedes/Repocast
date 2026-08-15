import CarPlay
import UIKit

/// Entry point for the CarPlay scene, named by the Info.plist scene manifest
/// (`CPTemplateApplicationSceneSessionRoleApplication` in project.yml). All it
/// does is hand the interface controller to `CarPlayInterface`; the car and
/// the phone share `AudioPlayerService.shared`, so playback started on either
/// screen is visible and controllable from both.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private let interface = CarPlayInterface()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        interface.connect(interfaceController)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        interface.disconnect()
    }
}
