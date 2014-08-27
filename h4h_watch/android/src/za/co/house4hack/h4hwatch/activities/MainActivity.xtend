package za.co.house4hack.h4hwatch.activities

import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.bluetooth.BluetoothHelper
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.logic.WatchState.Item
import za.co.house4hack.h4hwatch.logic.WatchState.OnStateChangedListener

@AndroidActivity(R.layout.activity_main) class MainActivity implements OnStateChangedListener {
   var BluetoothHelper btUtils = null;
   
   @OnCreate
   def void init() {
      btUtils = new BluetoothHelper(this)
   }
   
   override onDestroy() {
      btUtils.destroy
   }
   
   override onStateChanged(Item thatChanged) {
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
               btUtils.mService.write("H4h".getBytes)
            }
         }
      ]
   }

   def logMessage(String message) {
      mainText.text = message
   }
}