# JellyChute: Freefall Racers

Portrait 2D Android MVP for Godot 4.7, Compatibility renderer. Open project.godot and press F5. Bundled assets; no plugins required. APK/AAB are not built.

## Play
Four racers jump after 3, 2, 1, GO. Pink is the player. Tap once to open the parachute; desktop click also works. Safe landing requires at most 2.5 m/s. Three rounds score 10/7/4/2 for safe finishers, zero for crashes; final round order breaks tournament ties. Wins and best safe time persist in encrypted user://records.dat.

## Active art direction
The active reference is assets/toon/style-reference.png, the bold inked cartoon supplied by the user. toon_art.gd draws saturated characters with dark plum outlines, patterned parachutes, hand-painted countryside and matching yellow/cream UI. This supersedes the previous Paper Sky direction; assets/paper and paper_art.gd are retained as inactive source material.

assets/toon/actors.png contains four torsos, four patterned canopies, arms and boots. props.png contains clouds, bird, four landing pads and blank UI pieces. landscape.png is the transparent painted countryside. sky.png is an independent full-screen painted background, drawn once without tiling. No scene fragment from the reference image is tiled as sky. generation-prompts.txt records the built-in image_gen prompts.

## Motion and scale
The resting jelly is 1 metre tall, about 63 canvas pixels. This conversion is shared by the camera, foreground objects and altitude ruler. Jump height is 120m, arcade gravity 6 m/s², terminal speed 12 m/s, final chute descent 2 m/s. Freefall reaches the green 16–21m deployment band in 2–4 seconds. All racers share the randomized starting height. Clouds use parallax; birds occupy fixed world heights. Scarves and arms react to speed. A crash flattens the body, restores it in about 1.1 seconds, and leaves dizzy eyes and orbiting stars. The sole remains anchored to the landing surface.

Faces change during gameplay: excitement after takeoff, confidence during freefall, concern and panic near the ground, surprise during chute inflation, relief after inflation, joy on safe landing, dizziness after a failed landing. Blinks and moving pupils add motion between expression changes.

## Validation
Godot 4.7.2 headless simulation checks countdown, scale, complete tournaments, scores, restart, crash recovery and all expression transitions. work/capture.gd renders portrait game previews with the real renderer. Run locally:

    godot --headless --path . --script res://work/smoke.gd --quit-after 5

Device touch and Android performance remain for manual testing. This task does not build Android packages.

## Branding and landing polish
assets/toon/logo.png is the transparent illustrated JellyChute: Freefall Racers wordmark. menu-frame.png provides tree/flower corner framing. The main menu combines the logo, animated parachutists, drifting clouds, painted scenery, record cards and a large start button. Standard gameplay HUD geometry is restored when a tournament starts.

Safe landed racers use the landed expression: both eyes stay open instead of holding the airborne victory squint. Hard landings emit ten expanding, drifting dust puffs anchored to the world ground plane; safe landings do not emit dust. Puffs fade out after about a second. Star effects and dizzy expressions remain separate. Simulation tests cover open landed eyes across blink timings, dust emission/fade state and menu-to-race UI reset.

## Race HUD and finish reactions
The gameplay HUD separates the round/time/live-position header from the altitude/speed telemetry and thumb control. Context messages distinguish approaching ground, chute inflation, glide and landing. The action button locks after deployment and changes to a clear safe/crash landing state. Countdown uses a large central number. Native results labels are restored on results/podium screens.

Landed safe racers react to their actual place: champion raises both arms and wears a crown; runner-up claps; third wipes the forehead with a relieved smile; fourth slouches with downcast pupils and a frown. Eyes remain open for all landed reactions. Crashes preserve dizzy eyes, stars and dust instead of a victory reaction. Each place is recomputed from the classified order, so crashes are not treated as successful winners. On the final podium, reactions follow tournament points and the final-round tiebreak. The final landing has a 2.2-second reaction window before results.

The sky dock replaces the plane with candy-coloured planks, pennants and a CERTIFIED BAD IDEA sign. The altitude gauge highlights the green deployment band and the button calls out PULL NOW. Round results and the tournament finale use animated confetti, illustrated podiums and a compact honour roll.

