package com.yuewen.mix_stack.utils;

import android.app.Activity;
import android.view.View;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.platform.app.InstrumentationRegistry;

import com.yuewen.mix_stack.core.MXPageManager;
import com.yuewen.mix_stack.core.MXStackService;
import com.yuewen.mix_stack.core.Whitebox;
import com.yuewen.mix_stack.interfaces.IMXPageManager;
import com.yuewen.mix_stack.model.AreaInsetsConfig;

import org.junit.Before;
import org.junit.Test;
import org.mockito.Mockito;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static org.junit.Assert.fail;

/*******************************************************
 *
 * Created by julis.wang on 2020/10/10 17:20
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class OverlayUtilsTest {
    MXPageManager mxPageManager;
    MXPageManager mxPageManagerWithConfig;
    View mockTabBar, mockTitle;
    MethodChannel.Result result;
    MethodCall methodCallNoArguments;
    MethodCall methodCall;

    @Before
    public void setUp() throws Exception {
        mockTabBar = Mockito.mock(View.class);
        mockTitle = Mockito.mock(View.class);
        result = Mockito.mock(MethodChannel.Result.class);
        mxPageManager = new MXPageManager();
        mxPageManagerWithConfig = new MXPageManager() {
            @Override
            public Map<String, View> overlayViewsForNames(List<String> overlayNames) {
                Map<String, View> map = new HashMap<>();
                map.put("tabBar", mockTabBar);
                map.put("title", mockTitle);
                return map;
            }

            @Override
            public List<String> overlayNames() {
                List<String> overlayNames = new ArrayList<>();
                overlayNames.add("tabBar");
                overlayNames.add("title");
                return overlayNames;
            }

            @Override
            public View overlayView(String viewName) {
                if ("tabBar".equals(viewName)) {
                    return mockTabBar;
                } else if ("title".equals(viewName)) {
                    return mockTitle;
                }
                return null;
            }

            @Override
            public AreaInsetsConfig ignoreAreaInsetsConfig() {
                AreaInsetsConfig config = new AreaInsetsConfig();
                config.addBottomIgnoreNames("tabBar");
                return config;
            }
        };

        Map<String, Object> arguments = new HashMap<>();
        Map<String, Object> config = new HashMap<>();
        Map<String, Object> tabBar = new HashMap<>();

        tabBar.put("hidden", 1);
        tabBar.put("alpha", 0.0);
        tabBar.put("animation", 1);
        config.put("11111-tabBar", tabBar);
        arguments.put("configs", config);
        arguments.put("addr", "21341");
        methodCallNoArguments = new MethodCall("method", null);
        methodCall = new MethodCall("method", arguments);
        Whitebox.setInternalState(MXStackService.getInstance(), "application", ApplicationProvider.getApplicationContext());
    }

    @Test
    public void configOverlaysAndOverlayNames() {

        try {
            OverlayUtils.configOverlays(methodCallNoArguments, result);
            OverlayUtils.overlayInfo(methodCall, result);
            OverlayUtils.overlayNames(methodCall, result);
        } catch (Exception e) {
            fail();
        }

        //Not implement IMXPageManager.
        try {
            InstrumentationRegistry.getInstrumentation().runOnMainSync(new Runnable() {
                @Override
                public void run() {
                    WeakReference<Activity> testActivity = new WeakReference<>(new Activity());
                    Whitebox.setInternalState(MXStackService.getInstance(), "sActivity", testActivity);
                    OverlayUtils.configOverlays(methodCall, result);
                    OverlayUtils.overlayInfo(methodCall, result);
                    OverlayUtils.overlayNames(methodCall, result);
                }
            });
        } catch (Exception e) {
            fail();
        }

        InstrumentationRegistry.getInstrumentation().runOnMainSync(new Runnable() {
            @Override
            public void run() {
                WeakReference<Activity> testActivity = new WeakReference<>(new TestActivity());
                Whitebox.setInternalState(MXStackService.getInstance(), "sActivity", testActivity);
                OverlayUtils.configOverlays(methodCall, result);
                OverlayUtils.overlayInfo(methodCall, result);
                OverlayUtils.overlayNames(methodCall, result);
            }
        });


    }

    @Test
    public void getOverlayTexture() {
        InstrumentationRegistry.getInstrumentation().runOnMainSync(new Runnable() {
            @Override
            public void run() {
                WeakReference<Activity> testActivity = new WeakReference<>(new TestActivity());
                Whitebox.setInternalState(MXStackService.getInstance(), "sActivity", testActivity);

                Map<String, Object> arguments = new HashMap<>();
                MethodCall overlayMethodCall = new MethodCall("method", arguments);
                int aHashCode = MXStackService.getCurrentActivity().hashCode();
                List<String> views = Arrays.asList(aHashCode + "-tabBar", aHashCode + "-title", "-error");
                arguments.put("names", views);
                OverlayUtils.getOverlayTexture(overlayMethodCall, result);
            }
        });
    }

    @Test
    public void doScreenCapture() {
//        List<View> views = Arrays.asList(mockTabBar, mockTitle);
//        InstrumentationRegistry.getInstrumentation().runOnMainSync(new Runnable() {
//            @Override
//            public void run() {
//                TestActivity testActivity = new TestActivity();
//                Window mockWindow = Mockito.mock(Window.class);
//                WeakReference<Activity> weakReference = new WeakReference<>(testActivity);
//                Whitebox.setInternalState(MXStackService.getInstance(), "sActivity", weakReference);
//                Whitebox.setInternalState(testActivity, "mWindow", mockWindow);
//                Mockito.when(mockWindow.getDecorView()).thenReturn(Mockito.mock(View.class));
//                OverlayUtils.doScreenCapture(testActivity, views);
//            }
//        });

    }

    private class TestActivity extends Activity implements IMXPageManager {

        @Override
        public MXPageManager getPageManager() {
            return mxPageManagerWithConfig;
        }
    }
}