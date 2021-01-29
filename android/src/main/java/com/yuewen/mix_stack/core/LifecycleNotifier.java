package com.yuewen.mix_stack.core;

import com.yuewen.mix_stack.utils.InvokePipeline;

import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;

/*******************************************************
 *
 * Created by julis.wang on 2020/12/29 13:57
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class LifecycleNotifier {
    private static final String TAG = "LifecycleNotifier";

    public static final String INACTIVE = "inactive";
    public static final String RESUME = "resumed";
    public static final String PAUSED = "paused";
    public static final String DETACHED = "detached";
    public static Map<String, Object> currentUpdateMap = new HashMap<>();

    public static void appIsInactive() {
        Log.d(TAG, "Sending AppLifecycleState.inactive message.");
        updateLifecycle(INACTIVE);
    }

    public static void appIsResumed() {
        Log.d(TAG, "Sending AppLifecycleState.resumed message.");
        updateLifecycle(RESUME);
    }

    public static void appIsPaused() {
        Log.d(TAG, "Sending AppLifecycleState.paused message.");
        updateLifecycle(PAUSED);
    }

    public static void appIsDetached() {
        Log.d(TAG, "Sending AppLifecycleState.detached message.");
        updateLifecycle(DETACHED);
    }

    private static void updateLifecycle(String type) {
        Map<String, Object> queryMap = new HashMap<>();
        queryMap.put("lifecycle", type);
        currentUpdateMap = queryMap;
        InvokePipeline.getInstance().invoke("updateLifecycle", queryMap);
    }
}
