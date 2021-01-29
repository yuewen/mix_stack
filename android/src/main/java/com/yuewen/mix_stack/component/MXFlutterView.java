package com.yuewen.mix_stack.component;

import android.content.Context;
import android.graphics.Insets;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.util.Log;
import android.view.MotionEvent;
import android.view.TextureView;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsets.Builder;

import androidx.annotation.NonNull;

import com.yuewen.mix_stack.utils.ReflectionUtil;
import com.yuewen.mix_stack.utils.StatusBarUtil;

import java.lang.reflect.Field;

import io.flutter.embedding.android.AndroidTouchProcessor;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.view.AccessibilityBridge;

/*******************************************************
 *
 * Created by julis.wang on 2020/11/04 10:08
 *
 * Description : Wrapper Flutter view,override method {@see MXFlutterFragment.onViewCreated}
 * History   :
 *
 *******************************************************/

public class MXFlutterView extends FlutterView {
    private FlutterTextureView flutterTextureView;

    private AccessibilityBridge.OnAccessibilityChangeListener accessibilityChangeListener;

    public MXFlutterView(@NonNull Context context) {
        super(context);
    }

    public MXFlutterView(@NonNull Context context, @NonNull FlutterTextureView flutterTextureView) {
        super(context, flutterTextureView);
        this.flutterTextureView = flutterTextureView;
        hookFlutterTextureViewListener();
        initAccessibilityChangeListener();
    }

    /**
     * hook FlutterAccessibilityChangeListener, ensure {@link FlutterView resetWillNotDraw(boolean, boolean)}
     * have not null flutterEngine. In background flutter engine will detach.
     */
    private void initAccessibilityChangeListener() {
        AccessibilityBridge.OnAccessibilityChangeListener listener = getFlutterAccessibilityChangeListener();
        if (listener == null) {
            return;
        }
        accessibilityChangeListener = (isAccessibilityEnabled, isTouchExplorationEnabled) -> {
            if (getFlutterEngine() != null) {
                listener.onAccessibilityChanged(isAccessibilityEnabled, isTouchExplorationEnabled);
                Log.d("Mix_stack", "onAccessibilityChanged:" + isAccessibilityEnabled + "," + isTouchExplorationEnabled);
            } else {
                //TODO: if never see this log. delete initAccessibilityChangeListener method.
                Log.d("Mix_stack", "onAccessibilityChanged flutter engine is null.");
            }
        };
    }

