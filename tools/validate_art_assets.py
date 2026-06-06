from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


def has_alpha(image: Image.Image) -> bool:
    return image.mode in ("RGBA", "LA") or "transparency" in image.info


def main() -> int:
	root = Path(__file__).resolve().parents[1]
	asset_registry_path = root / "content" / "base" / "assets" / "base_assets.json"
	if not asset_registry_path.exists():
		print(f"Missing asset registry: {asset_registry_path}", file=sys.stderr)
		return 2

	registry = json.loads(asset_registry_path.read_text(encoding="utf-8"))
	issues: list[str] = []
	checked = 0

	for item in registry.get("entries", []):
		asset_path = str(item.get("path", ""))
		if not asset_path.startswith("res://assets/art/") or not asset_path.endswith(".png"):
			continue
		path = root / asset_path.removeprefix("res://")
		if not path.exists():
			issues.append(f"missing: {asset_path}")
			continue

		with Image.open(path) as image:
			if item.get("kind") in {"icon", "sprite", "ui", "vfx"} and image.width <= 0:
				issues.append(f"empty image: {asset_path}")
			if item.get("kind") in {"icon", "sprite", "vfx"} and not has_alpha(image):
				issues.append(f"alpha: {asset_path} expected transparent-capable art")
			checked += 1

	if issues:
		print("Art asset validation failed:")
		for issue in issues:
			print(f"- {issue}")
		return 1

	print(f"Validated {checked} registered runtime art PNG files.")
	return 0


if __name__ == "__main__":
    raise SystemExit(main())
