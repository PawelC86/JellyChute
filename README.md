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

On first launch, choose STAR, MANGO, BUBBLES or PICKLE using the four menu buttons before starting. Selection is saved and can be changed from the main menu. The selected jelly is the central menu hero and always occupies player slot zero (the left race lane); the other three identities fill the opponent slots. Their canopy, accessories, pad, UI colour and name follow their identity. The menu uses separate logo, hero, selection and record bands to prevent art/text overlaps.

Bubbles’ beret has a fitted band overlapping the upper head, with its crown seated lower. Pink’s headband is replaced by an outlined blond quiff with highlights and swept strands.

A MENU button in the upper-right corner returns from countdown, race, landing reactions, round results and the final podium. Escape does the same on desktop. Returning abandons the current tournament and resets transient race state while retaining character selection and saved records. The button is hidden on the main menu.

Each new tournament shuffles three opponent difficulties exactly once: CHILL JELLIES, WOBBLE PROS and JELLY ACES. The order stays fixed for its three rounds. Rivals open progressively later (21.5–23.5m, 18.5–20.5m, 16–17.5m), yielding faster safe finishes with the same flight physics as the player. Starting altitude remains independently randomized for a 2–4 second freefall to the green band.

Character selection is a two-arrow carousel with wraparound, colour dots and an animated sliding/bouncing hero. Left/Right keys also browse. CONFIRM & JUMP is the only bottom button; it saves the previewed character and starts a new tournament. Browsing alone does not overwrite the saved preference.

Main action buttons share flat candy colours with plum borders and shadows. Menu and flight helper copy is a non-interactive child label inset at the bottom of the button; the main title sits above it. No helper text is drawn below the button.

Star’s blond quiff and its highlight strands flutter with descent speed, with roots fixed to the head. Rival difficulty is tighter: base deployments at 18.6–20m, 17–18.6m and 16–17m. Each round adds shared random form (±0.7m) and each rival adds individual variation (±0.3m), clamped to 15.5–21m. Targets remain fixed throughout the jump. Difficulty bands can overlap while their average skill remains ordered.

Podium bubbles draw from 30 place-specific jokes and 12 character-specific jokes, rotating speakers every 2.8 seconds with a short pause. A place never repeats its previous line immediately. Dialogue uses independent randomness so reading the results does not change race difficulty or starting heights.

Round and tournament leaderboards use separate aligned rows, medal place markers, character portraits, player-coloured highlighting and explicit time/points headings. Countdown captions sit below the number inside a compact badge at y=263–292, with progress dots at y=307 above character accessories.

CREDITS on the main menu shows the spendable wallet. Each completed three-round tournament pays the sum of safe-round placement points once: 10/7/4/2 per round, zero for a crash. No credits or lifetime career points are paid during the first two rounds or for an abandoned tournament. Spending credits does not reduce lifetime career points. Old saves initialize the wallet from accumulated career points; a previously confirmed premium character is retained during migration.

Progress uses Godot ConfigFile AES-256 encrypted saves at user://records.dat. Writes go to an encrypted temporary file, are verified by decryption, then replace the previous save. Existing user://records.cfg data is migrated automatically and plaintext is removed only after successful replacement. Unreadable saves are preserved and automatic overwrites are blocked. The application-held password protects against casual inspection/editing; it is not a server-side anti-cheat boundary. Tests and preview captures preserve both legacy and encrypted user files.

Safe landings briefly trigger an exaggerated chest-out, hands-on-hips proud pose with sparkles. The podium cycles through a runner-up standing on tiptoe toward the winner, the winner leaning defensively, third place nibbling a bronze medal, and a crown slipping over the winner’s eyes. Platform signs rotate among twelve absurd safety notices with no immediate repeats. These are cosmetic and do not alter flight physics or scores.

The altitude gauge is a continuous green→orange→red gradient. Its red boundary is calculated from the same 120Hz parachute-inflation/braking integration used by gameplay; opening at terminal speed in the solid red region crashes. The fixed PULL marker is removed. Completed rounds update an encrypted player-skill profile using safe landings, deployment precision and placement. Skill changes by at most 0.08 per round; opponent deployment heights adapt only between rounds, preserving shuffled difficulty tiers and random form. Player physics and the gauge never change with skill.

