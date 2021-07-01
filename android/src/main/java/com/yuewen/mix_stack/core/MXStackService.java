package com.yuewen.mix_stack.core;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.interfaces.IMXPage;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/14 12:22
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class MXStackService {
    private static WeakReference<Activity> sActivity;
    private static MXStackService instance;
    private WeakReference<IMXPage> currentPage;
    private static int resumeActivityCount = 0;
    private Map<String, WeakReference<Activity>> pageActivityMap = new HashMap<>();

    private Application application;
    private FlutterEngine flutterEngine;

    public static MXStackService getInstance() {
        if (instance == null) {
            synchronized (MXStackService.class) {
                if (instance == null) {
                    instance = new MXStackService();
                }
            }
        }
        return instance;
    }

    public static Activity getCurrentActivity() {
        if (sActivity == null) {
            sActivity = new WeakReference<>(null);
        }
        return sActivity.get();
    }

    public Application getApplication() {
        return application;
    }

    public static void initWithFlutterEngine(Application application, FlutterEngine flutterEngine) {
        MXStackService.getInstance().application = application;
        if (flutterEngine == null) {
            flutterEngine = MXStackService.getInstance().createDefaultFlutterEngine(application);
        }
        MXStackService.getInstance().setFlutterEngine(flutterEngine);
        application.registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
            }

            @Override
            public void onActivityStarted(Activity activity) {
            }

            @Override
            public void onActivityResumed(Activity activity) {
                sActivity = new WeakReference<>(activity);
                if (resumeActivityCount == 0) {
                    LifecycleNotifier.appIsInactive();
                    LifecycleNotifier.appIsResumed();
                }
                resumeActivityCount++;
            }

            @Override
            public void onActivityPaused(Activity activity) {
            }

            @Override
            public void onActivityStopped(Activity activity) {
                resumeActivityCount--;
                if (resumeActivityCount == 0) {
                    LifecycleNotifier.appIsInactive();
                    LifecycleNotifier.appIsPaused();
                }
            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

            }

            @Override
            public void onActivityDestroyed(Activity activity) {
                if (resumeActivityCount == 0) {
                    LifecycleNotifier.appIsDetached();
                }
            }
        });
    }

    public static void init(Application application) {
        initWithFlutterEngine(application, null);
    }

    public IMXPage getCurrentPage() {
        return currentPage == null ? null : currentPage.get();
    }

    public void setCurrentPage(WeakReference<IMXPage> currentPage) {
        this.currentPage = currentPage;
        if (currentPage != null && currentPage.get() != null) {
            int hashCode = currentPage.get().hashCode();
            pageActivityMap.put(String.valueOf(hashCode), sActivity);
        }
    }

    public WeakReference<Activity> getActivityByHashCode(String hashCode) {
        return pageActivityMap.get(hashCode);
    }

    private void setFlutterEngine(FlutterEngine flutterEngine) {
        this.flutterEngine = flutterEngine;
    }

    private FlutterEngine createDefaultFlutterEngine(Application application) {
        FlutterEngine flutterEngine = new FlutterEngine(application);
        flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
        );
        return flutterEngine;
    }

    public FlutterEngine getFlutterEngine() {
        return flutterEngine;
    }

    public void forceRefresh() {
        List<WeakReference<IMXPage>> pages = MXStackInternal.getInstance().getAllSavePages();
        for (WeakReference<IMXPage> page : pages) {
            if (page == null || page.get() == null || !(page.get() instanceof MXFlutterFragment)) {
                continue;
            }
            MXFlutterFragment flutterFragment = (MXFlutterFragment) page.get();
            flutterFragment.setDirty(true);
        }
    }

    public List<MXFlutterFragment> getAllFlutterFragment() {
        return getContainer(MXFlutterFragment.class);
    }

    public List<MXFlutterActivity> getAllFlutterActivity() {
        return getContainer(MXFlutterActivity.class);
    }

    private <T extends IMXPage> List<T> getContainer(Class<T> clazz) {
        List<T> components = new CopyOnWriteArrayList<>();
        List<WeakReference<IMXPage>> pages = MXStackInternal.getInstance().getAllSavePages();
        for (WeakReference<IMXPage> page : pages) {
            if (page == null || page.get() == null || !clazz.isInstance(page.get())) {
                continue;
            }
            T component = clazz.cast(page.get());
            components.add(component);
        }
        return components;
    }

    public void destroy() {
        MXStackInternal.getInstance().destroy();
    }


}
