package za.co.house4hack.h4hwatch.modules.clock

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import java.text.SimpleDateFormat
import java.util.Date
import za.co.house4hack.h4hwatch.modules.WatchModule
import android.graphics.Paint.Style
import android.graphics.Paint.Align
import android.content.Context

class DigitalClock1 extends WatchModule {
   var Paint paint
   var Paint line
   var timeFormat = new SimpleDateFormat("HH:mm")
   
   override init(Context context) {
      paint = new Paint
      paint.color = Color.WHITE
      paint.style = Style.FILL
      paint.textSize = 40
      paint.textAlign = Align.CENTER

      line = new Paint
      line.color = Color.WHITE
      line.style = Style.STROKE
   }
   
   override getName() {
      "Digital Clock 1"
   }
   
   override getDescription() {
      "Simple digital clock"
   }

   override onDraw(Canvas canvas) {
      var date = new Date
      
      canvas.save
      
      canvas.drawText(timeFormat.format(date), canvas.width/2, canvas.height/2 + 14, paint)
      canvas.drawRect(0, 0, canvas.width - 1, canvas.height - 1, line)
      
      canvas.restore
   }
}