import Foundation
import Sparkle

final class SparkleUpdater: ObservableObject {
    static let shared = SparkleUpdater()

    private let updaterController: SPUStandardUpdaterController
    private let delegate: UpdaterDelegate

    @Published var isUpdateAvailable = false
    @Published var isUpdateReadyToRestart = false

    private init() {
        let delegate = UpdaterDelegate()
        self.delegate = delegate
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        delegate.owner = self
    }

    /// 后台静默检查并下载更新（配合 SUAutomaticallyUpdate 使用）
    func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }

    /// 调用 Sparkle 立即安装并重启
    func restartToInstallUpdate() {
        delegate.installUpdateBlock?()
    }

    // MARK: - Inner Delegate

    private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
        weak var owner: SparkleUpdater?
        var installUpdateBlock: (() -> Void)?

        func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
            DispatchQueue.main.async {
                self.owner?.isUpdateAvailable = true
            }
        }

        func updater(_ updater: SPUUpdater, didNotFindUpdate error: Error) {
            DispatchQueue.main.async {
                self.owner?.isUpdateAvailable = false
            }
        }

        func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock: @escaping () -> Void) {
            DispatchQueue.main.async {
                self.installUpdateBlock = immediateInstallationBlock
                self.owner?.isUpdateReadyToRestart = true
            }
        }
    }
}
