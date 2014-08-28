package za.co.house4hack.h4hwatch.activities

import android.content.Intent
import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService

@AndroidActivity(R.layout.activity_main) class MainActivity {
   @OnCreate
   def void init() {
      // start watch service
      var intent = new Intent(this, BluetoothService)
      startService(intent)
      
      watchDisplay.onClickListener = [
         watchDisplay.invalidate
      ]
   }
}