package com.godot.game;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import com.google.android.play.core.review.ReviewInfo;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public final class JellyChuteAppReview extends GodotPlugin {
    private final Handler main = new Handler(Looper.getMainLooper());
    private volatile int state; // 0 idle, 1 requesting, 2 ready, -1 unavailable
    private volatile boolean active;
    private ReviewManager manager;
    private ReviewInfo info;
    private int generation;

    public JellyChuteAppReview(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "JellyChuteAppReview"; }
    @UsedByGodot public int getReviewState() { return state; }
    @UsedByGodot public boolean isFlowActive() { return active; }
    private boolean usable(Activity activity) {
        return activity != null && !activity.isFinishing() && !activity.isDestroyed();
    }
    @UsedByGodot public void prepareReview() {
        state = 1;
        main.post(() -> {
            int token = ++generation;
            info = null;
            Activity activity = getActivity();
            if (!usable(activity) || active) { state = -1; return; }
            try {
                manager = ReviewManagerFactory.create(activity);
                manager.requestReviewFlow().addOnCompleteListener(task -> {
                    if (token != generation) return;
                    if (task.isSuccessful()) { info = task.getResult(); state = 2; }
                    else state = -1;
                });
            } catch (Exception error) { state = -1; }
        });
    }
    @UsedByGodot public void cancelRequest() {
        main.post(() -> { ++generation; info = null; state = 0; });
    }
    @UsedByGodot public void launchReview() {
        active = true;
        main.post(() -> {
            Activity activity = getActivity();
            if (!usable(activity) || info == null || manager == null) {
                active = false;
                state = -1;
                return;
            }
            ReviewInfo ready = info;
            info = null;
            state = 0;
            try {
                manager.launchReviewFlow(activity, ready).addOnCompleteListener(task -> active = false);
            } catch (Exception error) { active = false; }
        });
    }
    @Override public void onMainDestroy() {
        main.post(() -> { ++generation; info = null; manager = null; active = false; state = 0; });
    }
}
