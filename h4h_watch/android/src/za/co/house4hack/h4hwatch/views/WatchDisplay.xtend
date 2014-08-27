package za.co.house4hack.h4hwatch.views

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
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
      paint.color = Color.WHITE
   }
   
   override protected onDraw(Canvas canvas) {
      super.onDraw(canvas)
      
      canvas.save
      canvas.drawBitmap(bitmap, 0, 0, paint)
      canvas.drawLine(0, 0, 128, 64, paint)
      canvas.restore
   }
   
   def public Bitmap getBitmap() {
      //Define a bitmap with the same size as the view
      var Bitmap returnedBitmap = Bitmap.createBitmap(getWidth(), getHeight(),Bitmap.Config.ARGB_8888);
      //Bind a canvas to it
      var Canvas canvas = new Canvas(returnedBitmap);
      //Get the view's background
      var Drawable bgDrawable = getBackground();
      if (bgDrawable!=null) { 
            //has background drawable, then draw it on the canvas
            bgDrawable.draw(canvas);
      } else { 
            //does not have background drawable, then draw white background on the canvas
            canvas.drawColor(Color.WHITE);
      }
      
      // draw the view on the canvas
      draw(canvas);
      
      //return the bitmap
      return returnedBitmap;
   }
}