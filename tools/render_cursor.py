"""Export the mod-owned vector cursor. Build dependency: resvg-py==0.5.0."""
from pathlib import Path

import resvg_py


root = Path(__file__).resolve().parent.parent
source = root / "Assets" / "mcc_cursor.svg"
target = root / "Images" / "mcc_cursor.png"
target.write_bytes(resvg_py.svg_to_bytes(svg_path=str(source)))
print(f"Rendered {source.name} -> {target} ({target.stat().st_size} bytes)")
