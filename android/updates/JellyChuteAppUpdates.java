package com.godot.game;

import android.app.Activity;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.appupdate.AppUpdateOptions;
import com.google.android.play.core.install.InstallStateUpdatedListener;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Optional Play updates. No network/Play error is allowed to block gameplay. */
public final class JellyChuteAppUpdates extends GodotPlugin {
    private static final int REQUEST_UPDATE = 4817;
    private final Handler main = new Handler(Looper.getMainLooper());
    private AppUpdateManager manager;
    private volatile int state; // 0: idle/unavailable/downloading, 1: available, 2: downloaded
    private volatile boolean flowActive;
    private boolean consentVisible;
    private volatile boolean installFailed;
    private final InstallStateUpdatedListener listener = install -> {
        if (install.installStatus() == InstallStatus.DOWNLOADED) state = 2;
        else if (install.installStatus() == InstallStatus.FAILED
                || install.installStatus() == InstallStatus.CANCELED) state = 0;
    };

    public JellyChuteAppUpdates(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "JellyChuteAppUpdates"; }

    private boolean initialize() {
        Activity activity = getActivity();
        if (activity == null || activity.isFinishing() || activity.isDestroyed()) return false;
        if (manager == null) {
            manager = AppUpdateManagerFactory.create(activity);
            manager.registerListener(listener);
        }
        return true;
    }

    @UsedByGodot public boolean didInstallFail() { return installFailed; }
    @UsedByGodot public int getUpdateState() { return state; }
    @UsedByGodot public boolean isFlowActive() { return flowActive; }
    @UsedByGodot public void checkForUpdate() { main.post(this::check); }

    private void check() {
        if (!initialize() || flowActive) return;
        manager.getAppUpdateInfo().addOnSuccessListener(info -> {
            if (info.installStatus() == InstallStatus.DOWNLOADED) state = 2;
            else if (info.installStatus() == InstallStatus.DOWNLOADING
                    || info.installStatus() == InstallStatus.PENDING) state = 0;
            else state = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                    && info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE) ? 1 : 0;
        }).addOnFailureListener(error -> Log.d("JellyChuteAppUpdates", "Check unavailable", error));
    }

    @UsedByGodot public void startFlexibleUpdate() {
        flowActive = true;
        main.post(() -> {
            if (!initialize()) { flowActive = false; return; }
            // A fresh AppUpdateInfo is required for every attempt.
            manager.getAppUpdateInfo().addOnSuccessListener(info -> {
                if (!flowActive) return;
                if (info.installStatus() == InstallStatus.DOWNLOADED) {
                    state = 2;
                    flowActive = false;
                    return;
                }
                try {
                    if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE
                            || !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                            || !manager.startUpdateFlowForResult(info, getActivity(),
                                AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(), REQUEST_UPDATE)) {
                        flowActive = false;
                    } else consentVisible = true;
                } catch (Exception error) {
                    flowActive = false;
                    Log.w("JellyChuteAppUpdates", "Cannot open update", error);
                }
            }).addOnFailureListener(error -> flowActive = false);
        });
    }

    @Override public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_UPDATE) {
            flowActive = false;
            consentVisible = false;
            state = 0;
            check();
        }
    }

    @UsedByGodot public void cancelPendingCheck() {
        main.post(() -> { if (!consentVisible) flowActive = false; });
    }

    @UsedByGodot public void completeUpdate() {
        main.post(() -> {
            if (initialize() && state == 2) {
                installFailed = false;
                manager.completeUpdate().addOnFailureListener(error -> {
                    installFailed = true;
                    Log.w("JellyChuteAppUpdates", "Cannot install update", error);
                });
            }
        });
    }

    @Override public void onMainResume() { main.post(this::check); }
    @Override public void onMainDestroy() {
        main.post(() -> {
            if (manager != null) manager.unregisterListener(listener);
        });
    }
}
