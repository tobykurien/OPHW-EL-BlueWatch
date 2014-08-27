package za.co.house4hack.h4hwatch.activities

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
         var bitmap = watchDisplay.getDrawingCache(false)
         var bytes = newByteArrayOfSize(1025)
         bytes.set(0, 0x1 as byte) // start frame buffer command
         for (var i=1; i < bytes.length; i++) {
            bytes.set(i, 0xAA as byte)
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