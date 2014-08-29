package za.co.house4hack.h4hwatch.modules.h4h

import android.content.Context
import android.graphics.Canvas
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.modules.WatchModule
import android.view.View.MeasureSpec

class House4HackGate extends WatchModule {
   var ViewGroup vg
   
   override init(Context context) {
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
      Log.d("h4h", "Open gate!")
   }
   
   override onSecondaryAction() {
      Log.d("h4h", "Open door!")
   }
   
}