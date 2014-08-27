package za.co.house4hack.h4hwatch.activities

import android.graphics.Color
import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper.BluetoothActivity
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.logic.WatchState.Item

@AndroidActivity(R.layout.activity_main) class MainActivity implements BluetoothActivity {
   var BluetoothHelper btUtils = null;
   
   @OnCreate
   def void init() {
      btUtils = new BluetoothHelper(this)
      
      watchDisplay.onClickListener = [
         sendFrameBuffer
      ]
   }
   
   override onDestroy() {
      btUtils.destroy
      super.onDestroy
   }
   
   def onStateChanged(Item thatChanged) {
      runOnUiThread [|
         if (thatChanged == Item.bluetooth) {
            // disable connect action if we are already connected
            if (btUtils.mService.watchState.getBluetooth() != BluetoothService.STATE_CONNECTED) {
               switch (btUtils.mService.watchState.getBluetooth()) {
                  case BluetoothService.STATE_CONNECTING: 
                     logMessage("Bluetooth connecting")
                  case BluetoothService.STATE_LISTEN:
                     logMessage("Bluetooth not connected")
                  case BluetoothService.STATE_NONE:
                     logMessage("Bluetooth not connected")
               }
            } else {
               // connected
               logMessage("Connected")
            }
         } else if (thatChanged == Item.frameBuffer) {
            sendFrameBuffer
         }
      ]
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

   override logMessage(String message) {
      mainText.text = message
   }
}