Flight racers use 0.9 scale and lanes at x=151/251/351/451, leaving a dedicated left gutter for the altitude gauge. The same lane positions drive pads, platform markings, dust and landing particles. Podium jellies perform a victory bounce, exaggerated clapping/bowing and a wobbly balancing routine, with alternating comic speech bubbles.

Character identities persist in menu, flight, landings and podium: pink is a winking show-off with a swept blond quiff and lopsided grin; Mango laughs with buck teeth, freckles and wonky forehead goggles; Bubbles wears a beret, monocle and bow tie with an aristocratic smirk; Pickle has sleepy eyes, a tiny moustache and a swaying sprout. Fear, deployment surprise and crash dizziness still override their relaxed expressions.

Actor sprites use individually measured atlas regions rather than equal-width columns. All four canopies retain their complete outer scallops without strips from neighbouring parachutes.

The flight HUD has no numeric altitude/speed panel or world ruler. Deployment timing is communicated only by the left altitude bar, its green band and attached marker; the action button has a fixed label and there are no screen-edge timing flashes. The SFX toggle and saved mute preference are removed; sound effects are always enabled.

Jump countdown uses colour-coded elastic number badges, a draining beat ring, expanding ripples, comic captions and three progress dots. The GO badge bursts outward and fades during takeoff. Timing remains exactly three seconds.

Pickle now wears a three-blade propeller beanie. Rotor phase is integrated continuously from descent speed, accelerating in freefall and easing down after chute deployment and landing.

On first launch, choose STAR, MANGO, BUBBLES or PICKLE using the four menu buttons before starting. Selection is saved and can be changed from the main menu. The selected jelly is the central menu hero and always occupies player slot zero (the left race lane). At each tournament start, rival jellies and canopies are sampled independently without replacement from owned items, excluding the player selections; the roster stays fixed across all three rounds. Accessories, pad, UI colour and name follow each jelly identity. The menu uses separate logo, hero, selection and record bands to prevent art/text overlaps.

Bubbles’ beret has a fitted band overlapping the upper head, with its crown seated lower. Pink’s headband is replaced by an outlined blond quiff with highlights and swept strands.

A MENU button in the upper-right corner returns from countdown, race, landing reactions, round results and the final podium. Escape does the same on desktop. Returning abandons the current tournament and resets transient race state while retaining character selection and saved records. The button is hidden on the main menu.

Each new tournament shuffles three opponent difficulties exactly once: CHILL JELLIES, WOBBLE PROS and JELLY ACES. The order stays fixed for its three rounds. Base rival ranges are 18.6–20m, 17–18.6m and 16–17m, before skill, tournament-form and spacing adjustments, using the same flight physics as the player. Starting altitude remains independently randomized for a 2–4 second freefall to the green band.

Character selection is a two-arrow carousel with wraparound, colour dots and an animated sliding/bouncing hero. Left/Right keys also browse. CONFIRM & JUMP is the only bottom button; it saves the previewed character and starts a new tournament. Browsing alone does not overwrite the saved preference.

Main action buttons share flat candy colours with plum borders and shadows. Menu and flight helper copy is a non-interactive child label inset at the bottom of the button; the main title sits above it. No helper text is drawn below the button.

Star’s blond quiff and its highlight strands flutter with descent speed, with roots fixed to the head. Rival difficulty is tighter: base deployments at 18.6–20m, 17–18.6m and 16–17m. Each round adds shared random form (±0.7m) and each rival adds individual variation (±0.3m), clamped to 15.5–21m. Targets remain fixed throughout the jump. Difficulty bands can overlap while their average skill remains ordered.

Podium bubbles draw from 30 place-specific jokes and 12 character-specific jokes, rotating speakers every 2.8 seconds with a short pause. A place never repeats its previous line immediately. Dialogue uses independent randomness so reading the results does not change race difficulty or starting heights.

Round and tournament leaderboards use separate aligned rows, medal place markers, character portraits, player-coloured highlighting and explicit time/points headings. Countdown captions sit below the number inside a compact badge at y=263–292, with progress dots at y=307 above character accessories.

