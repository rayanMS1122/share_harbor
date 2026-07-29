import Foundation

public class FileLockManager {
    private let lockFileUrl: URL

    public init(lockFileUrl: URL) {
        self.lockFileUrl = lockFileUrl
    }

    public func withLock<T>(timeoutSeconds: Double = 5.0, action: () throws -> T) throws -> T {
        let parentDir = lockFileUrl.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let fd = open(lockFileUrl.path, O_RDWR | O_CREAT, 0o666)
        if fd < 0 {
            throw NSError(domain: "ShareHarborLock", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open lock file at \(lockFileUrl.path)"])
        }

        defer {
            close(fd)
        }

        var lock = flock()
        lock.l_type = Int16(F_WRLCK)
        lock.l_whence = Int16(SEEK_SET)
        lock.l_start = 0
        lock.l_len = 0

        let startTime = Date()
        var acquired = false

        while !acquired {
            if fcntl(fd, F_SETLK, &lock) != -1 {
                acquired = true
            } else {
                if Date().timeIntervalSince(startTime) > timeoutSeconds {
                    throw NSError(domain: "ShareHarborLock", code: 2, userInfo: [NSLocalizedDescriptionKey: "Lock timeout exceeded on \(lockFileUrl.path)"])
                }
                usleep(50000) // 50ms
            }
        }

        defer {
            lock.l_type = Int16(F_UNLCK)
            _ = fcntl(fd, F_SETLK, &lock)
        }

        return try action()
    }
}
