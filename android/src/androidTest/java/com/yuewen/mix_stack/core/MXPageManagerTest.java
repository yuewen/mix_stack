package com.yuewen.mix_stack.core;

import android.app.Activity;
import android.view.View;

import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.model.AreaInsetsConfig;

import org.junit.Before;
import org.junit.Test;
import org.mockito.Mockito;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

/*******************************************************
 *
 * Created by julis.wang on 2020/10/10 15:37
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class MXPageManagerTest {
    MXPageManager mxPageManager;
    MXPageManager mxPageManagerWithConfig;
    View mockTabBar, mockTitle;

    @Before
    public void setUp() throws Exception {
        mockTabBar = Mockito.mock(View.class);
        mockTitle = Mockito.mock(View.class);

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
    }


    @Test
    public void onDestroy() {
        mxPageManager.onDestroy();
    }

    @Test
    public void onResume() {
        mxPageManager.onResume();
    }

    @Test
    public void setCurrentShowPage() {
        try {
            mxPageManager.setCurrentShowPage(null);
        } catch (Exception e) {
            fail();
        }

        IMXPage page = Mockito.mock(IMXPage.class);
        mxPageManager.setCurrentShowPage(page);
        Object currentPage = Whitebox.getInternalState(mxPageManager, "currentPage");
        assertEquals(page, currentPage);
    }

    @Test
    public void onFlutterFirstShow() {
        mxPageManager.onFlutterFirstShow();
    }

    @Test
    public void onBackPressed() {
        Activity activity = Mockito.mock(Activity.class);
        mxPageManager.onBackPressed(activity);
    }

    @Test
    public void testOnBackPressed() {
    }


    @Test
    public void willFlutterPageBack() {
        assertFalse(mxPageManager.checkIsFlutterCanPop());
        mxPageManager.setCurrentShowPage(Mockito.mock(MXFlutterActivity.class));
        assertFalse(mxPageManager.checkIsFlutterCanPop());

        MXFlutterFragment mxFlutterFragment = Mockito.mock(MXFlutterFragment.class);
        mxPageManager.setCurrentShowPage(mxFlutterFragment);
        assertFalse(mxPageManager.checkIsFlutterCanPop());

        Whitebox.setInternalState(mxFlutterFragment, "checkIsFlutterCanPop", true);
        assertTrue(mxPageManager.checkIsFlutterCanPop());
    }

    @Test
    public void updateContainer() {
    }

    @Test
    public void isInFlutterPage() {
        assertFalse(mxPageManager.isInFlutterPage());

        mxPageManager.setCurrentShowPage(Mockito.mock(MXFlutterFragment.class));
        assertTrue(mxPageManager.isInFlutterPage());

        mxPageManager.setCurrentShowPage(Mockito.mock(Activity.class));
        assertFalse(mxPageManager.isInFlutterPage());

        mxPageManager.setCurrentShowPage(Mockito.mock(MXFlutterActivity.class));
        assertTrue(mxPageManager.isInFlutterPage());

        mxPageManager.setCurrentShowPage(Mockito.mock(Activity.class));
        assertFalse(mxPageManager.isInFlutterPage());

        mxPageManager.setCurrentShowPage(Mockito.mock(IMXPage.class));
        assertTrue(mxPageManager.isInFlutterPage());

    }

    @Test
    public void overlayNames() {
        assertTrue(mxPageManager.overlayNames().isEmpty());
        assertFalse(mxPageManagerWithConfig.overlayNames().isEmpty());
        assertEquals("tabBar", mxPageManagerWithConfig.overlayNames().get(0));
    }

    @Test
    public void overlayView() {
        assertNull(mxPageManager.overlayView("tabBar"));
        assertEquals(mockTabBar, mxPageManagerWithConfig.overlayView("tabBar"));
    }

    @Test
    public void overlayViewsForNames() {
        List<String> overlayNames = Arrays.asList("title", "tabBar");
        Map<String, View> overlayView = mxPageManagerWithConfig.overlayViewsForNames(overlayNames);
        assertNotNull(overlayView);
        assertFalse(overlayView.isEmpty());
        assertEquals(mockTitle, overlayView.get("title"));
        assertEquals(mockTabBar, overlayView.get("tabBar"));
    }

}