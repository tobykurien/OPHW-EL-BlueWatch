package za.co.house4hack.h4hwatch.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Notification
import android.app.PendingIntent
import android.graphics.Bitmap
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Data
import za.co.house4hack.h4hwatch.activities.MainActivity

import static za.co.house4hack.h4hwatch.activities.MainActivity.*

class NotificationService extends AccessibilityService {
   var static inbox = new ArrayList<EventInfo>

   override onAccessibilityEvent(AccessibilityEvent evt) {
      if (evt.packageName.toString.startsWith("za.co.house4hack.h4hwatch")) {
         // we got our own notification
         MainActivity.hasAccessibility = true
      } else {
         var notif = evt.parcelableData as Notification
         Log.d("notif", "[" + evt.packageName + "] " + evt.text)
         
         synchronized(inbox) {
            // don't keep more than 10 items in the inbox
            while (inbox.size > 10) inbox.remove(0)
            
            inbox.add(new EventInfo(
                  evt.text.get(0).toString, 
                  notif.largeIcon, 
                  notif.when, 
                  notif.number,
                  notif.contentIntent // TODO - may need to make a clone of this
               ))
         }
      }
   }

   override onInterrupt() {
   }

   override void onServiceConnected() {
      var info = new AccessibilityServiceInfo();
      info.eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED;
      info.feedbackType = AccessibilityServiceInfo.FEEDBACK_ALL_MASK;
      info.notificationTimeout = 100;
      setServiceInfo(info);
   }
   
   def public static getInbox() {
      inbox
   }
}

@Data class EventInfo {
   String text
   Bitmap icon
   long when
   int number
   PendingIntent pendingIntent
}