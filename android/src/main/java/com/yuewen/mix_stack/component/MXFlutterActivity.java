package com.yuewen.mix_stack.component;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.yuewen.mix_stack.core.LifecycleNotifier;
import com.yuewen.mix_stack.core.MXPageManager;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.interfaces.IMXPageManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/10 19:34
 *
 * Description : {@see ActivityFragmentDelegate}
 * History   :
 *
 *******************************************************/

public class MXFlutterActivity extends AppCompatActivity implements ActivityFragmentDelegate.Host, IMXPageManager {
    public static final String ROUTE = "route";
    private ActivityFragmentDelegate delegate;
    private String mRoute;
    private FlutterEngine flutterEngine;
    private MXFlutterView flutterView;
    private boolean onPauseLock = false; //ensure onFlutterViewInitCompleted did before onPause.
    private MXPageManager pageManager = new MXPageManager();
    private List<ActivityFragmentDelegate.EventModel> eventList = new ArrayList<>();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        delegate = new ActivityFragmentDelegate(this);
        flutterEngine = delegate.getFlutterEngine();


        Intent intent = getIntent();
        if (intent != null) {
            mRoute = intent.getStringExtra(ROUTE);
        }
        if (TextUtils.isEmpty(mRoute) && savedInstanceState != null) {
            mRoute = savedInstanceState.getString(ROUTE);
        }

        ViewGroup contentContainer = createContentView();
        setContentView(contentContainer);
        contentContainer.post(() -> delegate.doSplashScreen(contentContainer));
    }

    private ViewGroup createContentView() {
        FrameLayout contentContainer = new FrameLayout(this);
        FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT);
        contentContainer.setLayoutParams(layoutParams);
        flutterView = delegate.createFlutterView();
        contentContainer.addView(flutterView);
        return contentContainer;
    }


    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        if (!TextUtils.isEmpty(mRoute)) {
            outState.putString(ROUTE, mRoute);
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        delegate.onStop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        FlutterRenderer renderer = flutterEngine.getRenderer();
        renderer.removeIsDisplayingFlutterUiListener(delegate.flutterUiDisplayListener);
        if (pageManager != null) {
            pageManager.onDestroy();
        }
        delegate.fixInputMemoryLeak();
    }

    @Override
    protected void onResume() {
        super.onResume();
        delegate.onAttach();
        onPauseLock = false;
        LifecycleNotifier.appIsResumed();
        Log.v("Mix_stack", "onResume before onFlutterViewInitCompleted");
        flutterView.post(this::onFlutterViewInitCompleted);
        Log.v("Mix_stack", "onResume after onFlutterViewInitCompleted");
        delegate.handleEvent(this, eventList);
        eventList.clear();
    }

    @Override
    public void onPostResume() {
        super.onPostResume();
        delegate.onPostResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        onPauseLock = true;
        delegate.detachFromFlutterEngine();
        delegate.onDetach();
    }

    @Override
    public void onBackPressed() {
        if (pageManager != null) {
            pageManager.onBackPressed(result -> {
                boolean hasMorePage = (Boolean) ((HashMap) result).get("result");
                if (!hasMorePage) {
                    MXFlutterActivity.super.onBackPressed();
                }
            });
        } else {
            super.onBackPressed();
        }
    }

    @Override
    public FlutterView getFlutterView() {
        return flutterView;
    }

    /**
     * {@link ActivityFragmentDelegate#sendEvent(IMXPage, String, Map)}
     *
     * @param eventName
     * @param query
     */
    public void sendEvent(String eventName, Map<String, String> query) {
        if (delegate == null) {
            eventList.add(new ActivityFragmentDelegate.EventModel(eventName, query));
        } else {
            delegate.sendEvent(this, eventName, query);
        }
    }

    @Override
    public String rootRoute() {
        return mRoute;
    }

    @Override
    public void onPopNative() {
        finish();
        //Hook for subclasses.this is the default implement,
        //If you want to implement by yourself, please notice super has called finish();
    }

    @Override
    public MXPageManager getPageManager() {
        return pageManager;
    }

    @Nullable
    @Override
    public SplashScreen provideSplashScreen() {
        // No-op. Hook for subclasses.
        return null;
    }

    @Override
    public void onFlutterViewInitCompleted() {
        if (!onPauseLock) {
            pageManager.setCurrentShowPage(MXFlutterActivity.this);
            delegate.attachToFlutterEngine();
        } else {
            Log.v("Mix_stack", "didn't run ATE");
        }
        Log.v("Mix_stack", "onFlutterViewInitCompleted completed.");
    }

    @Override
    public Activity getActivity() {
        return this;
    }
}