package com.yuewen.mix_stack.core;

import com.yuewen.mix_stack.MixStackPlugin;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.interfaces.InvokeMethodListener;
import com.yuewen.mix_stack.model.MXViewConfig;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/11 09:59
 *
 * Description :
 * History   :
 *
 *******************************************************/

class MXStackInternal {
    private static MXStackInternal instance;
    private List<WeakReference<IMXPage>> pages;
    private WeakReference<IMXPage> currentPage;
    private Map<String, Object> currentPageQuery;
    private MXViewConfig.InsetInfo lastContainerInsetInfo;

    private MXStackInternal() {
        pages = new CopyOnWriteArrayList<>();
    }

    static MXStackInternal getInstance() {
        if (instance == null) {
            synchronized (MXStackInternal.class) {
                if (instance == null) {
                    instance = new MXStackInternal();
                }
            }
        }
        return instance;
    }

    /**
     * Set current page's into and tells flutter which page should to show at now.
     *
     * @param page which page want to show.
     */
    void setPage(IMXPage page) {
        lastContainerInsetInfo = null; //reset.
        if (currentPage != null && currentPage.get() == page) {
            return;
        }
        checkAndAddPage(page);
        String formatStr = "%s?addr=%s";
        String current = String.format(formatStr, page.rootRoute(), page.hashCode());
        Map<String, Object> query = new HashMap<>();
        query.put("pages", getAllStackPageInfo());
        query.put("current", current);
        MixStackPlugin.invoke("setPages", query);
        currentPageQuery = query;
        currentPage = new WeakReference<>(page);
        MXStackService.getInstance().setCurrentPage(currentPage);
    }


    private void checkAndAddPage(IMXPage page) {
        boolean isContains = false;
        for (WeakReference<IMXPage> iPage : pages) {
            if (iPage.get() == page) {
                isContains = true;
                break;
            }
        }
        if (!isContains) {
            pages.add(new WeakReference<>(page));
        }
    }

    /**
     * Clear destroyed pages.
     *
     * @param pageSet
     */
    void onDestroy(List<IMXPage> pageSet, IMXPage page) {
        for (IMXPage childPage : pageSet) {
            for (WeakReference<IMXPage> tPage : pages) {
                if (tPage == null) {
                    continue;
                }
                if (tPage.get() == null || tPage.get() == childPage) {
                    pages.remove(tPage);
                }
            }
        }

        String formatStr = "%s?addr=%s";
        String current = "";
        if (currentPage.get() != page) {
            current = String.format(formatStr, currentPage.get().rootRoute(), currentPage.get().hashCode());
        }
        Map<String, Object> query = new HashMap<>();
        query.put("pages", getAllStackPageInfo());
        query.put("current", current);
        MixStackPlugin.invoke("setPages", query);

    }

    /**
     * Ensure flutter had call setPages when it's running.
     */
    public void onFlutterFirstShow() {
        callCurrentPageAgain();
    }

    public void callCurrentPageAgain() {
        MixStackPlugin.invoke("setPages", currentPageQuery);
    }

    public void updateContainer(MXViewConfig.InsetInfo containerInsetInfo) {
        Map<String, Object> query = new HashMap<>();
        if (currentPageQuery == null) {
            return;
        }
        Object current = currentPageQuery.get("current");
        if (current == null) {
            return;
        }
        if (containerInsetInfo.equals(lastContainerInsetInfo)) {
            return;
        }
        lastContainerInsetInfo = containerInsetInfo;
        String target = (String) current;
        query.put("target", target);
        query.put("info", containerInsetInfo.toMap());
        MixStackPlugin.invoke("containerInfoUpdate", query);
    }

    /**
     * In flutter page, when it's back from back key press or navigation bar's back action.
     */
    void pagePop(InvokeMethodListener listener) {
        if (currentPageQuery != null) {
            MixStackPlugin.invokeWithListener("popPage", currentPageQuery, listener);
        }
    }

    private List<String> getAllStackPageInfo() {
        String formatStr = "%s?addr=%s";
        List<String> allStackPage = new ArrayList<>(); //current status all of exist pages.
        for (WeakReference<IMXPage> iPage : pages) {
            if (iPage == null || iPage.get() == null) {
                pages.remove(iPage);
                continue;
            }
            allStackPage.add(String.format(formatStr, iPage.get().rootRoute(), iPage.get().hashCode()));
        }
        return allStackPage;
    }


    public List<WeakReference<IMXPage>> getAllSavePages() {
        return pages;
    }

    void pageHistory(InvokeMethodListener listener) {
        if (currentPageQuery != null) {
            MixStackPlugin.invokeWithListener("pageHistory", currentPageQuery, listener);
        }
    }

    void destroy() {
        instance = null;
    }
}