    @Override
    public void attachToFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.attachToFlutterEngine(flutterEngine);
        hookFlutterAccessibilityChangeListener();
    }

    private void hookFlutterAccessibilityChangeListener() {
        AccessibilityBridge accessibilityBridge = getAccessibilityBridge();
        accessibilityBridge.setOnAccessibilityChangeListener(accessibilityChangeListener);
    }

    private FlutterEngine getFlutterEngine() {
        Field flutterEngineField = ReflectionUtil.getField(getClass().getSuperclass(), "flutterEngine");
        Object flutterEngineObj = ReflectionUtil.getValue(flutterEngineField, this);
        if (flutterEngineObj == null) {
            return null;
        } else {
            return (FlutterEngine) flutterEngineObj;
        }
    }

    private AccessibilityBridge.OnAccessibilityChangeListener getFlutterAccessibilityChangeListener() {
        Field onAccessibilityField = ReflectionUtil.getField(getClass().getSuperclass(), "onAccessibilityChangeListener");
        Object onAccessibilityObj = ReflectionUtil.getValue(onAccessibilityField, this);
        if (onAccessibilityObj == null) {
            return null;
        } else {
            return (AccessibilityBridge.OnAccessibilityChangeListener) onAccessibilityObj;
        }
    }


    /**
     * hook FlutterTextureViewListener, ensure {@link FlutterTextureView onSizeChanged(int, int, int, int)}
     * have not empty surface.
     */
    private void hookFlutterTextureViewListener() {
        TextureView.SurfaceTextureListener surfaceTextureListener = getSurfaceTextureListener();
        if (surfaceTextureListener == null) {
            return;
        }
        flutterTextureView.setSurfaceTextureListener(
                new TextureView.SurfaceTextureListener() {

                    @Override
                    public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
                        surfaceTextureListener.onSurfaceTextureAvailable(surface, width, height);
                    }

                    @Override
                    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
                        if (ensureSafeSurface()) {
                            surfaceTextureListener.onSurfaceTextureSizeChanged(surface, width, height);
                        }
                    }

                    @Override
                    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                        return surfaceTextureListener.onSurfaceTextureDestroyed(surface);
                    }

                    @Override
                    public void onSurfaceTextureUpdated(SurfaceTexture surface) {
                        surfaceTextureListener.onSurfaceTextureUpdated(surface);
                    }
                });

    }

    private TextureView.SurfaceTextureListener getSurfaceTextureListener() {
        Field surfaceListenerField = ReflectionUtil.getField(flutterTextureView.getClass(), "surfaceTextureListener");
        Object surfaceListenerObj = ReflectionUtil.getValue(surfaceListenerField, flutterTextureView);
        if (surfaceListenerObj == null) {
            return null;
        } else {
            return (TextureView.SurfaceTextureListener) surfaceListenerObj;
        }
    }

    /**
     * ensure flutter render got not empty surface.
     *
     * @return
     */
    private boolean ensureSafeSurface() {
        try {
            FlutterRenderer flutterRenderer = flutterTextureView.getAttachedRenderer();
            if (flutterRenderer == null) { // maybe first time.
                return true;
            }
            Field surfaceField = ReflectionUtil.getField(flutterRenderer.getClass(), "surface");
            Object surfaceObj = ReflectionUtil.getValue(surfaceField, flutterRenderer);
            if (surfaceObj == null) {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    /**
     * This problem also in {@link io.flutter.embedding.android.FlutterView}
     *
     * <p>
     * see https://github.com/alibaba/flutter_boost/pull/760
     */
    @Override
    public boolean onTouchEvent(@NonNull MotionEvent event) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            requestUnbufferedDispatch(event);
        }
        AndroidTouchProcessor androidTouchProcessor = getAndroidTouchProcessor();
        if (androidTouchProcessor == null) {
            return super.onTouchEvent(event);
        }
        return getAndroidTouchProcessor().onTouchEvent(event);
    }

    private AndroidTouchProcessor getAndroidTouchProcessor() {
        try {
            Field touchProcessorField = ReflectionUtil.getField(getClass().getSuperclass(), "androidTouchProcessor");
            Object touchProcessorObj = ReflectionUtil.getValue(touchProcessorField, this);
            return (AndroidTouchProcessor) touchProcessorObj;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private AccessibilityBridge getAccessibilityBridge() {
        try {
            Field accessibilityBridge = ReflectionUtil.getField(getClass().getSuperclass(), "accessibilityBridge");
            Object accessibilityObj = ReflectionUtil.getValue(accessibilityBridge, this);
            return (AccessibilityBridge) accessibilityObj;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public boolean checkInputConnectionProxy(View view) {
        if (view == null) {
            return false;
        }
        return super.checkInputConnectionProxy(view);
    }

    @Override
    public boolean onHoverEvent(@NonNull MotionEvent event) {
        if (getAccessibilityBridge() == null) {
            return false;
        }
        return super.onHoverEvent(event);
    }

    @Override
    public WindowInsets dispatchApplyWindowInsets(WindowInsets insets) {
        if (insets != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                final int top = insets.getSystemWindowInsetTop();
                final int newTop = StatusBarUtil.getStatusBarHeight();
                if (top != newTop) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        Insets newInsets = Insets.of(
                                insets.getSystemWindowInsetLeft(),
                                newTop,
                                insets.getSystemWindowInsetRight(),
                                insets.getSystemWindowInsetBottom());
                        insets = new Builder(insets).setSystemWindowInsets(newInsets).build();
                    } else {
                        insets = insets.replaceSystemWindowInsets(
                                insets.getSystemWindowInsetLeft(),
                                newTop,
                                insets.getSystemWindowInsetRight(),
                                insets.getSystemWindowInsetBottom());
                    }
                }
            }
        }
        return super.dispatchApplyWindowInsets(insets);
    }

}
