import SwiftUI
import AppKit

@main
struct KimiBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            KimiMenu()
        } label: {
            KimiLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

struct KimiLabel: View {
    @StateObject private var model = KimiBarModel.shared

    var body: some View {
        if let quota = model.quota {
            Image(nsImage: MenuBarTextRenderer.image(
                weekly: quota.weekly.percentage,
                fiveHour: quota.fiveHour.percentage
            ))
        } else {
            Text(model.text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
    }
}

@MainActor
enum MenuBarTextRenderer {
    static func image(weekly: Int, fiveHour: Int) -> NSImage {
        let content = VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 3) {
                Text("7D")
                    .frame(width: 20, alignment: .leading)
                Text("\(weekly)\u{2009}%")
                    .frame(width: 32, alignment: .trailing)
            }
            HStack(spacing: 3) {
                Text("5H")
                    .frame(width: 20, alignment: .leading)
                Text("\(fiveHour)\u{2009}%")
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .default))
        .monospacedDigit()
        .foregroundStyle(Color(red: 0.886, green: 0.910, blue: 0.961))
        .frame(width: 55, height: 22, alignment: .trailing)

        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0

        guard let nsImage = renderer.nsImage else {
            return NSImage(size: NSSize(width: 56, height: 22))
        }
        nsImage.isTemplate = false
        return nsImage
    }
}

struct KimiMenu: View {
    @StateObject private var model = KimiBarModel.shared
    @State private var editingKey = ""

    private let consoleURL = URL(string: "https://www.kimi.com/code/console")!

    var body: some View {
        VStack(spacing: 0) {
            // 统计区域
            if let quota = model.quota {
                QuotaDashboard(quota: quota)
                    .padding(.top, 20)
            } else {
                Text(model.text)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(.top, 20)
            }

            Divider()
                .padding(.vertical, 16)

            // API Key 编辑行
            HStack(spacing: 12) {
                Text("API Key")
                    .font(.system(size: 13))
                    .frame(width: 60, alignment: .leading)

                SecureField("输入 API Key", text: $editingKey)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 控制台快捷方式
            Button {
                NSWorkspace.shared.open(consoleURL)
            } label: {
                Text("KimiCode控制台")
                    .font(.caption)
            }
            .buttonStyle(.link)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)

            Spacer(minLength: 16)

            // 底部操作区
            HStack(spacing: 12) {
                Button("保存") {
                    model.key = editingKey
                }
                .disabled(editingKey.isEmpty)

                Button("刷新") {
                    model.refresh()
                }
                .disabled(model.key.isEmpty)

                Button("立即刷新") {
                    model.key = editingKey
                    model.refresh()
                }
                .disabled(editingKey.isEmpty)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .frame(width: 340)
        .onAppear {
            editingKey = model.key
        }
    }
}

struct QuotaDashboard: View {
    let quota: KimiQuota

    var body: some View {
        HStack(spacing: 0) {
            StatColumn(
                title: "本周用量",
                value: quota.weekly.percentage,
                reset: quota.weekly.timeUntilReset,
                color: .blue
            )

            Divider()
                .frame(height: 56)
                .padding(.horizontal, 16)

            StatColumn(
                title: "5小时用量",
                value: quota.fiveHour.percentage,
                reset: quota.fiveHour.timeUntilReset,
                color: .orange
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct StatColumn: View {
    let title: String
    let value: Int
    let reset: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(value)%")
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .monospacedDigit()

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 3)
                        .foregroundStyle(.secondary.opacity(0.15))

                    Capsule()
                        .frame(width: proxy.size.width * CGFloat(min(value, 100)) / 100, height: 3)
                        .foregroundStyle(color)
                }
            }
            .frame(width: 72, height: 3)

            Text(reset)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
final class KimiBarModel: ObservableObject {
    static let shared = KimiBarModel()

    @AppStorage("kimiApiKey") var key = ""
    @Published var text = "-- · --"
    @Published var quota: KimiQuota?

    private let service = KimiQuotaService()
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in self.refresh() }
        }
    }

    func refresh() {
        guard !key.isEmpty else {
            text = "未配置"
            quota = nil
            return
        }
        Task {
            if let quota = await service.fetchQuota(key: key) {
                self.quota = quota
                self.text = "周 \(quota.weekly.percentage)% · 5h \(quota.fiveHour.percentage)%"
            } else {
                self.text = "--"
                self.quota = nil
            }
        }
    }
}
