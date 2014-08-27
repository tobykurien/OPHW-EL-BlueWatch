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
         // start sending frame buffer
         var bitmap = watchDisplay.bitmap
         var bytes = newByteArrayOfSize(128*64/8 + 1)
         bytes.set(0, 0x1 as byte) // start frame buffer command
         var float[] hsv = newFloatArrayOfSize(3)

         // convert bitmap to monochrome frame buffer         
         for (var i=1; i < bytes.length; i++) {
            var int b = 0
            for (var x=7; x >= 0; x--) {
               var row = (i / 128) as int               
               var pix = bitmap.getPixel((i-1) % 128, x + (row * 7))
               Color.colorToHSV(pix, hsv)
               b = if (hsv.get(2) > 0.3) b.bitwiseOr(1 << x) else b.bitwiseAnd((0x1 << x).bitwiseNot) 
            }
            bytes.set(i, b as byte)
         }
                        
         btUtils.mService.write(bytes)
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
         }
      ]
   }

   override logMessage(String message) {
      mainText.text = message
   }
}