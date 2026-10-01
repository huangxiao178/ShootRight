import Foundation

/// 轻量运行追踪日志：写入 App 沙盒 Documents/app_trace.log
/// 用途：真机闪退时通过 爱思助手-文件 导出该文件，可看到崩溃前执行到哪一步
enum AppLogger {
    private static let lock = NSLock()
    private static var fileURL: URL? = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("app_trace.log")
    }()

    static func log(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let url = fileURL else { return }
        let line = "[\(Date().timeIntervalSince1970)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}
