"""Resize generated parachute artwork to small transparent runtime textures."""
from pathlib import Path
from PIL import Image
import json
ROOT = Path(__file__).resolve().parents[1]
IDS = ("underpants", "cow", "royal", "breakfast", "patched", "disco", "bling", "cat", "dog")
source = ROOT / "work/source-art/chutes"
target = ROOT / "assets/toon/chutes"
target.mkdir(parents=True, exist_ok=True)
report = []
for name in IDS:
    src = source / (name + ".png")
    with Image.open(src) as original:
        assert original.mode == "RGBA", (name, original.mode)
        # Numerical bounds ignore faint alpha haze without painting or recolouring artwork.
        bounds = original.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0).getbbox()
        assert bounds, name
        x0,y0,x1,y1 = bounds
        bounds = (max(0,x0-3),max(0,y0-3),min(original.width,x1+3),min(original.height,y1+3))
        image = original.crop(bounds)
        image.thumbnail((384,256), Image.Resampling.LANCZOS)
        dst = target / (name + ".png")
        image.save(dst, optimize=True, compress_level=9)
        assert image.width <= 384 and image.height <= 256
        report.append({"id":name,"source_bytes":src.stat().st_size,"runtime_bytes":dst.stat().st_size,"runtime_size":list(image.size)})
        print(name, list(image.size), dst.stat().st_size)
(target / "sizes.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print("Total runtime PNG bytes:",sum(item["runtime_bytes"] for item in report))
