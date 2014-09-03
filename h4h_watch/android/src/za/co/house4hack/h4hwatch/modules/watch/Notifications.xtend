package za.co.house4hack.h4hwatch.modules.watch

import android.content.Context
import android.graphics.Canvas
import android.view.LayoutInflater
import android.view.View.MeasureSpec
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.modules.WatchModule
import za.co.house4hack.h4hwatch.services.NotificationService
import android.view.View

/**
 * Display notifications on the watch
 */
class Notifications extends WatchModule {
   int index = 0
   var ViewGroup vg
   var TextView title
   var ImageView icon
   
   override init(Context context) {
      vg = LayoutInflater.from(context)
            .inflate(R.layout.module_notifications, null, false) as ViewGroup
      vg.measure(MeasureSpec.makeMeasureSpec(128, MeasureSpec.EXACTLY), 
                 MeasureSpec.makeMeasureSpec(64, MeasureSpec.EXACTLY));
      title = vg.findViewById(R.id.notif_title) as TextView
      icon = vg.findViewById(R.id.notif_icon) as ImageView
   }
   
   override getName() {
      "Notifications"
   }
   
   override getDescription() {
      "Display notifications on the watch"
   }
   
   override onPrimaryAction() {
      index++
      if (index >= NotificationService.inbox.length) {
         index = 0
      }
   }

   override onSecondaryAction() {
      index--
      if (index < 0) {
         index = NotificationService.inbox.length - 1
      }
   }
   
   override onDraw(Canvas canvas) {
      if (NotificationService.inbox.length == 0) {
         title.text = "No notifications"
         icon.visibility = View.GONE
      } else if (index < NotificationService.inbox.length) {
         var notif = NotificationService.inbox.get(index)
         title.text = notif.text
         icon.imageBitmap = notif.icon
         icon.visibility = View.VISIBLE
      }
      
      vg.layout(0, 0, canvas.width - 1, canvas.height - 1)
      vg.draw(canvas)
   }
   
}