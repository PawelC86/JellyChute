# Jelly collection

Nine additional characters use the same painted bean torso, plum ink, cream eye shapes, brown harness and animated face system as the four original jellies.

| ID | Name | Separate animated detail |
| --- | --- | --- |
| cat | Sir Pounce | Curved tail, feline stretch, whiskers |
| dog | Barkley | Wagging tail, floppy ears, tongue, eager hop |
| dragon | Toasty | Flapping wings, horned crest, little fangs |
| bling | 2 CHAINZ, NO BONES | Fitted sideways cap, two gold necklaces, bracelet, gold-tooth grin |
| bee | Buzzbert | Fluttering wings, antennae, honey stripes |
| unicorn | Sir Sparkles | Pastel mane and tail, gold horn, cheek stars |
| robot | Wobblebot | Turning key, antenna, panel smile, stepped idle motion |
| ghost | Booberry | Wisp trail, curled tuft, floating idle motion |
| chef | Chef Wobble | Anchored toque, neckerchief, moustache |

Each RGBA PNG (512 x 512 for the original collection; 1254 x 1254 for the generated bling atlas) is a 2 x 2 atlas: body (upper left), headpiece (upper right), arm (lower left), extra (lower right). Faces remain blank in the painted body and are drawn at runtime for all flight, crash and podium expressions. Existing dark boots and four parachutes are shared. Nine characters appear in a 3 x 3 grid in the Jellies shop tab; new characters are locked until purchased for credits. Prices are 200 (bee, ghost, chef), 300 (dragon, robot), and 500 (cat, dog, bling, unicorn). Advertising is not integrated.

Art generated with the built-in image_gen tool using `../actors.png` and `../style-reference.png` as binding references. Full prompt records: `generation-prompts.json`. Runtime PNGs use lossless compression, preserve alpha and are downsampled with Lanczos. `sizes.json` records actual source/runtime byte sizes. Run `python work/prepare_collection.py` from the project root to rebuild from archived originals.

Original atlases are kept locally in `work/source-art/collection/`. Source art, backup and preview folders are ignored by Git and contain `.gdignore` so they do not become Godot resources or enter a normal resource export. Production PNGs, import metadata and scripts remain versioned. No Android package size is claimed until an actual export is built.

Headpieces are anchored by their painted centre underside, embedded in the scalp and drawn with the same transform as the body. No independent vertical hat motion is applied during flight or landing. Free tails, wings, headband ribbons and the wind-up key retain their own animation. Atlas bounds and contact ratios are generated into `atlas_regions.gd`, a preloaded resource included in exports.

2 CHAINZ, NO BONES replaces the ninja at persistent character ID 7. Its source atlas is kept at native resolution with alpha intact; atlas regions reference each image's native pixels. The cap uses a narrower fitted rectangle and deeper scalp seating, and the chains are painted over the lower torso after the animated face. The card occupies bottom-center via CHARACTER_SHOP_ORDER; its two-line name and portrait share that card's placement. Built-in generation prompt: ../../../work/bling-prompt.txt. Ownership of the former ninja transfers automatically because the numeric ID is unchanged.

Dragon, unicorn and chef headpieces use deeper individual scalp seating (HEAD_SEAT_Y) while retaining the exact body transform through flight and landing. The revised chef toque has a solid front band with no visible opening, underside or rear rim; its source prompt is chef-hat-prompts.json.
