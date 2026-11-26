# Jelly collection

Nine additional characters use the same painted bean torso, plum ink, cream eye shapes, brown harness and animated face system as the four original jellies.

| ID | Name | Separate animated detail |
| --- | --- | --- |
| cat | Sir Pounce | Curved tail, feline stretch, whiskers |
| dog | Barkley | Wagging tail, floppy ears, tongue, eager hop |
| dragon | Toasty | Flapping wings, horned crest, little fangs |
| ninja | Sneaky Bean | Attached indigo hood and mask, gold-emblem band, flowing red ribbons |
| bee | Buzzbert | Fluttering wings, antennae, honey stripes |
| unicorn | Sir Sparkles | Pastel mane and tail, gold horn, cheek stars |
| robot | Wobblebot | Turning key, antenna, panel smile, stepped idle motion |
| ghost | Booberry | Wisp trail, curled tuft, floating idle motion |
| chef | Chef Wobble | Anchored toque, neckerchief, moustache |

Each `512 x 512` RGBA PNG is a 2 x 2 atlas: body (upper left), headpiece (upper right), arm (lower left), extra (lower right). Faces remain blank in the painted body and are drawn at runtime for all flight, crash and podium expressions. Existing dark boots and four parachutes are shared. Nine characters appear in a 3 x 3 grid in the Jellies shop tab; new characters are locked until purchased for credits. Prices are 200 (bee, ghost, chef), 300 (dragon, ninja, robot), and 500 (cat, dog, unicorn). Advertising is not integrated.

Art generated with the built-in image_gen tool using `../actors.png` and `../style-reference.png` as binding references. Full prompt records: `generation-prompts.json`. Runtime PNGs use lossless compression, preserve alpha and are downsampled with Lanczos. `sizes.json` records actual source/runtime byte sizes. Run `python work/prepare_collection.py` from the project root to rebuild from archived originals.

Original atlases are kept locally in `work/source-art/collection/`. Source art, backup and preview folders are ignored by Git and contain `.gdignore` so they do not become Godot resources or enter a normal resource export. Production PNGs, import metadata and scripts remain versioned. No Android package size is claimed until an actual export is built.

Headpieces are anchored by their painted centre underside, embedded in the scalp and drawn with the same transform as the body. No independent vertical hat motion is applied during flight or landing. Free tails, wings, headband ribbons and the wind-up key retain their own animation. Atlas bounds and contact ratios are generated into `atlas_regions.gd`, a preloaded resource included in exports.

Sneaky Bean redesign: hood and lower mask are painted into the torso, so both share every body deformation. The separate crimson forehead band stays anchored to the hood; only its free ribbons move. Store portraits retain the original centred body placement at (72, 125) and uniform 1.1 scale. Each portrait is drawn inside a Control with clip_contents enabled, inset 3px from the card border and ending above its name. Long ribbons, wings and tails are clipped at the card edge without shifting or shrinking the character.

Dragon, unicorn and chef headpieces use deeper individual scalp seating (HEAD_SEAT_Y) while retaining the exact body transform through flight and landing. The revised chef toque has a solid front band with no visible opening, underside or rear rim; its source prompt is chef-hat-prompts.json.
