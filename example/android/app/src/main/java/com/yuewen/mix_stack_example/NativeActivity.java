package com.yuewen.mix_stack_example;

import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

/*******************************************************
 *
 * Created by julis.wang on 2021/01/20 16:16
 *
 * Description :
 *
 * History   :
 *
 *******************************************************/

public class NativeActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_native);
        initView();

    }

    private void initView() {
        Fragment fg = new NativeFragment();
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.add(R.id.fl_container, fg, fg.getClass().getName());
        transaction.commit();
    }
}