CREDITS on the main menu shows the spendable wallet. Each completed three-round tournament pays the sum of safe-round placement points once: 10/7/4/2 per round, zero for a crash. No credits or lifetime career points are paid during the first two rounds or for an abandoned tournament. Spending credits does not reduce lifetime career points. Old saves initialize the wallet from accumulated career points; a previously confirmed premium character is retained during migration.

Progress uses Godot ConfigFile AES-256 encrypted saves at user://records.dat. Writes go to an encrypted temporary file, are verified by decryption, then replace the previous save. Existing user://records.cfg data is migrated automatically and plaintext is removed only after successful replacement. Unreadable saves are preserved and automatic overwrites are blocked. The application-held password protects against casual inspection/editing; it is not a server-side anti-cheat boundary. Tests and preview captures preserve both legacy and encrypted user files.

Safe landings briefly trigger an exaggerated chest-out, hands-on-hips proud pose with sparkles. The podium cycles through a runner-up standing on tiptoe toward the winner, the winner leaning defensively, third place nibbling a bronze medal, and a crown slipping over the winner’s eyes. Platform signs rotate among twelve absurd safety notices with no immediate repeats. These are cosmetic and do not alter flight physics or scores.

The altitude gauge is a continuous green→orange→red gradient with no tick marks or numeric labels. Opening in solid red always fails, regardless of descent speed. Player physics and the gauge remain independent of difficulty.

Adaptive profile v2 keeps the last 12 performance scores, a slower long-term estimate and a crash streak. Safe landings are scored by timing precision (45%), placement (30%) and successful landing (25%). More recent results carry greater weight; the target combines recent form (70%) and long-term skill (30%). After the initial nine-round calibration described below, difficulty rises by at most 0.05 per landing; an isolated loss lowers it by at most 0.035, while consecutive crashes allow relief of up to 0.08 per landing. Original opponent plans are sampled at round start; early-player reactions described below affect live opening targets only, retaining the three shuffled difficulty tiers and fixed player physics.

Each player landing updates and saves the profile immediately, once per round, before the results screen. Abandoning the tournament retains this learning but awards no tournament credits. Pause and desktop close also save progress. All persistent gameplay data (profile/history, records, wallet, ownership and confirmed selections) shares the AES-256 encrypted records.dat file. Temporary saves are encrypted before verification and replacement. Older encrypted profiles retain learned skill; plaintext legacy records are removed only after verified encrypted replacement, including cleanup retries on future launches.

Validation: work/adaptive-v2-check.gd checks adaptation limits, loss streaks, recovery, bounded history, encrypted roundtrips, legacy cleanup, immediate landing persistence, duplicate-result protection and encrypted temporary files after replacement failure.
The tournament champion holds a gold two-handled trophy in the right hand. The cup is anchored to the arm’s animated grip and follows the winner’s bounce; round-result podiums do not award the tournament trophy.

Three seconds after the first landing (safe or crash), the camera slides to ground over 1.6 seconds and holds for 2 seconds. Airborne racers keep flying outside the finish-line camera and are not teleported to the ground. Remaining classification is resolved with identical physics after this live view, before the results screen. The deadline resets each round.

The project and Google Play icon is assets/icons/google-play.png: enlarged Mango without parachute on a full opaque turquoise square, 512x512 RGBA, sRGB, under 1MB. application/config/icon points to this asset. Separate transparent Mango foreground: assets/icons/android-foreground.png.

The menu has separate upper arrows for four parachute designs and lower arrows for four jellies. Up/down changes the chute; left/right changes the jelly. CONFIRM & JUMP saves both choices together in the encrypted settings. Old saves default the chute to the saved character color. The chosen chute is used in the menu and flight; rivals retain their own canopies.

Normal completed rounds go to results 0.8 seconds after all racers land, without waiting for the first-landing deadline. The 1.6-second camera descent and 2-second ground hold apply only when the camera actually has to scroll down to the finish line.

## Additional jelly collection

Nine additional painted jellies extend the original four: Sir Pounce (cat), Barkley (dog), Toasty (dragon), 2 CHAINZ, NO BONES (bling rapper), Buzzbert (bee), Sir Sparkles (unicorn), Wobblebot (robot), Booberry (ghost), and Chef Wobble (chef). Owned characters can be previewed and confirmed in the existing character carousel; four unique racers still participate in each race. New selections persist with the existing encrypted progress format. Parachutes are selected independently; the four original canopies are free and nine additional cosmetics are available in the shop.

