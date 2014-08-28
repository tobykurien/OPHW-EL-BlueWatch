package za.co.house4hack.h4hwatch.activities

import android.content.Intent
import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import za.co.house4hack.h4hwatch.R
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.views.WatchDisplay

@AndroidActivity(R.layout.activity_main) class MainActivity {
   @OnCreate
   def void init() {
      // start watch service
      var intent = new Intent(this, BluetoothService)
      startService(intent)

      val watchDisplay = new WatchDisplay(this)
      preview.setImageBitmap(watchDisplay.bitmap)
      
      preview.onClickListener = [
         watchDisplay.invalidate
         preview.setImageBitmap(watchDisplay.bitmap)
      ]           
   }
}