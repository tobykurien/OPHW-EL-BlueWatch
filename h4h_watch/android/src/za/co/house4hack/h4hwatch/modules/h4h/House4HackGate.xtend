package za.co.house4hack.h4hwatch.modules.h4h

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.util.Log
import android.widget.TextView
import za.co.house4hack.h4hwatch.modules.WatchModule
import android.widget.LinearLayout
import android.widget.LinearLayout.LayoutParams
import android.view.Gravity

class House4HackGate extends WatchModule {
   var TextView tv
   
   override init(Context context) {
      tv = new TextView(context)
      tv.text = "House4Hack entry"
      tv.textColor = Color.WHITE
      tv.textSize = 12
      tv.gravity = Gravity.CENTER
   }
   
   override getName() {
      "House4Hack Entry"
   }
   
   override getDescription() {
      "Open the gate or door at House4Hack using the openSHAC app"
   }
   
   override onDraw(Canvas canvas) {
      tv.layout(0, 0, canvas.width, canvas.height)
      tv.draw(canvas)
   }
   
   override onPrimaryAction() {
      Log.d("h4h", "Open gate!")
   }
   
   override onSecondaryAction() {
      Log.d("h4h", "Open door!")
   }
   
}