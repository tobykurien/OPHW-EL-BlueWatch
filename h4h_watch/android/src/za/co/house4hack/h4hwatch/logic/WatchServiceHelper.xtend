package za.co.house4hack.h4hwatch.logic

import android.content.Context
import android.graphics.Color
import android.util.Log
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper.BluetoothActivity
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.views.WatchDisplay

/**
 * Helper class to be used by the blueooth service to handle watch 
 * functionality
 */
class WatchServiceHelper implements BluetoothActivity {
   var BluetoothHelper btUtils = null;   
   val Context context
   var WatchDisplay watchDisplay
   
   new(BluetoothService context) {
      this.context = context   
      btUtils = new BluetoothHelper(context.applicationContext, this)
      watchDisplay = new WatchDisplay(context.applicationContext)
   }
   
   def onStateChanged(WatchState.Item thatChanged) {
      logMessage("Got state change " + thatChanged.toString)
      if (thatChanged == WatchState.Item.bluetooth) {
         if (btUtils.mService.watchState.getBluetooth() == BluetoothService.STATE_CONNECTED) {
            // connected
            sendFrameBuffer()
         }
      } else if (thatChanged == WatchState.Item.frameBuffer) {
         sendFrameBuffer
      }
   }
   
   def sendFrameBuffer() {
      // start sending frame buffer
      var bitmap = watchDisplay.bitmap
      var bytes = newByteArrayOfSize(128*64/8 + 1)
      bytes.set(0, 0x1 as byte) // start frame buffer command
      var float[] hsv = newFloatArrayOfSize(3)
   
      // convert bitmap to monochrome frame buffer         
      for (var i=1; i < bytes.length; i++) {
         // loop through the target frame buffer
         var int b = 0
         for (var x=7; x >= 0; x--) {
            // in the target frame buffer, each byte is 8 *vertical* pixels
            var row = (i / 128) as int // work out the row based on index in frame buffer
            
            // get the corresponding pixel from the image to send (remember, 8 vertical pixels per byte)               
            var pix = bitmap.getPixel((i-1) % 128, x + (row * 7))
            // convert the ARGB value into HSV value to make it easier to convert to monochrome
            Color.colorToHSV(pix, hsv)
            // set the corresponding bit in frame buffer based on brightness threshold
            b = if (hsv.get(2) > 0.6) b.bitwiseOr(1 << x) else b.bitwiseAnd((0x1 << x).bitwiseNot) 
         }
         
         // set the byte that now represents the 8 vertical pixels
         bytes.set(i, b as byte)
      }
                     
      btUtils.mService.write(bytes)
   }
   
   override void logMessage(String message) {
      Log.d("watch", message)
   }
}