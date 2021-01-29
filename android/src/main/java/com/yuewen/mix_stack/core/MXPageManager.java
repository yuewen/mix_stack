package com.yuewen.mix_stack.core;

import android.app.Activity;
import android.os.Build;
import android.view.View;

import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.component.MXFlutterFragment;
import com.yuewen.mix_stack.interfaces.PageIsRootListener;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.interfaces.IMXPageManager;
import com.yuewen.mix_stack.interfaces.InvokeMethodListener;
import com.yuewen.mix_stack.interfaces.PageHistoryListener;
import com.yuewen.mix_stack.model.AreaInsetsConfig;
import com.yuewen.mix_stack.model.MXViewConfig;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/13 19:07
 *
 * Description :
 *
 *  This class has two important functions:
 *  1\Control the Flutter page to present the lifecycle.
 *
 *  2\Handle for displaying full-screen content on the Flutter page.
 *
 *
 * History   :
 *
 *******************************************************/

public class MXPageManager extends PageOverlayConfig {
    private List<IMXPage> pageList;
    private Object currentPage;
    private boolean hasListen = false;

    public MXPageManager() {
        this.pageList = new CopyOnWriteArrayList<>();
    }

    public void onDestroy() {
        MXStackInternal.getInstance().onDestroy(pageList);
        pageList.clear();
    }

    public void onResume() {
        MXStackInternal.getInstance().callCurrentPageAgain();
    }

    /**
     * @param willShowPage contains Fragment & Activity.
     */
    private void setCurrentShowPageInner(Object willShowPage) {
        if (willShowPage == null) {
            return;
        }
        currentPage = willShowPage;
        if (!(willShowPage instanceof IMXPage)) {
            return;
        }
        IMXPage page = (IMXPage) willShowPage;
        if (!pageList.contains(page)) {
            pageList.add(page);
        }
        MXStackInternal.getInstance().setPage(page);
    }

    /**
     * @param willShowPage
     */
    public void setCurrentShowPage(Object willShowPage) {
        setCurrentShowPageInner(willShowPage);
        if (!hasListen) {
            hasListen = true;
            initIgnoreAreaListener();
        }
    }

    private void initIgnoreAreaListener() {
        View view = tryToFindNotNullView();
        if (view == null) {
            return;
        }
        //below api 26 addOnDrawListener don't have callback.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            view.post(() -> addOnDrawListener(view));
        } else {
            addOnDrawListener(view);
        }
    }

    private View tryToFindNotNullView() {
        List<String> overlayNames = overlayNames();
        if (overlayNames == null || overlayNames.isEmpty()) {
            return null;
        }
        for (String name : overlayNames) {
            View view = overlayView(name);
            if (view != null) {
                return view;
            }
        }
        return null;
    }

    private void addOnDrawListener(View view) {
        view.getViewTreeObserver().addOnDrawListener(
                () -> {
                    Activity activity = MXStackService.getCurrentActivity();
                    if (!(activity instanceof IMXPageManager)) {
                        return;
                    }
                    int newHasCode = ((IMXPageManager) activity).getPageManager().hashCode();
                    if (newHasCode != MXPageManager.this.hashCode()) {
                        return;
                    }
                    MXViewConfig.InsetInfo containerInsetInfo
                            = ignoreAreaInsetsConfig()
                            .areaInsetsForOverlayHandler(MXPageManager.this);
                    updateContainer(containerInsetInfo);
                });
    }

    //TODO: when flutter not init.
    public void onFlutterFirstShow() {
        MXStackInternal.getInstance().onFlutterFirstShow();
    }

    public void onBackPressed(InvokeMethodListener listener) {
        MXStackInternal.getInstance().pagePop(listener);
    }

    /**
     * Send a notice to flutter that pop this flutter page then get a result:
     * true->has more flutter page
     * false->in root flutter page.
     * <p>
     * Every time on back key pressed which means that we want to pop this flutter page, but situation becomes complicated
     * when in a root flutter page.
     * <p>
     * If this container's flutter in root page which means that there are no more flutter content,
     * We set a flag {@link MXFlutterFragment#isFlutterCanPop} by {@link MXPageManager#checkIsFlutterCanPop()} use
     * eg:
     * <p>
     * public void onBackPressed() {
     * if (pageManager.checkIsFlutterCanPop()) {
     * pageManager.onBackPressed(this);
     * } else {
     * super.onBackPressed();
     * }
     * }
     * <p>
     * When hasMorePage->false, will call fragment's host#onBackPressed(),and {@link MXPageManager#checkIsFlutterCanPop()}
     * get a false result, then call host normal onBackPressed().
     *
     * @param activity
     */
    public void onBackPressed(Activity activity) {
        final WeakReference<Activity> activityWeakReference = new WeakReference<>(activity);
        MXStackInternal.getInstance().pagePop(new InvokeMethodListener() {
            @Override
            public void onCompleted(Object result) {
                boolean hasMorePage = (Boolean) ((HashMap) result).get("result");
                if (!(currentPage instanceof IMXPage)) {
                    activityWeakReference.get().onBackPressed();
                    return;
                }
                MXFlutterFragment fragment = (MXFlutterFragment) currentPage;

                if (!hasMorePage) {
                    fragment.isFlutterCanPop = false;
                    activityWeakReference.get().onBackPressed();
                } else {
                    fragment.isFlutterCanPop = true;
                }
            }
        });
    }

    /**
     * Check current container's flutter page if in root page.
     * This method is not synchronized,so you'd add a listener.
     *
     * @param listener
     */
    public void isInRootPage(final PageIsRootListener listener) {
        getPageHistory(new PageHistoryListener() {
            @Override
            public void pageHistory(List<String> history) {
                int length = history == null ? 0 : history.size();
                if (currentPage instanceof MXFlutterFragment) {
                    MXFlutterFragment flutterFragment = (MXFlutterFragment) currentPage;
                    if (!flutterFragment.isFlutterCanPop) {
                        flutterFragment.isFlutterCanPop = length != 1;
                    }
                }
                listener.isInRootPage(length == 1);
            }
        });
    }

    public void getPageHistory(PageHistoryListener listener) {
        MXStackInternal.getInstance().pageHistory(new InvokeMethodListener() {
            @Override
            public void onCompleted(Object result) {
                List<String> list = result == null ? new ArrayList<>() : (List<String>) result;
                listener.pageHistory(list);
            }
        });
    }

    public boolean checkIsFlutterCanPop() {
        if (!isInFlutterPage()) {
            return false;
        }
        if (currentPage instanceof MXFlutterFragment) {
            MXFlutterFragment fragment = (MXFlutterFragment) currentPage;
            return fragment.isFlutterCanPop;
        }
        return false;
    }

    public void updateContainer(MXViewConfig.InsetInfo params) {
        MXStackInternal.getInstance().updateContainer(params);
    }

    public boolean isInFlutterPage() {
        return currentPage instanceof MXFlutterFragment
                || currentPage instanceof MXFlutterActivity
                || currentPage instanceof IMXPage;
    }

    @Override
    public List<String> overlayNames() {
        return new ArrayList<>();
    }

    @Override
    public View overlayView(String viewName) {
        return null;
    }

    @Override
    public AreaInsetsConfig ignoreAreaInsetsConfig() {
        return new AreaInsetsConfig();
    }
}
