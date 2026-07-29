package dev.raean.share_harbor.core

import java.io.File
import java.io.RandomAccessFile
import java.nio.channels.FileChannel
import java.nio.channels.FileLock

class FileLockManager(private val lockFile: File) {

    fun <T> withLock(timeoutMs: Long = 5000, action: () -> T): T {
        val parent = lockFile.parentFile
        if (parent != null && !parent.exists()) {
            parent.mkdirs()
        }

        var raf: RandomAccessFile? = null
        var channel: FileChannel? = null
        var lock: FileLock? = null

        try {
            raf = RandomAccessFile(lockFile, "rw")
            channel = raf.channel
            lock = channel.tryLock()
        } catch (_: Exception) {
            // Lock unavailable or held in JVM
        }

        try {
            return action()
        } finally {
            try {
                lock?.release()
            } catch (_: Exception) {}
            try {
                channel?.close()
            } catch (_: Exception) {}
            try {
                raf?.close()
            } catch (_: Exception) {}
        }
    }
}
