package dev.rayan.share_harbor.core

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.InputStream
import java.util.UUID

object IntentDecoder {

    fun decodeIntent(context: Context, intent: Intent): Pair<List<Pair<SpoolItem, InputStream>>, String?> {
        val action = intent.action ?: return Pair(emptyList(), null)
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)

        val streamUris = mutableListOf<Uri>()

        if (action == Intent.ACTION_SEND) {
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                ?: intent.data
            if (uri != null) {
                streamUris.add(uri)
            }
        } else if (action == Intent.ACTION_SEND_MULTIPLE) {
            val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            if (uris != null) {
                streamUris.addAll(uris)
            }
        }

        intent.clipData?.let { clipData ->
            for (i in 0 until clipData.itemCount) {
                clipData.getItemAt(i).uri?.let { uri ->
                    if (!streamUris.contains(uri)) {
                        streamUris.add(uri)
                    }
                }
            }
        }

        val items = mutableListOf<Pair<SpoolItem, InputStream>>()

        for (uri in streamUris.distinct()) {
            val inputStream = context.contentResolver.openInputStream(uri) ?: continue
            val mimeType = context.contentResolver.getType(uri) ?: "application/octet-stream"
            val displayName = queryDisplayName(context, uri)

            val itemId = UUID.randomUUID().toString()
            val kind = mapMimeTypeToKind(mimeType)

            val item = SpoolItem(
                itemId = itemId,
                kind = kind,
                originalName = displayName,
                internalName = "$itemId.payload",
                declaredMimeType = mimeType,
                resolvedMimeType = mimeType,
                byteLength = querySize(context, uri)
            )

            items.add(Pair(item, inputStream))
        }

        val combinedText = when {
            text != null && subject != null -> "$subject\n$text"
            text != null -> text
            subject != null -> subject
            else -> null
        }

        return Pair(items, combinedText)
    }

    private fun mapMimeTypeToKind(mimeType: String): String {
        return when {
            mimeType.startsWith("image/") -> "image"
            mimeType.startsWith("video/") -> "video"
            mimeType.startsWith("text/html") -> "html"
            mimeType.startsWith("text/") -> "text"
            else -> "file"
        }
    }

    private fun queryDisplayName(context: Context, uri: Uri): String? {
        if (uri.scheme == "content") {
            try {
                context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index != -1) {
                            return cursor.getString(index)
                        }
                    }
                }
            } catch (_: Exception) {}
        }
        return uri.lastPathSegment
    }

    private fun querySize(context: Context, uri: Uri): Long {
        if (uri.scheme == "content") {
            try {
                context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (index != -1) {
                            return cursor.getLong(index)
                        }
                    }
                }
            } catch (_: Exception) {}
        }
        return 0L
    }
}
