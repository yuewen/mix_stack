package com.yuewen.mix_stack_example;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.FragmentTransaction;

import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.core.MXPageManager;
import com.yuewen.mix_stack.interfaces.IMXPageManager;
import com.yuewen.mix_stack.model.AreaInsetsConfig;
import com.yuewen.mix_stack.model.MXViewConfig;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/*******************************************************
 *
 * Created by julis.wang on 2021/01/21 10:37
 *
 * Description :
 *
 * History   :
 *
 *******************************************************/

public class MoreFunctionActivity extends AppCompatActivity implements IMXPageManager {
    private String route;
    private LinearLayout llTabBar;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_more_function);
        Intent intent = getIntent();
        if (intent != null) {
            route = intent.getStringExtra("route");
        }
        initView();
        showFlutterFragment();
    }

    private void initView() {
        llTabBar = findViewById(R.id.ll_tab_container);
        ViewGroup.LayoutParams layoutParams = llTabBar.getLayoutParams();
        if (TextUtils.equals(route, "/popup_window")) {
            findViewById(R.id.ll_container).setVisibility(View.GONE);
        }
        findViewById(R.id.btn_add).setOnClickListener(v -> {
            layoutParams.height += 20;
            llTabBar.setLayoutParams(layoutParams);

        });
        findViewById(R.id.btn_sub).setOnClickListener(v -> {
            layoutParams.height -= 20;
            if (layoutParams.height < 0) {
                return;
            }
            llTabBar.setLayoutParams(layoutParams);
        });

        findViewById(R.id.btn_show).setOnClickListener(v -> llTabBar.setVisibility(View.VISIBLE));
        findViewById(R.id.btn_hide).setOnClickListener(v -> llTabBar.setVisibility(View.INVISIBLE));
    }

    private void showFlutterFragment() {
        MXFlutterFragment fg = new MXFlutterFragment();
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.add(R.id.fl_container, fg, fg.getClass().getName());
        transaction.commit();
        Bundle bundle = new Bundle();
        bundle.putString(MXFlutterFragment.ROUTE, route);
        fg.setArguments(bundle);
        pageManager.setCurrentShowPage(fg);

    }

    MXPageManager pageManager = new MXPageManager() {
        @Override
        public List<String> overlayNames() {
            List<String> overlayNames = new ArrayList<>();
            overlayNames.add("tabBar");
            return overlayNames;
        }

        @Override
        public View overlayView(String viewName) {
            if ("tabBar".equals(viewName)) {
                return llTabBar;
            } else {
                return null;
            }
        }

        @Override
        public AreaInsetsConfig ignoreAreaInsetsConfig() {
            AreaInsetsConfig config = new AreaInsetsConfig();
            config.addBottomIgnoreNames("tabBar");
            return config;
        }

        @Override
        public void configOverlay(Map<String, MXViewConfig> overlayNamesConfig) {
            super.configOverlay(overlayNamesConfig);

        }
    };

    @Override
    public MXPageManager getPageManager() {
        return pageManager;
    }

}
