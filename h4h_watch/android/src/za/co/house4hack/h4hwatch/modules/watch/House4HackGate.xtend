package za.co.house4hack.h4hwatch.modules.watch

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.os.Handler
import android.util.Log
import android.view.LayoutInflater
import android.view.View.MeasureSpec
import android.view.ViewGroup
import java.lang.ref.WeakReference
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.modules.WatchModule

import static extension org.xtendroid.utils.AlertUtils.*

class House4HackGate extends WatchModule {
   var ViewGroup vg
   var WeakReference<Context> context = null
   enum Entry {
      door, gate
   }
   
   override init(Context context) {
      this.context = new WeakReference(context)
      
      vg = LayoutInflater.from(context)
            .inflate(R.layout.module_h4h, null, false) as ViewGroup
      vg.measure(MeasureSpec.makeMeasureSpec(128, MeasureSpec.EXACTLY), 
                 MeasureSpec.makeMeasureSpec(64, MeasureSpec.EXACTLY));
   }
   
   override getName() {
      "House4Hack Entry"
   }
   
   override getDescription() {
      "Open the gate or door at House4Hack using the openSHAC app"
   }
   
   override onDraw(Canvas canvas) {
      vg.layout(0, 0, canvas.width - 1, canvas.height - 1)
      vg.draw(canvas)
   }
   
   override onPrimaryAction() {
      openH4h(Entry.gate)
   }
   
   override onSecondaryAction() {
      openH4h(Entry.door)
   }

   def openH4h(Entry access) {
      if (context.get != null) {
         Log.d("h4h", "Open " + access.toString)
         var intent = new Intent()
         intent.action = "za.co.house4hack.shac.OPEN"
         intent.addCategory(Intent.CATEGORY_DEFAULT)
         intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
         intent.putExtra("access", access.toString)
         
         try {
            context.get.startActivity(intent)
         } catch (ActivityNotFoundException e) {
            var handler = new Handler(context.get.mainLooper)
            handler.post [ context.get.toast("openSHAC app not installed") ]
         }
      }
   }   
}