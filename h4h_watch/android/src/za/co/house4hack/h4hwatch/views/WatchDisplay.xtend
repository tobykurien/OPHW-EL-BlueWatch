package za.co.house4hack.h4hwatch.views

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.util.AttributeSet
import android.view.View
import za.co.house4hack.h4hwatch.R

class WatchDisplay extends View {
   var Bitmap bitmap
   var Paint paint
   
   new(Context context) {
      super(context)
   }
   
   new(Context context, AttributeSet attrs) {
      super(context, attrs)
   }
   
   new(Context context, AttributeSet attrs, int defStyleAttr) {
      super(context, attrs, defStyleAttr)
   }
   
   override protected onAttachedToWindow() {
      super.onAttachedToWindow()
      var bd = resources.getDrawable(R.drawable.ic_launcher) as BitmapDrawable
      bitmap = bd.bitmap
      paint = new Paint
   }
   
   override protected onDraw(Canvas canvas) {
      super.onDraw(canvas)
      
      canvas.save
      
      canvas.drawBitmap(bitmap, 0, 0, paint)
      
      canvas.restore
   }
   
}