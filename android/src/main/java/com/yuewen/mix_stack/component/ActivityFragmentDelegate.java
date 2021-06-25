package com.yuewen.mix_stack.component;

import android.app.Activity;
import android.text.TextUtils;
import android.util.Log;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.ImageView;

import androidx.lifecycle.Lifecycle;

import com.yuewen.mix_stack.MixStackPlugin;
import com.yuewen.mix_stack.core.LifecycleNotifier;
import com.yuewen.mix_stack.core.MXStackService;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.utils.ReflectionUtil;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.DrawableSplashScreen;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.SplashScreenProvider;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugin.platform.PlatformPlugin;

/*******************************************************
 *
 * Created by julis.wang on 2020/09/18 13:40
 *
 * Description :
 *
 *  This delegate extract the common points of {@link MXFlutterFragment} and {@link MXFlutterActivity}
 *  These code for Single-engine scenario. so, Single-engine corresponds to more than one FlutterView.
 *  Our strategy is very simple: At the same moment, only one flutter content can be display for screen.
 *  If there are two FlutterView A and Flutter B, when FlutterView A in visible status that have attached
 *  Single-engine, another Flutter B must detached from Single-engine, and vice versa.
 *
 * History   :
 *
 *******************************************************/

class ActivityFragmentDelegate {
    private static final int DEFAULT_SPLASH_DURATION = 500;

    private Host host;
    private PlatformPlugin platformPlugin;
    private FlutterEngine flutterEngine;
    private FlutterTextureView flutterTextureView;
    private MXFlutterView flutterView;
    public FlutterUiDisplayListener flutterUiDisplayListener;

    public ActivityFragmentDelegate(Host host) {
        this.host = host;
        flutterEngine = MXStackService.getInstance().getFlutterEngine();
    }

    /**
     * Create FlutterView with FlutterTextureView,
     * Why not FlutterSurfaceView? We try to use FlutterSurfaceView, but get some terrible bug
     * about z-index, so we change the render mode to {@see io.flutter.embedding.android.RenderMode.texture}
     * Although it's performance not better than FlutterSurfaceView, but we have the better coding experience!!!
     *
     * @return
     */
    public MXFlutterView createFlutterView() {
        flutterTextureView = new FlutterTextureView(host.getActivity());
        flutterView = new MXFlutterView(host.getActivity(), flutterTextureView);
        flutterTextureView.setOpaque(false);
        checkFlutterView();
        return flutterView;
    }

