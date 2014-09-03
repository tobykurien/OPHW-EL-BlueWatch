package za.co.house4hack.h4hwatch.modules.clock

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Paint.Align
import android.graphics.Paint.Style
import java.text.SimpleDateFormat
import java.util.Date
import org.xtendroid.annotations.AndroidPreference
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.modules.WatchModule

class DigitalClock1 extends WatchModule {
   var Paint paint
   var Paint line
   var timeFormat24 = new SimpleDateFormat("H:mm")
   var timeFormat12 = new SimpleDateFormat("h:mm")
   var dateFormat = new SimpleDateFormat("EEE, d MMM")
   var DigitalClock1Settings settings = null

   override init(Context context) {
      paint = new Paint
      paint.color = Color.WHITE
      paint.style = Style.FILL
      paint.textSize = 40
      paint.textAlign = Align.CENTER

      line = new Paint
      line.color = Color.WHITE
      line.style = Style.STROKE

      settings = DigitalClock1Settings.getDigitalClock1Settings(context)
   }

   override getName() {
      "Digital Clock 1"
   }

   override getDescription() {
      "Simple digital clock"
   }

   override onDraw(Canvas canvas) {
      var date = new Date

      var textX = canvas.width / 2
      var textY = canvas.height / 2 + 14

      var timeFormat = timeFormat24
      if (!settings.dc1Hours24) {
         timeFormat = timeFormat12
      }
      
      if (settings.dc1ShowDate) {
         paint.textSize = 30
         textY -= 14
      } else {
         paint.textSize = 40
      }

      canvas.save

      canvas.drawText(timeFormat.format(date), textX, textY, paint)
      
      if (settings.dc1ShowDate) {
         paint.textSize = 10
         canvas.drawText(dateFormat.format(date), textX, textY + 20, paint)
      }
      
      if(settings.dc1ShowBorder) canvas.drawRect(0, 0, canvas.width - 1, canvas.height - 1, line)

      canvas.restore
   }

   override getSettings() {
      return R.xml.module_dclock1_settings
   }

}

/**
 * Class to store the settings for the digital clock
 */
@AndroidPreference class DigitalClock1Settings {

   // avoid naming conflicts by adding a prefix
   boolean dc1ShowBorder = true
   boolean dc1ShowDate = false
   boolean dc1Hours24 = true
}
