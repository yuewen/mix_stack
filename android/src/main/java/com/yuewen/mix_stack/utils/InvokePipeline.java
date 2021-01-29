package com.yuewen.mix_stack.utils;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import com.yuewen.mix_stack.core.LifecycleNotifier;
import com.yuewen.mix_stack.interfaces.InvokeMethodListener;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/20 13:43
 *
 * Description :
 * History   :
 *
 *******************************************************/

public final class InvokePipeline {
    private static final String TAG = "InvokePipeline";
    private static final String TYPE_PAGE_POP = "popPage";
    private static final String TYPE_SET_PAGES = "setPages";
    private static final String TYPE_PAGE_EVENT = "pageEvent";
    private static final String TYPE_UPDATE_PAGES = "updatePages";
    private static final String TYPE_PAGE_HISTORY = "pageHistory";
    private static final String TYPE_UPDATE_LIFECYCLE = "updateLifecycle";
    private static final String TYPE_CONTAINER_UPDATE = "containerInfoUpdate";

    private static final int MAX_TRY_TIME = 20;
    private static final int DELAY_TIME = 250;

    private int TRY_TIME = 0;
    private volatile boolean isFlutterWorking = false;
    private volatile boolean isUpdateLifecycle = false;
    private static InvokePipeline instance;
    private WeakReference<MethodChannel> channel;

    public void setChannel(MethodChannel channel) {
        this.channel = new WeakReference<>(channel);
    }

    private InvokeQueryCache setPageCache = new InvokeQueryCache();

    public static InvokePipeline getInstance() {
        if (instance == null) {
            synchronized (InvokePipeline.class) {
                if (instance == null) {
                    instance = new InvokePipeline();
                }
            }
        }
        return instance;
    }

    public void invoke(final String method, Map<String, Object> query) {
        invokeWithListener(method, query, null);
    }

    public void invokeWithListener(final String method,
                                   Map<String, Object> query, InvokeMethodListener listener) {
        switch (method) {
            case TYPE_SET_PAGES:
                setPageCache.setInvokeQuery(query);
                doSetPages();
                break;
            case TYPE_PAGE_HISTORY:
            case TYPE_PAGE_POP:
            case TYPE_CONTAINER_UPDATE:
            case TYPE_PAGE_EVENT:
            case TYPE_UPDATE_LIFECYCLE:
            case TYPE_UPDATE_PAGES:
                handleMethodByType(method, query, listener);
                break;
        }
    }

    private void handleMethodByType(String type,
                                    Map<String, Object> query, InvokeMethodListener listener) {
        if (TYPE_PAGE_POP.equals(type)
                || TYPE_PAGE_HISTORY.equals(type)
                || TYPE_CONTAINER_UPDATE.equals(type)
                || TYPE_PAGE_EVENT.equals(type)
                || TYPE_UPDATE_LIFECYCLE.equals(type)
                || TYPE_UPDATE_PAGES.equals(type)) {
            realInvoke(type, query, listener);
            return;
        }

        if (isFlutterWorking) {
            invokeMethodByType(type);
        } else {
            invokeMethodByType(TYPE_SET_PAGES);
        }
    }

    private void invokeMethodByType(String type) {
        if (TYPE_SET_PAGES.equals(type)) {
            doSetPages();
        }
    }

    private void doSetPages() {
        if (!isUpdateLifecycle) {
            invoke(TYPE_UPDATE_LIFECYCLE, LifecycleNotifier.currentUpdateMap);
        }
        realInvoke(TYPE_SET_PAGES, setPageCache.getInvokeQuery(), result -> {
            isFlutterWorking = true;
            setPageCache.reset();
        });
    }


    private void realInvoke(final String method, Map<String, Object> query,
                            final InvokeMethodListener listener) {
        if (channel == null) {
            Log.d(TAG, method + " channel is not init.");
            return;
        }
        if (query == null) {
            Log.d(TAG, method + " query is empty.");
            return;
        }

        Map<String, Object> argumentsMap = new HashMap<>();
        argumentsMap.put("query", query);
        if (channel.get() == null) {
            Log.e(TAG, "can't get channel!");
            return;
        }
        channel.get().invokeMethod(method, argumentsMap, new MethodChannel.Result() {
            @Override
            public void success(@Nullable Object result) {
                if (listener != null) {
                    listener.onCompleted(result);
                }
                if (!isUpdateLifecycle && TYPE_UPDATE_LIFECYCLE.equals(method)) {
                    isUpdateLifecycle = true;
                }
                TRY_TIME = 0;
            }

            @Override
            public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                Log.e(TAG, "errorMessage:->" + errorMessage + "errorCode:" + errorCode);
            }

            @Override
            public void notImplemented() {
                if (TYPE_SET_PAGES.equals(method) && TRY_TIME <= MAX_TRY_TIME) {
                    trySetPages(method, query, listener);
                }
                Log.e(TAG, method + " -->notImplemented");
            }
        });
    }

    private void trySetPages(final String method, Map<String, Object> query,
                             final InvokeMethodListener listener) {
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            realInvoke(method, query, listener);
            TRY_TIME++;
        }, DELAY_TIME);
    }


    private static class InvokeQueryCache {
        volatile Map<String, Object> invokeQuery;

        Map<String, Object> getInvokeQuery() {
            return invokeQuery;
        }

        void setInvokeQuery(Map<String, Object> invokeQuery) {
            this.invokeQuery = invokeQuery;
        }

        void reset() {
            setInvokeQuery(null);
        }
    }

}
