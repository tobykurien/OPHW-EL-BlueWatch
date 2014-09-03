package za.co.house4hack.h4hwatch.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class NotificationService extends AccessibilityService {

   override onAccessibilityEvent(AccessibilityEvent evt) {
      Log.d("notif", "Got " + evt.packageName)
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
}
