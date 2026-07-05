package me.symon.rivus

import android.content.ContentResolver
import android.database.Cursor
import android.provider.MediaStore

/**
 * Queries MediaStore.Audio.Media for all music tracks visible to this app,
 * across internal storage and any mounted SD card (MediaStore is
 * storage-volume-agnostic; it returns whatever the system has indexed,
 * regardless of which physical volume a file lives on).
 *
 * Returns MediaStore.Audio.Media.DATA (the on-disk path) rather than a
 * content:// URI, since the app's embedded HTTP file server needs a real
 * filesystem path it can open directly, not an Android ContentResolver
 * reference. MediaStore's DATA column remains populated and readable for
 * apps holding READ_MEDIA_AUDIO; scoped storage's restrictions target
 * arbitrary app-private files, not the shared media collections this
 * permission exists for.
 */
class MediaStoreAudioQuery(private val contentResolver: ContentResolver) {

    fun querySongs(): List<Map<String, Any?>> {
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.MIME_TYPE,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"

        val songs = mutableListOf<Map<String, Any?>>()

        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder,
        )?.use { cursor: Cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val mimeTypeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)

            while (cursor.moveToNext()) {
                val path = cursor.getString(dataCol) ?: continue
                songs.add(
                    mapOf(
                        "id" to cursor.getLong(idCol).toString(),
                        "title" to cursor.getString(titleCol),
                        "durationMs" to cursor.getLong(durationCol),
                        "path" to path,
                        "mimeType" to cursor.getString(mimeTypeCol),
                    ),
                )
            }
        }

        return songs
    }
}
