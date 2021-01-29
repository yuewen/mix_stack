package com.yuewen.mix_stack_example;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/10 18:19
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class NativeFragment extends Fragment {

    private String testRoute;
    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Bundle bundle = getArguments();
        if (bundle != null) {
            testRoute = bundle.getString("route");
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.layout_native_list, container, false);
        initView(view);
        return view;
    }

    @SuppressLint("SetTextI18n")
    private void initView(View view) {
        Button btnGoFlutter = view.findViewById(R.id.btn_go_flutter);
        Button btnGoNative = view.findViewById(R.id.btn_go_native);
        Button btnGoBack = view.findViewById(R.id.btn_go_back);
        TextView textView = view.findViewById(R.id.tv_hash_code);
        int randomIndex = new Random().nextInt(primariesColor.size());
        view.findViewById(R.id.ll_container)
                .setBackgroundColor(getResources()
                        .getColor(primariesColor.get(randomIndex)));
        Activity activity = getActivity();
        textView.setText("hashCode:" + this.hashCode());
        btnGoFlutter.setOnClickListener(v -> {
            Intent intent = new Intent(activity, FlutterMainActivity.class);
            if ("/clear_stack".equals(testRoute)) {
                intent.putExtra("route", testRoute);
            } else {
                intent.putExtra("route", "simple_flutter_page");
            }
            startActivity(intent);
        });
        btnGoNative.setOnClickListener(v -> {
            Intent intent = new Intent(activity, NativeActivity.class);
            startActivity(intent);
        });
        btnGoBack.setOnClickListener(v -> activity.finish());
    }

    private static final List<Integer> primariesColor = Arrays.asList(
            R.color.red,
            R.color.pink,
            R.color.purple,
            R.color.deeppink,
            R.color.indigo,
            R.color.blue,
            R.color.mediumorchid,
            R.color.blueviolet,
            R.color.teal,
            R.color.green,
            R.color.lightgreen,
            R.color.aqua,
            R.color.gray,
            R.color.black,
            R.color.orange,
            R.color.orangered,
            R.color.brown);


}
