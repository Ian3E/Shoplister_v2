import SwiftUI
import UIKit

private final class ShakeDetectorController: UIViewController {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.isUserInteractionEnabled = false
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake?()
    }
}

private struct DeviceShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorController {
        let controller = ShakeDetectorController()
        controller.onShake = onShake
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ controller: ShakeDetectorController, context: Context) {
        controller.onShake = onShake
        DispatchQueue.main.async {
            _ = controller.becomeFirstResponder()
        }
    }
}

extension View {
    func onDeviceShake(perform action: @escaping () -> Void) -> some View {
        background {
            DeviceShakeDetector(onShake: action)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}