The tournament champion holds a gold two-handled trophy in the right hand. The cup is anchored to the arm’s animated grip and follows the winner’s bounce; round-result podiums do not award the tournament trophy.

Three seconds after the first landing (safe or crash), the camera slides to ground over 1.6 seconds and holds for 2 seconds. Airborne racers keep flying outside the finish-line camera and are not teleported to the ground. Remaining classification is resolved with identical physics after this live view, before the results screen. The deadline resets each round.

The project and Google Play icon is assets/icons/google-play.png: enlarged Mango without parachute on a full opaque turquoise square, 512x512 RGBA, sRGB, under 1MB. application/config/icon points to this asset. Separate transparent Mango foreground: assets/icons/android-foreground.png.

The menu has separate upper arrows for four parachute designs and lower arrows for four jellies. Up/down changes the chute; left/right changes the jelly. CONFIRM & JUMP saves both choices together in the encrypted settings. Old saves default the chute to the saved character color. The chosen chute is used in the menu and flight; rivals retain their own canopies.

Normal completed rounds go to results 0.8 seconds after all racers land, without waiting for the first-landing deadline. The 1.6-second camera descent and 2-second ground hold apply only when the camera actually has to scroll down to the finish line.

## Additional jelly collection

Nine additional painted jellies extend the original four: Sir Pounce (cat), Barkley (dog), Toasty (dragon), Sneaky Bean (ninja), Buzzbert (bee), Sir Sparkles (unicorn), Wobblebot (robot), Booberry (ghost), and Chef Wobble (chef). Owned characters can be previewed and confirmed in the existing character carousel; four unique racers still participate in each race. New selections persist with the existing encrypted progress format. Parachutes are selected independently; the four original canopies are free and nine additional cosmetics are available in the shop.

The Jellies shop tab displays the nine new characters in three columns and three rows. Locked characters are dimmed and marked with a lock. Purchase buttons show 200/300/500-credit prices, then EQUIP or EQUIPPED after ownership. Cat, dog and unicorn cost 500; dragon, ninja and robot cost 300; bee, ghost and chef cost 200. Purchases validate funds and ownership and roll back if saving fails. Ads are not integrated. `assets/toon/collection/README.md` documents asset layout and optimization. `work/capture-collection.gd` verifies and captures all new characters in the menu, freefall, open-chute and crash states plus shop/podium views. Local source art and capture outputs are excluded from Git and Godot resource scanning.

`work/economy-check.gd` verifies wallet migration, prices, purchase/equip states, insufficient funds, save rollback, locked carousel filtering, complete-tournament-only rewards, zero rewards for crashes, persistence and duplicate payout protection.

## Purchasable parachutes

The Parachutes shop tab contains Emergency Underpants, Holy Cow! and Flying Breakfast for 150 credits; Royal Flush, Definitely Safe, Disco Drop, Purrfect Landing and Woof Woof for 200; Bling Bling for 500. These are cosmetic canopies with unchanged flight physics. Each is a compact transparent painted PNG, maximum 384 x 256, documented in assets/toon/chutes/README.md.

Owned parachutes persist separately from owned jellies. Both shops use BUY, EQUIP and EQUIPPED; successful purchases appear in the respective main-menu arrow selector, while locked items are skipped. Equipping in a shop saves immediately; browsing on the main menu saves only on CONFIRM & JUMP. Existing saves retain all four free canopies. work/chute-check.gd verifies purchases, insufficient funds, save rollback, fresh-instance reload, main-menu selection of purchased jellies and all nine parachutes, plus in-flight rendering and shop states.

## Branded boot splash

The engine boot splash uses assets/toon/boot-splash.png: the selected cream illustration with the JellyChute logo and the four jellies packing parachutes. The opaque PNG is downsampled to 800 x 1279 and uses lossless compression. Boot stretch mode Keep preserves the full illustration and its proportions; linear filtering is enabled. Uncovered screen areas use the sampled cream #fdf3db background. The engine default Godot image is replaced; no extra scene or artificial startup delay is added. Full-resolution source remains in the ignored splash-proposals preview folder. work/capture-boot-splash.gd validates the configured image and captures portrait, tall-phone and wider-screen layouts.