The Jellies shop tab displays the nine new characters in three columns and three rows. Locked characters are dimmed and marked with a lock. Purchase buttons show 200/300/500-credit prices, then EQUIP or EQUIPPED after ownership. Cat, dog, rapper and unicorn cost 500; dragon and robot cost 300; bee, ghost and chef cost 200. Purchases validate funds and ownership and roll back if saving fails. Ads are not integrated. `assets/toon/collection/README.md` documents asset layout and optimization. `work/capture-collection.gd` verifies and captures all new characters in the menu, freefall, open-chute and crash states plus shop/podium views. Local source art and capture outputs are excluded from Git and Godot resource scanning.

`work/economy-check.gd` verifies wallet migration, prices, purchase/equip states, insufficient funds, save rollback, locked carousel filtering, complete-tournament-only rewards, zero rewards for crashes, persistence and duplicate payout protection.

## Purchasable parachutes

The Parachutes shop tab contains Emergency Underpants, Holy Cow! and Flying Breakfast for 150 credits; Royal Flush, Definitely Safe, Disco Drop, Purrfect Landing and Woof Woof for 200; Bling Bling for 500. These are cosmetic canopies with unchanged flight physics. Each is a compact transparent painted PNG, maximum 384 x 256, documented in assets/toon/chutes/README.md.

Owned parachutes persist separately from owned jellies. Both shops use BUY, EQUIP and EQUIPPED; successful purchases appear in the respective main-menu arrow selector, while locked items are skipped. Equipping in a shop saves immediately; browsing on the main menu saves only on CONFIRM & JUMP. Existing saves retain all four free canopies. work/chute-check.gd verifies purchases, insufficient funds, save rollback, fresh-instance reload, main-menu selection of purchased jellies and all nine parachutes, plus in-flight rendering and shop states.

## Branded boot splash

The engine boot splash uses assets/toon/boot-splash.png: the selected cream illustration with the JellyChute logo and the four jellies packing parachutes. The opaque PNG is downsampled to 800 x 1279 and uses lossless compression. Boot stretch mode Keep preserves the full illustration and its proportions; linear filtering is enabled. Uncovered screen areas use the sampled cream #fdf3db background. The engine default Godot image is replaced; no extra scene or artificial startup delay is added. Full-resolution source remains in the ignored splash-proposals preview folder. work/capture-boot-splash.gd validates the configured image and captures portrait, tall-phone and wider-screen layouts.

## Tournament pacing and adaptive profile v3

The persistent 12-landing profile still updates and saves once on each player landing. A struggle streak now also counts safe finishes in third/fourth place, so repeated losses soften opponents even without crashes. Both crash and struggle streaks persist in the encrypted save; older profiles default struggle streak to the existing crash streak.

Each tournament also tracks landing outcomes (using original-plan placement in reactive rounds). After one weak jump (crash or third/fourth), opponents open 1m earlier; after one excellent jump (safe top-two, performance >= 0.72), they open only 0.2m later. Two consecutive weak jumps increase relief to 2.5m; two excellent jumps increase the challenge to just 0.65m. Other mixed outcomes use only the latest jump. These offsets combine with the saved skill profile before sampling the next round, never during a running jump.

For these two-outcome finales, shared randomness drops from +/-0.7m to +/-0.35m and individual variation from +/-0.3m to +/-0.18m. Final opponent plans are anchored to the original second-round average: relief moves opening 0.8–2.5m earlier, while challenge moves it only 0.25–0.7m later. This prevents shuffled difficulty tiers from cancelling relief or creating a large final spike. The pre-spacing plans retain the safe floor and 24m ceiling. The subsequent spacing pass described below may move individual openings up to 27m, preserving the average except where the safe floor requires extra room. The player's physics, gauge, scoring and rewards are unchanged.

Tournament form clears on restart/abandonment, while the encrypted long-term profile remains. The tournament is not resumed after app restart. Validation: work/tournament-adaptation-check.gd exercises all six tier orders with crashes, safe fourth places and excellent results, immediate second-round adaptation, bounded finale pacing, safe rival landings at 30/60/120 FPS, encrypted reload and reset behavior.
## Android export profiles

