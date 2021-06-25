package com.yuewen.mix_stack_example;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.core.MXPageManager;
import com.yuewen.mix_stack.interfaces.IMXPageManager;

import java.util.HashMap;
import java.util.Map;

/*******************************************************
 *
 * Created by julis.wang on 2021/01/20 18:55
 *
 * Description :
 *
 * History   :
 *
 *******************************************************/

public class MultipleTabActivity extends MXFlutterActivity implements View.OnClickListener, IMXPageManager {
    private LinearLayout llTabBar;
    MXPageManager pageManager = new MXPageManager();
    private String route;
    private NativeFragment nativeListFragment;
    private Fragment currentFragment, flutterPage1, flutterPage2;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tab);
        Intent intent = getIntent();
        if (intent != null) {
            route = intent.getStringExtra("route");
        }
        initView();
    }

    private void initView() {
        llTabBar = findViewById(R.id.ll_tab_container);
        findViewById(R.id.tv_native).setOnClickListener(this);
        findViewById(R.id.tv_flutter_first).setOnClickListener(this);
        findViewById(R.id.tv_flutter_second).setOnClickListener(this);
        if (nativeListFragment == null) {
            nativeListFragment = new NativeFragment();
            Bundle bundle = new Bundle();
            bundle.putString("route", route);
            nativeListFragment.setArguments(bundle);
            currentFragment = nativeListFragment;
        }
        showFragment(currentFragment);
    }

    private void showFragment(Fragment fg) {
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        if (currentFragment != fg) {
            transaction.hide(currentFragment);
        }
        if (!fg.isAdded()) {
            transaction.add(R.id.fl_main_container, fg, fg.getClass().getName());
        } else {
            transaction.show(fg);
        }
        transaction.commit();

        currentFragment = fg;
        pageManager.setCurrentShowPage(currentFragment);
    }


    @Override
    public void onBackPressed() {
        if (pageManager.checkIsFlutterCanPop()) {
            pageManager.onBackPressed(this);
        } else {
            super.onBackPressed();
        }
    }


    @SuppressLint("NonConstantResourceId")
    @Override
    public void onClick(View v) {
        int viewId = v.getId();
        int index = 0;

        switch (viewId) {
            case R.id.tv_native:
                showFragment(nativeListFragment);
                index = 0;
                break;
            case R.id.tv_flutter_first:
                if (flutterPage1 == null) {
                    flutterPage1 = buildFlutterFragment();
                }
                showFragment(flutterPage1);
                index = 1;
                break;
            case R.id.tv_flutter_second:
                if (flutterPage2 == null) {
                    flutterPage2 = buildFlutterFragment();
                }
                showFragment(flutterPage2);
                index = 2;
                break;

        }
        for (int i = 0; i < llTabBar.getChildCount(); i++) {
            TextView textView = (TextView) llTabBar.getChildAt(i);
            textView.setTextColor(index == i ? Color.BLACK : Color.GRAY);
        }
    }

    private MXFlutterFragment buildFlutterFragment() {
        MXFlutterFragment hxFlutterFragment = new MXFlutterFragment();
        Bundle bundle = new Bundle();
        bundle.putString(MXFlutterFragment.ROUTE, "/simple_flutter_page");
        hxFlutterFragment.setArguments(bundle);

        return hxFlutterFragment;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        pageManager.onDestroy(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        pageManager.setCurrentShowPage(currentFragment);
    }

    @Override
    public MXPageManager getPageManager() {
        return pageManager;
    }


    // ======== Test clear stack start ========

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (intent == null) {
            return;
        }
        String action = intent.getStringExtra("action");
        if (!TextUtils.isEmpty(action) && "go_to_tab".equals(action)) {
            findViewById(R.id.tv_flutter_second).performClick();
            Map<String, String> query = new HashMap<>();
            query.put("query_data", "data from native");
            if (flutterPage2 != null) {
                ((MXFlutterFragment) flutterPage2).sendEvent("popToTab", query);
                findViewById(R.id.tv_flutter_first).performClick();
            }
        }
    }
    // ======== Test clear stack End ========

}
