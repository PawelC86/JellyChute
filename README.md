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

CAREER POINTS on the main menu accumulates the player’s safe-round placement points across all tournaments and character choices. Completed rounds save their award immediately, with a guard against duplicate awards; crashes award zero. Returning to menu retains earned points. A gold star badge and a smoothly counting total sit above the confirmation button. Existing saves default the new total to zero.

Progress uses Godot ConfigFile AES-256 encrypted saves at user://records.dat. Writes go to an encrypted temporary file, are verified by decryption, then replace the previous save. Existing user://records.cfg data is migrated automatically and plaintext is removed only after successful replacement. Unreadable saves are preserved and automatic overwrites are blocked. The application-held password protects against casual inspection/editing; it is not a server-side anti-cheat boundary. Tests and preview captures preserve both legacy and encrypted user files.

Safe landings briefly trigger an exaggerated chest-out, hands-on-hips proud pose with sparkles. The podium cycles through a runner-up standing on tiptoe toward the winner, the winner leaning defensively, third place nibbling a bronze medal, and a crown slipping over the winner’s eyes. Platform signs rotate among twelve absurd safety notices with no immediate repeats. These are cosmetic and do not alter flight physics or scores.

The altitude gauge is a continuous green→orange→red gradient. Its red boundary is calculated from the same 120Hz parachute-inflation/braking integration used by gameplay; opening at terminal speed in the solid red region crashes. The fixed PULL marker is removed. Completed rounds update an encrypted player-skill profile using safe landings, deployment precision and placement. Skill changes by at most 0.08 per round; opponent deployment heights adapt only between rounds, preserving shuffled difficulty tiers and random form. Player physics and the gauge never change with skill.

The tournament champion holds a gold two-handled trophy in the right hand. The cup is anchored to the arm’s animated grip and follows the winner’s bounce; round-result podiums do not award the tournament trophy.

Three seconds after the first landing (safe or crash), the camera slides to ground over 1.6 seconds and holds for 2 seconds. Airborne racers keep flying outside the finish-line camera and are not teleported to the ground. Remaining classification is resolved with identical physics after this live view, before the results screen. The deadline resets each round.

The project and Google Play icon is assets/icons/google-play.png: enlarged Mango without parachute on a full opaque turquoise square, 512x512 RGBA, sRGB, under 1MB. application/config/icon points to this asset. Separate transparent Mango foreground: assets/icons/android-foreground.png.

The menu has separate upper arrows for four parachute designs and lower arrows for four jellies. Up/down changes the chute; left/right changes the jelly. CONFIRM & JUMP saves both choices together in the encrypted settings. Old saves default the chute to the saved character color. The chosen chute is used in the menu and flight; rivals retain their own canopies.

Normal completed rounds go to results 0.8 seconds after all racers land, without waiting for the first-landing deadline. The 1.6-second camera descent and 2-second ground hold apply only when the camera actually has to scroll down to the finish line.
