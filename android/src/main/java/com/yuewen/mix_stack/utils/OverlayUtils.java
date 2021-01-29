package com.yuewen.mix_stack.utils;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;

import com.yuewen.mix_stack.BuildConfig;
import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.core.MXStackService;
import com.yuewen.mix_stack.core.PageOverlayConfig;
import com.yuewen.mix_stack.interfaces.IMXPageManager;
import com.yuewen.mix_stack.model.MXViewConfig;

import java.io.ByteArrayOutputStream;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/14 16:08
 *
 * Description :
 * History   :
 *
 *******************************************************/

public final class OverlayUtils {
    private static final String TAG = "OverlayUtils";

    public static Bitmap doScreenCapture(Activity activity, List<View> maskViews) {
        Bitmap bitmap = CommonUtils.screenShot(activity);

        bitmap = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), Bitmap.Config.ARGB_4444);
        Canvas canvas = new Canvas(bitmap);
        for (View view : maskViews) {
            drawMaskToCanvas(canvas, view);
        }
        Bitmap newBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight());
        bitmap.recycle();
        return newBitmap;
    }


    private static void drawMaskToCanvas(Canvas wholeCanvas, View maskView) {
        Bitmap maskBitmap = viewToBitmap(maskView);

        int[] location = new int[2];
        maskView.getLocationInWindow(location);

        Paint paint = new Paint();
        wholeCanvas.drawBitmap(maskBitmap, location[0], location[1], paint);
        maskBitmap.recycle();
    }


    private static Bitmap viewToBitmap(View v) {
        v.setDrawingCacheEnabled(true);
        v.buildDrawingCache();

        Bitmap bitmap = v.getDrawingCache();
        Bitmap newBitmap = Bitmap.createBitmap(bitmap,
                0, 0, bitmap.getWidth(), bitmap.getHeight());

        v.setDrawingCacheEnabled(false);
        bitmap.recycle();
        return newBitmap;
    }

    @SuppressWarnings("unchecked")
    public static void configOverlays(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "configOverlays");
        if (call.arguments == null) {
            result.success(null);
            return;
        }
        Activity currentActivity = getSafeActivity(call);
        if (!(currentActivity instanceof IMXPageManager)) {
            return;
        }
        IMXPageManager mxStack = (IMXPageManager) currentActivity;
        PageOverlayConfig pageOverlayConfig = mxStack.getPageManager();

        Map<String, MXViewConfig> configMap = new HashMap<>();
        Map<String, MXViewConfig> query = (Map) ((HashMap) call.arguments).get("configs");
        for (Map.Entry<String, MXViewConfig> entry : query.entrySet()) {
            String key = entry.getKey();
            Map<String, Object> value = (Map) entry.getValue();
            boolean hidden = (Integer) value.get("hidden") == 1;
            float alpha = ((Double) value.get("alpha")).floatValue();
            boolean animation = (Integer) value.get("animation") == 1;
            MXViewConfig config = new MXViewConfig(hidden, alpha, animation);
            configMap.put(key.split("-")[1], config);
        }

        pageOverlayConfig.configOverlay(configMap);
        result.success(null);
    }

    @SuppressWarnings("unchecked")
    public static void overlayInfo(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "overlayInfos");
        Map<String, Map<String, Object>> viewInfos = new HashMap<>();
        Activity currentActivity = getSafeActivity(call);
        if (!(currentActivity instanceof IMXPageManager) || call.arguments == null) {
            result.success(viewInfos);
            return;
        }

        PageOverlayConfig pageOverlayConfig = ((IMXPageManager) currentActivity).getPageManager();
        if (pageOverlayConfig == null) {
            result.error("-1", "PageOverlayConfig not set.", null);
            return;
        }
        List<String> names = (List<String>) ((HashMap) call.arguments).get("names");
        Map<String, View> viewsForNames = pageOverlayConfig.overlayViewsForNames(names);
        for (String name : viewsForNames.keySet()) {
            Map<String, Object> viewInfo = new HashMap<>();
            View view = viewsForNames.get(name);
            if (view == null) {
                continue;
            }
            viewInfo.put("x", CommonUtils.px2dip(view.getX()));
            viewInfo.put("y", CommonUtils.px2dip(view.getY()));
            viewInfo.put("width", CommonUtils.px2dip(view.getWidth()));
            viewInfo.put("height", CommonUtils.px2dip(view.getHeight()));
            viewInfo.put("hidden", view.getVisibility() != View.VISIBLE);
            viewInfos.put(name, viewInfo);
        }
        result.success(viewInfos);
    }

    @SuppressWarnings("unchecked")
    public static void getOverlayTexture(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "getOverlayTexture");
        if (call.arguments == null) {
            result.success(null);
            return;
        }

        List<String> query = (List<String>) ((HashMap) call.arguments).get("names");
        if (query == null) {
            result.success(null);
            return;
        }
        Activity currentActivity = getSafeActivity(call);
        if (!(currentActivity instanceof IMXPageManager)) {
            result.success(null);
            return;
        }

        List<String> names = checkDataSafely(query, currentActivity);
        if (names.size() != query.size()) {
            result.success(null);
            return;
        }
        IMXPageManager mxStack = (IMXPageManager) currentActivity;
        PageOverlayConfig pageOverlayConfig = mxStack.getPageManager();
        pageOverlayConfig.overlayViewsForNames(names);
        List<View> viewList = new ArrayList<>(pageOverlayConfig.overlayViewsForNames(names).values());
        List<View> filterViewList = getUnHiddenView(viewList);

        if (filterViewList.isEmpty()) {
            return;
        }

        Bitmap bitmap = OverlayUtils.doScreenCapture(currentActivity, filterViewList);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 1, baos);
        result.success(baos.toByteArray());

        bitmap.recycle();
        baos.reset();
    }

    /**
     * When flutter wants to #getOverlayTexture #overlayInfo() and so on.
     * We will get host's config, but it's not on the same time series,
     * so we need to get the correct host by arguments of (#address)
     *
     * @param call will get the hashcode of page's.
     * @return address's fragment of container Activity.
     */
    private static Activity getSafeActivity(MethodCall call) {
        String address = call.argument("addr");
        if (TextUtils.isEmpty(address)) {
            address = "";
        }
        Activity currentActivity;

        List<MXFlutterActivity> flutterActivities = MXStackService.getInstance().getAllFlutterActivity();
        for (Activity a : flutterActivities) {
            if (address.equals(String.valueOf(a.hashCode()))) {
                currentActivity = a;
                return currentActivity;
            }
        }

        List<MXFlutterFragment> flutterFragmentList = MXStackService.getInstance().getAllFlutterFragment();
        for (MXFlutterFragment f : flutterFragmentList) {
            String fHashCode = String.valueOf(f.hashCode());
            if (address.equals(fHashCode)) {
                currentActivity = f.getActivity();
                if (currentActivity == null) {
                    WeakReference<Activity> wActivity = MXStackService.getInstance().getActivityByHashCode(fHashCode);
                    if (wActivity != null) {
                        currentActivity = wActivity.get();
                    }
                }
                if (currentActivity == null) {
                    currentActivity = MXStackService.getCurrentActivity(); // the last solution.
                }
                return currentActivity;
            }
        }
        String errorStr = "Can not found the activity of ->" + address;
        if (BuildConfig.DEBUG) {
            throw new RuntimeException(errorStr);
        } else {
            currentActivity = MXStackService.getCurrentActivity();
            Log.e("Mix_stack", errorStr);
        }
        return currentActivity;
    }

    private static List<View> getUnHiddenView(List<View> viewList) {
        List<View> unHiddenViewList = new ArrayList<>();
        for (View view : viewList) {
            if (view.getVisibility() == View.VISIBLE && view.getAlpha() == 1.0f) {
                unHiddenViewList.add(view);
            }
        }
        return unHiddenViewList;
    }

    private static List<String> checkDataSafely(List<String> query, Activity currentActivity) {
        List<String> names = new ArrayList<>();
        if (currentActivity == null) {
            return new ArrayList<>();
        }
        for (String name : query) {
            String[] nameSplit = name.split("-");
            if (nameSplit.length < 2) {
                Log.e(TAG, "this name[" + name + " ]should be a couple");
                break;
            }
            String currentActivityHashCode = String.valueOf(Math.abs(currentActivity.hashCode()));
            if (!currentActivityHashCode.equals(nameSplit[0])) {
                Log.e(TAG, "Different activity.");
                break;
            }
            names.add(nameSplit[1]);
        }
        return names;
    }


    public static void overlayNames(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "overlayNames");
        List<String> names = new ArrayList<>();
        Activity currentActivity = getSafeActivity(call);
        if (currentActivity instanceof IMXPageManager) {
            IMXPageManager mxStack = (IMXPageManager) currentActivity;
            PageOverlayConfig pageOverlayConfig = mxStack.getPageManager();
            if (pageOverlayConfig == null) {
                return;
            }
            List<String> overlayNames = pageOverlayConfig.overlayNames();
            for (String name : overlayNames) {
                names.add(String.format("%s-%s", Math.abs(currentActivity.hashCode()), name));
            }
        }
        result.success(names);
    }


}
