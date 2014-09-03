package za.co.house4hack.h4hwatch.activities

import android.os.Bundle
import android.preference.PreferenceActivity

class ModulePreferences extends PreferenceActivity {
   val public static EXTRA_XML_ID = "xml_id"
   
   override protected onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState)
      
      if (intent == null) finish
      else if (intent.getIntExtra(EXTRA_XML_ID, -1) == -1) finish
      else {
         addPreferencesFromResource(intent.getIntExtra(EXTRA_XML_ID, -1));
      }
   }
   
}
