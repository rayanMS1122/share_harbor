package dev.rayan.share_harbor

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import dev.rayan.share_harbor.core.FileSpool
import dev.rayan.share_harbor.core.IntentDecoder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ShareHarborReceiverActivity : Activity() {

    private val activityScope = CoroutineScope(Dispatchers.Main + Job())
    private var isCancelled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(64, 64, 64, 64)
        }

        val statusText = TextView(this).apply {
            text = "Saving shared content to ShareHarbor..."
            textSize = 16f
            gravity = Gravity.CENTER
        }
        val progressBar = ProgressBar(this).apply {
            isIndeterminate = true
        }
        val cancelButton = Button(this).apply {
            text = "Cancel"
            setOnClickListener {
                isCancelled = true
                finish()
            }
        }

        layout.addView(statusText)
        layout.addView(progressBar)
        layout.addView(cancelButton)
        setContentView(layout)

        val intent = intent
        if (intent == null) {
            finish()
            return
        }

        activityScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val (items, text) = IntentDecoder.decodeIntent(applicationContext, intent)
                    if (isCancelled || items.isEmpty() && text == null) {
                        return@withContext
                    }

                    val spool = FileSpool(applicationContext.filesDir)
                    spool.commitDelivery(
                        items = items,
                        text = text,
                        subject = intent.getStringExtra(android.content.Intent.EXTRA_SUBJECT),
                        source = callingPackage
                    )
                }

                statusText.text = "Saved successfully!"
                progressBar.visibility = View.GONE
                cancelButton.visibility = View.GONE

                packageManager.getLaunchIntentForPackage(packageName)?.let { launchIntent ->
                    launchIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(launchIntent)
                }
            } catch (e: Exception) {
                statusText.text = "Error: ${e.localizedMessage}"
            } finally {
                finish()
            }
        }
    }
}