export_presets.cfg contains Android APK - test (builds/JellyChute-test.apk) and Android AAB - Google Play (builds/JellyChute-0.1.0.aab), adapted from alchemiQ. Both use com.pcplay.jellychute, display name JellyChute, version 0.1.0/code 1, ARM64, minimum SDK 24 and target SDK 36. They use the current google-play.png icon with a plum adaptive background and retain portrait orientation from project.godot. The game currently needs no network permissions.

The matching Godot 4.7.2 Android Gradle template is installed locally under android/build (ignored by Git). On a fresh checkout, install the matching Android build template from Godot before exporting. Work previews, icon proposals and development files are excluded from exports. Export credentials stay ignored; no alchemiQ signing secrets or plugins were copied.

For a test APK, choose Android APK - test and export with debug enabled. For Google Play, choose Android AAB - Google Play, configure the release keystore and credentials in Godot, and export with debug disabled. Android SDK/JDK settings are machine-local. Release exports require signing credentials; increase version/code for subsequent store uploads. No APK or AAB was built while preparing these profiles.
## Google Play flexible updates

Android uses Play app-update 2.1.0. After installing/replacing the matching Godot Android build template, run `powershell -ExecutionPolicy Bypass -File android/updates/install.ps1` before exporting either Android preset. This idempotently wires the tracked Java plugin, dependency and plugin metadata into the generated template. No signing credentials are changed.

The plugin checks at startup and on resume. Consent is offered once per process, only in the menu; Google Play downloads in the background. A downloaded update displays the restart dialog in the menu, never during a tournament. LATER defers it until the next launch. Restart first flushes the encrypted save; save errors block restart, and Play completion errors allow retry. Non-Android/offline/non-Play installations remain playable.

End-to-end verification requires a Play-installed build, the same application ID/signing identity and a higher versionCode available to the tester through Google Play. Use an internal test track or internal app sharing. A desktop screenshot uses a fake downloaded state, not a real Play download.

Validation: update-state/UI checks passed (work/app-updates-check.gd), Android Java compilation passed, and the debug APK exported with plugin class and manifest registration verified. The general smoke test reports a chute-selection assertion at work/smoke.gd:658; the same failure was reproduced with the update integration removed from an in-memory baseline script.

## Responsive portrait layout

The viewport uses canvas_items + expand. responsive_layout.gd computes a uniformly scaled 540x960 gameplay reference inside the current Android display safe area. Additional height anchors the menu logo and race header upward and action controls/credits downward; the world and physics retain their original metre/pixel mapping. Wider portrait displays add scenery at the sides. Sky fills the complete viewport and scenic landscapes preserve their aspect ratio while covering the bottom. Runtime resize/resume recomputes the layout. The update overlay remains full-screen and its card is centered inside the safe area.

Validation: work/responsive-check.gd captures menu, both shop tabs, countdown, landing, results, podium and update dialog at 16:9, 19.5:9, 20:9, 21:9 and portrait 3:4. It checks painted corners, action bounds, actual mouse hit targets after resize and synthetic cutout/navigation insets. Android safe-area behavior still needs a physical-device check. During this validation, shop portrait rendering was corrected to avoid reading gameplay state from a portrait drawing node.

Godot resolution reference: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

## Google Play in-app reviews

Uses the native unmodified Google Play review card (review 2.0.2). The same android/updates/install.ps1 wires both updates and reviews into a fresh Godot Android template.

First eligibility requires 3 consecutive completed tournament wins. Only a settled podium (4 seconds), after at least 60 seconds in the current process, is eligible. A non-winning completed tournament resets the streak; abandoning an unfinished tournament does not count as a completed result. Purchases and predicted star ratings are never used. Preparing a review is asynchronous and expires after 10 seconds; leaving the podium or backgrounding cancels the pending request. Updates take priority. The game pauses only while the native review flow is active and resumes on completion.

