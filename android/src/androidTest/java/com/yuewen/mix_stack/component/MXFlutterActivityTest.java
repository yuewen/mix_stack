package com.yuewen.mix_stack.component;

import androidx.test.core.app.ActivityScenario;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.platform.app.InstrumentationRegistry;

import com.yuewen.mix_stack.core.MXStackService;

import org.junit.Before;
import org.junit.Test;

import io.flutter.embedding.engine.FlutterEngine;

/*******************************************************
 *
 * Created by julis.wang on 2020/10/12 15:14
 *
 * Description :
 * History   :
 *
 *******************************************************/
public class MXFlutterActivityTest {

    @Before
    public void setUp() throws Exception {

//        FlutterEngine flutterEngine = Mockito.mock(FlutterEngine.class);
//        Whitebox.setInternalState(MXStackService.getInstance(), "flutterEngine", flutterEngine);
//
//        Mockito.when(flutterEngine.getRenderer()).thenReturn(Mockito.mock(FlutterRenderer.class));

        InstrumentationRegistry.getInstrumentation().runOnMainSync(new Runnable() {
            @Override
            public void run() {
                MXStackService.init(ApplicationProvider.getApplicationContext());
            }
        });

        ActivityScenario<MXFlutterActivity> activityScenario
                = ActivityScenario.launch(MXFlutterActivity.class);

    }

    @Test
    public void onCreate() {
//        Espresso.onView(ViewMatchers.withId(R.id.fl_flutter_container))
//                .check(matches(not(isDisplayed())));    //是否不可见
    }

    @Test
    public void onDestroy() {
        FlutterEngine flutterEngine = new FlutterEngine(ApplicationProvider.getApplicationContext());
    }

    @Test
    public void onResume() {
    }

    @Test
    public void onPause() {
    }

    @Test
    public void onBackPressed() {
    }

    @Test
    public void getFlutterView() {
    }

    @Test
    public void rootRoute() {
    }

    @Test
    public void onPopNative() {
    }

    @Test
    public void getPageManager() {
    }

    @Test
    public void provideSplashScreen() {
    }
}