package za.co.house4hack.h4hwatch.views

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import za.co.house4hack.h4hwatch.modules.clock.DigitalClock1
import za.co.house4hack.h4hwatch.modules.clock.AnalogClock1

/**
 * Renders the watch display by calling the appropriate module(s)
 */
class WatchDisplay {
   var clock = new AnalogClock1
   
   new(Context context) {
   }
   
   def void invalidate() {
   }
   
   def public Bitmap getBitmap() {
      //Define a bitmap with the same size as the view
      var Bitmap returnedBitmap = Bitmap.createBitmap(128, 64, Bitmap.Config.ARGB_8888);
      if (returnedBitmap == null) throw new Exception("Could not create bitmap")
      
      //Bind a canvas to it
      var Canvas canvas = new Canvas(returnedBitmap);
      if (canvas == null) throw new Exception("Could not create canvas")
      //does not have background drawable, then draw black background on the canvas
      canvas.drawColor(Color.BLACK);
      
      // draw the view on the canvas
      clock.onDraw(canvas);
      
      //return the bitmap
      return returnedBitmap;
   }
}