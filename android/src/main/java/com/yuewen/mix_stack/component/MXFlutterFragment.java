package com.yuewen.mix_stack.component;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.yuewen.mix_stack.core.LifecycleNotifier;
import com.yuewen.mix_stack.interfaces.IMXPage;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/27 10:19
 *
 * Description : {@see ActivityFragmentDelegate}
 * History   :
 *
 *******************************************************/

public class MXFlutterFragment extends Fragment implements ActivityFragmentDelegate.Host {
    public static final String ROUTE = "route";
    //used for fragment that to judge if is in root page of flutter in this fragment.
    //false -> in root page, true is not.
    public boolean isFlutterCanPop = true;
    private boolean isFirstTimeRenderFlutter = true;
    private boolean isDirty = false;
    private boolean onPauseLock = false; //ensure onFlutterViewInitCompleted did before onPause.

    private String pageRoute;
    private MXFlutterView flutterView;
    private Bitmap preBitmap;
    private ImageView screenshotView;
    private Activity mActivity;
    private ActivityFragmentDelegate delegate;
    private OnFirstShowListener firstShowListener;
    private List<ActivityFragmentDelegate.EventModel> eventList = new ArrayList<>();

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        mActivity = (Activity) context;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        delegate = new ActivityFragmentDelegate(this);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        FrameLayout.LayoutParams matchParentParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT);

        FrameLayout contentContainer = new FrameLayout(mActivity);
        contentContainer.setLayoutParams(matchParentParams);

        flutterView = delegate.createFlutterView();
        screenshotView = new ImageView(mActivity);
        contentContainer.addView(flutterView, matchParentParams);
        contentContainer.addView(screenshotView, matchParentParams);
        contentContainer.post(() -> delegate.doSplashScreen(contentContainer));
        initFlutterUiDisplayListener();
        return contentContainer;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        //In order to be compatible with the top padding, when fragment in activity
        //only first fragment will response View.dispatchApplyWindowInsets.
        //so invoke flutterView.requestApplyInsets() by ourselves that notice view to applyInsets
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            flutterView.requestApplyInsets();
        }
    }

    private void initFlutterUiDisplayListener() {
        delegate.flutterUiDisplayListener = new FlutterUiDisplayListener() {
            @Override
            public void onFlutterUiDisplayed() {
                if (isFirstTimeRenderFlutter && firstShowListener != null) {
                    isFirstTimeRenderFlutter = false;
                    firstShowListener.onFirstShow();
                }
                if (preBitmap != null) {
                    preBitmap.recycle();
                    preBitmap = null;
                }
                screenshotView.setImageBitmap(null);
                FlutterTextureView textureView = delegate.getFlutterTextureView();
                if (textureView == null) {
                    return;
                }
                textureView.setVisibility(View.VISIBLE);
            }

            @Override
            public void onFlutterUiNoLongerDisplayed() {

            }
        };
    }

    @Override
    public void onResume() {
        super.onResume();
        LifecycleNotifier.appIsResumed();
        if (preBitmap != null) {
            screenshotView.setImageBitmap(preBitmap);
        }
        if (!isHidden()) {
            delegate.onAttach();
            onResumeToAttach();
            onPauseLock = false;
        }
    }

    private void onResumeToAttach() {
        flutterView.post(this::onFlutterViewInitCompleted);
        delegate.onPostResume();
        delegate.handleEvent(this, eventList);
        eventList.clear();
    }

    @Override
    public void onPause() {
        super.onPause();
        if (!isHidden()) {
            onPauseLock = true;
        }
        savePreBitmap();
        screenshotView.setImageBitmap(preBitmap);
        delegate.detachFromFlutterEngine();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        delegate.detachFromFlutterEngine();
        delegate.fixInputMemoryLeak();
        if (preBitmap != null) {
            preBitmap.recycle();
            preBitmap = null;
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        delegate.onDetach();
    }

    @Override
    public void onHiddenChanged(boolean hidden) {
        super.onHiddenChanged(hidden);
        if (hidden) {
            savePreBitmap();
            LifecycleNotifier.appIsPaused();
            delegate.detachFromFlutterEngine();
        } else {
            onPauseLock = false;
            LifecycleNotifier.appIsResumed();
            screenshotView.setImageBitmap(preBitmap);
            flutterView.post(this::onFlutterViewInitCompleted);
        }
    }


    @Override
    public String rootRoute() {
        if (TextUtils.isEmpty(pageRoute)) {
            Bundle bundle = getArguments();
            if (bundle == null) {
                this.pageRoute = "/";
            } else {
                this.pageRoute = bundle.getString(ROUTE);
            }
        }
        return pageRoute;
    }

    @Override
    public void onPopNative() {
        mActivity.finish();
    }

    @Nullable
    @Override
    public SplashScreen provideSplashScreen() {
        return null;
    }

    public void setOnFlutterFirstShowListener(OnFirstShowListener firstShowListener) {
        this.firstShowListener = firstShowListener;
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
    public void onStop() {
        super.onStop();
        if (!isHidden()) {
            delegate.onStop();
        }
    }

    public boolean isDirty() {
        return isDirty;
    }

    public void setDirty(boolean dirty) {
        isDirty = dirty;
    }

    @Override
    public FlutterView getFlutterView() {
        return flutterView;
    }

    @Override
    public void onFlutterViewInitCompleted() {
        if (!onPauseLock) {
            delegate.attachToFlutterEngine();
            forceRefresh();
        }
    }

    private void savePreBitmap() {
        FlutterRenderer flutterRenderer = delegate.getFlutterEngine().getRenderer();
        if (flutterRenderer != null) {
            preBitmap = flutterRenderer.getBitmap();
        }
    }

    /**
     * Force refresh the flutterView when surface available for rendering,
     * must ensure that {@see FlutterTextureView#connectSurfaceToRenderer()}
     */
    private void forceRefresh() {
        if (isDirty) {
            FlutterTextureView textureView = delegate.getFlutterTextureView();
            if (textureView == null) {
                return;
            }
            FlutterRenderer renderer = textureView.getAttachedRenderer();
            if (renderer == null) {
                return;
            }
            if (delegate.isSurfaceAvailableForRendering() && delegate.ensureSafeSurface()) {
                renderer.surfaceChanged(flutterView.getWidth(), flutterView.getHeight());
                textureView.setVisibility(View.INVISIBLE);
            }
        }
        isDirty = false;
    }


    public interface OnFirstShowListener {
        void onFirstShow();
    }

}