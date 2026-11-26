# Cosmetic parachutes

Nine standalone painted canopies extend the four original parachutes. Thick plum outlines, gouache/cel shading, creamy highlights and cloth seams match the original actors atlas. No physics or race advantage changes.

| ID | Name | Credits |
| --- | --- | ---: |
| underpants | Emergency Underpants | 150 |
| cow | Holy Cow! | 150 |
| royal | Royal Flush | 200 |
| breakfast | Flying Breakfast | 150 |
| patched | Definitely Safe | 200 |
| disco | Disco Drop | 200 |
| bling | Bling Bling | 500 |
| cat | Purrfect Landing | 200 |
| dog | Woof Woof | 200 |

PNG artwork is generated with built-in image_gen using ../actors.png as style reference. Prompts: generation-prompts.json. Runtime files preserve transparency, use lossless PNG compression and fit within 384 x 256 pixels. Run python work/prepare_chutes.py from the project root to prepare runtime files from the locally archived originals in work/source-art/chutes. Originals and preview images remain excluded from Git and Godot export.

The four original canopies are always owned. Paid canopies persist independently in wallet/owned_chutes; settings/chute stores the equipped ID. The shop supports BUY, EQUIP and EQUIPPED. Main-menu arrows skip locked items, include all owned items and save the choice on CONFIRM & JUMP. Equipping in the shop saves immediately. Parachutes work with every owned jelly.

Royal Flush uses a repeating pattern of smaller toilets, toilet-paper rolls and plungers on burgundy cloth, rather than large central emblems. The updated prompt and original prompt are recorded together in generation-prompts.json. Runtime PNG sizes are recorded in sizes.json.

Disco Drop uses many small curved silver mirror tiles and painted star glints. Bling Bling instead uses gold cloth, diamonds and chain ornaments. Purrfect Landing has tabby stripes and triangular ears; Woof Woof has caramel patches and floppy ears. Existing item IDs remain unchanged, preserving prior purchases and equipped items.

Bling Bling has a diamond-encrusted dollar emblem, costs 500 credits and occupies the bottom-centre shop card, between Purrfect Landing and Woof Woof. Display ordering is separate from saved item IDs.