After the first launch attempt, wait at least 30 days. After the second and subsequent attempts, wait at least 60 days from the latest attempt. Each launch resets the win streak, so another series of 3 wins is required. There is at most one preparation per process; there is no lifetime attempt cap. Preparation errors back off for 24 hours. Persist the attempt and cleared streak before calling Play; a save error prevents launch and rolls back those fields. Tournament totals and streak updates are saved atomically with tournament rewards, exactly once. Counters/cooldowns live in the existing encrypted save. App updates retain them; clearing app data resets them. Old saves start at zero wins for this mechanism.

Play may suppress the card due to its own quota and does not report whether a rating was submitted. Completion is not treated as a submitted review. No custom pre-prompt, incentives, rating filter or forced store redirect is used. End-to-end testing needs a Play installation/internal test setup; local checks use a fake bridge.

References: https://developer.android.com/guide/playcore/in-app-review and https://developer.android.com/guide/playcore/in-app-review/kotlin-java

Review validation: work/app-reviews-check.gd covers 3-win eligibility, loss reset, exact 30/60-day thresholds, backward-clock suppression, saved cooldown reload, exactly-once tournament settlement, failed-save rollback, stale preparation cancellation, timeout backoff, update/background guards and pause/resume with a fake Play bridge. Native Java compilation passed. The review-feature APK export was cancelled at the user request. Create APK/AAB only when explicitly requested. The real Play review card and quota require Play-based device testing.

## 2 CHAINZ, NO BONES

Character ID 7 replaces the former ninja, preserving existing ownership and saved selections. Built-in image_gen produced assets/toon/collection/bling.png: purple blank-faced body, separately seated cap, bracelet arm and double gold necklace. Runtime eyes/mouth remain animated in every game state. The cap is scaled to 66x35 logical units, with a closed front band and no visible interior/rear lower rim and its underside is embedded in the scalp, sharing the body transform. The primary purple also drives its landing pad. Prompt: work/bling-prompt.txt.

Price: 500 credits. CHARACTER_SHOP_ORDER places ID 7 at row 3, column 2; card drawings, clipped portraits and purchase hit areas all use that order, while save IDs remain stable. The shop name is split across two readable lines. work/bling-check.gd verifies insufficient funds, purchase/equip, bottom-center button, persistent ID/ownership and captures menu, flight, landing and podium. The economy regression check also passes. No APK/AAB export was performed.


## Rival pacing and initial calibration (November 2026)

- The first nine learned landings calibrate faster: maximum upward skill changes per landing are 0.16, 0.11 and 0.075 in successive groups of three; downward changes have 15% more room. Recent performance carries 90% weight during calibration, and the long-term estimate updates at 30%. After nine landings, the previous conservative learning limits and 70/30 weighting resume. Existing profiles retain their progress; abandoning a tournament does not restart calibration. The skill-to-opening adjustment spans +3.5m to -3.5m, with the same physics and safe floor.
- Normal rival openings use randomized lane order around the planned mean with 1.8–2.6m between adjacent thresholds (about 0.15–0.22s at terminal speed). In 8% of rounds a tighter 0.15–0.55m spacing creates an occasional close pack. Safety takes precedence over preserving the mean.
- If the player opens at least 6m above the earliest rival plan, rivals respond in shuffled order: the first after roughly 0.18–0.32s, then mostly 0.18–0.44s apart. A 20% chance adds a short hesitation after the first responder. Beginners get shorter gaps, limiting the rivals' freefall advantage. A rival always retains its original opening as a safety fallback; reactions can only advance it.
- Original thresholds and predicted finish times are cached using the flight integrator. Both persistent skill and within-tournament form evaluate reactive races against those original finish times. Finale balancing also uses original thresholds. Visible standings, points and rewards still reflect the race that actually happened.
- Eyes have independent per-character phases and per-round seeds: left wink, right wink, both eyes shut, double blink or open eyes. Rendering does not consume gameplay randomness, and landed/podium expressions retain their open eyes.

Validation: `work/rival-pacing-check.gd` covers complete/partial cosmetic collections, player exclusions, stable tournament rosters, close-pack frequency over 500 rounds, 72 reactive races at 30/60/120 FPS, all six response orders, safe landings, immutable learning plans, normal-opening behavior, initial calibration and eye variants. Existing smoke, adaptive persistence and tournament adaptation checks also apply. No Android export is needed for these checks.
