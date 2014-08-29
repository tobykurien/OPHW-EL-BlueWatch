package za.co.house4hack.h4hwatch.logic

import android.content.Context
import android.graphics.Color
import android.util.Log
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper.BluetoothActivity
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.modules.clock.AnalogClock1
import za.co.house4hack.h4hwatch.modules.clock.DigitalClock1
import za.co.house4hack.h4hwatch.views.WatchDisplay

/**
 * Helper class to be used by the blueooth service to handle watch 
 * functionality
 */
class WatchServiceHelper implements BluetoothActivity {
   val public static clockModules = #[
      new DigitalClock1, new AnalogClock1
   ]

   var static WatchServiceHelper instance   
      
   var BluetoothHelper btUtils = null;   
   val Context context
   var WatchDisplay watchDisplay
   var selectedClock = 0
   
   new(BluetoothService context) {
      instance = this
      this.context = context   
      btUtils = new BluetoothHelper(context.applicationContext, this)
      watchDisplay = new WatchDisplay(context.applicationContext, 
         clockModules.get(0))
   }
   
   def onStateChanged(WatchState.Item thatChanged) {
      logMessage("Got state change " + thatChanged.toString)
      if (thatChanged == WatchState.Item.bluetooth) {
         if (btUtils.mService.watchState.getBluetooth() == BluetoothService.STATE_CONNECTED) {
            // connected
            btUtils.mService.showNotification("Watch connected")
            sendFrameBuffer()
         } else {
            btUtils.mService.showNotification("Watch not connected")
         }
      } else if (thatChanged == WatchState.Item.frameBuffer) {
         sendFrameBuffer
      }
   }
   
   def sendFrameBuffer() {
      // start sending frame buffer
      var bitmap = watchDisplay.bitmap
      var bytes = newByteArrayOfSize(128*64/8 + 2)
      bytes.set(0, 0x1 as byte) // start frame buffer command
      var float[] hsv = newFloatArrayOfSize(3)
   
      // convert bitmap to monochrome frame buffer         
      for (var i=1; i < bytes.length; i++) {
         // loop through the target frame buffer
         var int b = 0
         for (var y=7; y >= 0; y--) {
            // in the target frame buffer, each byte is 8 *vertical* pixels
            var row = ((i-1) / 128) as int // work out the row based on index in frame buffer

            // get the corresponding pixel from the image to send (remember, 8 vertical pixels per byte)
            // sequence for x and y coordinates for scanning image into buffer is: 
            //  0x7, 0x6, ..., 0x0, 1x7, 1x6, ..., 1x0, ..., 127x1, 127x0, 
            //  0x15, 0x14, ..., 0x8, 1x15, 1x14, ... 
            var xCoord = (i-1) % 128
            var yCoord = y + (row * 8)

            if (yCoord < bitmap.height && xCoord < bitmap.width) {
               var pix = bitmap.getPixel(xCoord, yCoord)
               // convert the ARGB value into HSV value to make it easier to convert to monochrome
               Color.colorToHSV(pix, hsv)
               // set the corresponding bit in frame buffer based on brightness threshold
               b = if (hsv.get(2) > 0.6) {
                     // set the bit for this pixel
                     b.bitwiseOr(1 << y) 
                   } else {
                     // clear the bit for this pixel
                     b.bitwiseAnd((0x1 << y).bitwiseNot)
                   } 
            }               
         }
         
         // set the byte that now represents the 8 vertical pixels
         bytes.set(i, b as byte)
      }
                     
      btUtils.mService.write(bytes)
   }
   
   override void logMessage(String message) {
      Log.d("watch", message)
   }
   
   def static void setSelectedClock(int clock) {
      if (clock < clockModules.length && clock >= 0) {
         instance.selectedClock = clock
         instance.watchDisplay = new WatchDisplay(
            instance.context.applicationContext, 
            clockModules.get(clock))
      }
   }
}