    /**
     * New version of flutter have fixed this bug.
     * if flutter version below 1.22 may use this method to fix.
     * <p>
     * Also see: https://github.com/flutter/flutter/issues/53857
     */
    private void checkFlutterView() {
        try {
            Field f = flutterView.getClass().getSuperclass().getDeclaredField("renderSurface");
            f.setAccessible(true);
            Object object = f.get(flutterView);
            if (object == null) {
                f.set(flutterView, flutterTextureView);
            }
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }

    public void onAttach() {
        PlatformChannel platformChannel = flutterEngine.getPlatformChannel();
        platformPlugin = new PlatformPlugin(host.getActivity(), platformChannel);
        flutterEngine.getActivityControlSurface().attachToActivity(host.getActivity(), host.getLifecycle());
    }

    void onPostResume() {
        if (platformPlugin != null) {
            platformPlugin.updateSystemUiOverlays();
        }
    }

    void onDetach() {
        flutterEngine.getActivityControlSurface().detachFromActivity();
        if (platformPlugin != null) {
            platformPlugin.destroy();
            platformPlugin = null;
        }
    }

    void onStop() {
        FlutterRenderer renderer = flutterEngine.getRenderer();
        if (renderer == null) {
            return;
        }
        boolean isDisplayingFlutterUi = renderer.isDisplayingFlutterUi();
        if (!isDisplayingFlutterUi) {
            LifecycleNotifier.appIsPaused();
        }
    }

    void attachToFlutterEngine() {
        flutterView.attachToFlutterEngine(flutterEngine);
        flutterEngine.getLifecycleChannel().appIsResumed();
        FlutterRenderer renderer = flutterTextureView.getAttachedRenderer();
        if (renderer != null && flutterUiDisplayListener != null) {
            renderer.addIsDisplayingFlutterUiListener(flutterUiDisplayListener);
        }
    }

    void detachFromFlutterEngine() {
        FlutterRenderer renderer = flutterTextureView.getAttachedRenderer();
        if (renderer != null && flutterUiDisplayListener != null) {
            renderer.removeIsDisplayingFlutterUiListener(flutterUiDisplayListener);
        }
        flutterEngine.getLifecycleChannel().appIsPaused();

        //Exception: Attempt to invoke virtual method 'void android.view.Surface.release()' on a null object reference
        try {
            flutterView.detachFromFlutterEngine();
        } catch (Exception e) {
            String hostStr = "";
            if (host instanceof MXFlutterActivity) {
                hostStr = "Activity";
            } else if (host instanceof MXFlutterFragment) {
                hostStr = "Fragment";
            }
            Log.d("Mix-Stack", "flutterView detachFromFlutterEngine from " + hostStr + " fail,error:" + e.getMessage());
        }

    }

    /**
     * send the event to flutter that you can custom ur stack business which like:
     * Open three native activities(as A B C) , now in flutter page(D),  want to jump D->A.
     * A can use single task launch mode, but in flutter stack manage, you'd clear the stack of B C.
     * so, you can send event by this method.
     *
     * @param page
     * @param eventName
     * @param query
     */
    void sendEvent(IMXPage page, String eventName, Map<String, String> query) {
        String formatStr = "%s?addr=%s";
        String address = String.format(formatStr, page.rootRoute(), page.hashCode());
        Map<String, Object> eventQuery = new HashMap<>();
        eventQuery.put("addr", address);
        if (query != null) {
            eventQuery.put("query", query);
        }
        if (!TextUtils.isEmpty(eventName)) {
            eventQuery.put("event", eventName);
        }
        MixStackPlugin.invoke("pageEvent", eventQuery);
    }

    void handleEvent(IMXPage page, List<EventModel> eventModels) {
        if (eventModels == null || eventModels.isEmpty()) {
            return;
        }
        for (EventModel model : eventModels) {
            sendEvent(page, model.eventName, model.query);
        }
    }

    /**
     * Custom animation of splashScreen.
     *
     * @param contentContainer which container to place animation view.
     */
    protected void doSplashScreen(final ViewGroup contentContainer) {
        SplashScreenProvider splashScreenProvider;
        if (host != null) {
            splashScreenProvider = host;
        } else {
            return;
        }

        DrawableSplashScreen drawableSplashScreen = (DrawableSplashScreen) splashScreenProvider.provideSplashScreen();
        if (drawableSplashScreen == null) {
            return;
        }

        final DrawableSplashScreen.DrawableSplashScreenView splashScreenView
                = (DrawableSplashScreen.DrawableSplashScreenView)
                drawableSplashScreen.createSplashView(host.getActivity(), null);
        if (splashScreenView == null) {
            return;
        }

        splashScreenView.setScaleType(ImageView.ScaleType.CENTER);
        contentContainer.addView(splashScreenView);
        AlphaAnimation alphaAnimation = new AlphaAnimation(1.0f, 0.0f);
        alphaAnimation.setDuration(DEFAULT_SPLASH_DURATION);
        alphaAnimation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                contentContainer.removeView(splashScreenView);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
        splashScreenView.setAnimation(alphaAnimation);
        alphaAnimation.setRepeatCount(0);
        alphaAnimation.start();
    }

    /**
     * ensure flutter render got not empty surface.
     *
     * @return
     */
    boolean ensureSafeSurface() {
        try {
            FlutterRenderer flutterRenderer = flutterTextureView.getAttachedRenderer();
            if (flutterRenderer == null) { // maybe first time.
                return true;
            }
            Field surfaceField = ReflectionUtil.getField(flutterRenderer.getClass(), "surface");
            if (surfaceField == null) {
                return false;
            }
            Object surfaceObj = ReflectionUtil.getValue(surfaceField, flutterRenderer);
            if (surfaceObj == null) {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return true;
    }

    boolean isSurfaceAvailableForRendering() {
        try {
            FlutterTextureView flutterTextureView = getFlutterTextureView();
            Field isSurfaceAvailableForRenderingField = ReflectionUtil.getField(
                    flutterTextureView.getClass(), "isSurfaceAvailableForRendering");
            if (isSurfaceAvailableForRenderingField == null) {
                return false;
            }
            Object isSurfaceAvailableForRendering = ReflectionUtil.getValue(isSurfaceAvailableForRenderingField, flutterTextureView);
            return (boolean) isSurfaceAvailableForRendering;
        } catch (Exception e) {
            Log.e("mix_stack", "Exception:" + e.getMessage());
        }
        return false;
    }

    public FlutterTextureView getFlutterTextureView() {
        return flutterTextureView;
    }

    interface Host extends IMXPage, SplashScreenProvider {
        Lifecycle getLifecycle();

        Activity getActivity();

        FlutterView getFlutterView();

        /**
         * This method will call when flutterView has a determined height and width,
         * Cause flutter view inner operation, leads to system something wrong, eg. status bar color or height,
         * So if you want to do something about window layer, you'd better invoke ur methods at this method.
         */
        void onFlutterViewInitCompleted();
    }

    FlutterEngine getFlutterEngine() {
        return flutterEngine;
    }

    static class EventModel {
        String eventName;
        Map<String, String> query;

        public EventModel(String eventName, Map<String, String> query) {
            this.eventName = eventName;
            this.query = query;
        }
    }

}
