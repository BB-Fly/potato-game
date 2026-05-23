from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


def has_alpha(image: Image.Image) -> bool:
    return image.mode in ("RGBA", "LA") or "transparency" in image.info


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    manifest_path = (
        root
        / "assets"
        / "art"
        / "source"
        / "handdrawn_replacement_v01"
        / "runtime_asset_manifest.json"
    )
    if not manifest_path.exists():
        print(f"Missing manifest: {manifest_path}", file=sys.stderr)
        return 2

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    issues: list[str] = []

    for item in manifest:
        path = root / item["path"]
        if not path.exists():
            issues.append(f"missing: {item['path']}")
            continue

        with Image.open(path) as image:
            if image.size != (item["width"], item["height"]):
                issues.append(
                    f"size: {item['path']} expected "
                    f"{item['width']}x{item['height']} got {image.width}x{image.height}"
                )
            if has_alpha(image) != item["has_alpha"]:
                issues.append(
                    f"alpha: {item['path']} expected {item['has_alpha']} got {has_alpha(image)}"
                )

    if issues:
        print("Art asset validation failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print(f"Validated {len(manifest)} runtime art PNG files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
