package com.yuewen.mix_stack.utils;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.view.View;

import com.yuewen.mix_stack.core.MXStackService;

/*******************************************************
 *
 * Created by julis.wang on 2020/09/22 15:16
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class CommonUtils {
    public static float px2dip(float pxValue) {
        final float scale = MXStackService.getInstance().getApplication()
                .getResources().getDisplayMetrics().density;
        return pxValue / scale + 0.5f;
    }

    public static float getActivityWidth() {
        Activity activity = MXStackService.getCurrentActivity();
        Rect outRect = new Rect();
        activity.getWindow().getDecorView().getWindowVisibleDisplayFrame(outRect);
        return outRect.width();
    }

    public static float getActivityContentViewHeight() {
        Activity activity = MXStackService.getCurrentActivity();
        View decorView = activity.getWindow().getDecorView();
        View contentView = decorView.findViewById(android.R.id.content);
        return contentView.getHeight();
    }

    public static Bitmap screenShot(Activity activity) {
        View decorView = activity.getWindow().getDecorView();
        View contentView = decorView.findViewById(android.R.id.content);
        contentView.setDrawingCacheEnabled(true);
        contentView.buildDrawingCache();

        Rect outRect = new Rect();
        contentView.getWindowVisibleDisplayFrame(outRect);

        Bitmap bitmap = contentView.getDrawingCache();
        Bitmap newBitmap = Bitmap.createBitmap(bitmap,
                0, 0, bitmap.getWidth(), bitmap.getHeight());

        contentView.setDrawingCacheEnabled(false);
        contentView.destroyDrawingCache();

        return newBitmap;
    }
}
