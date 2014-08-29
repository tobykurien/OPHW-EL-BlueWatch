package za.co.house4hack.h4hwatch.modules.clock

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Paint.Style
import java.util.Date
import za.co.house4hack.h4hwatch.modules.WatchModule

class AnalogClock1 extends WatchModule {
   var Paint line
   
   override void init(Context context) {
      line = new Paint
      line.color = Color.WHITE
      line.style = Style.STROKE
   }
   
   override getName() {
      "Analog Clock 1"
   }
   
   override getDescription() {
      "Simple analog clock"
   }

   override onDraw(Canvas canvas) {
      var date = new Date
      var hours = date.hours
      if (hours >= 12) hours = hours - 12
      var mins = date.minutes
      
      var centerX = canvas.width/2
      var centerY = canvas.height/2
      
      canvas.save

      line.strokeWidth = 2
      canvas.drawCircle(canvas.width/2, canvas.height/2, 30, line)
      for (var i=0; i < 12; i++) {
         // draw hour ticks
         canvas.drawLine(centerX, centerY - 26, centerX, 0, line)
         canvas.rotate(360/12, centerX, centerY)
      }

      // draw hour needle
      line.strokeWidth = 4
      var deg = 360f/12f * (hours as float + mins as float/60f)
      canvas.rotate(deg, centerX, centerY)
      canvas.drawLine(centerX, centerY, centerX, 16, line)
      canvas.rotate(-deg, centerX, centerY)

      // draw minute needle
      line.strokeWidth = 3
      canvas.rotate(360/60 * mins, centerX, centerY)
      canvas.drawLine(centerX, centerY, centerX, 5, line)
      
      canvas.restore
   }
}