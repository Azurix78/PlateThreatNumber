"""Build a clean, installable ZIP without tools, tests or generated caches."""
from pathlib import Path
import re
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
toc_name = "PlateThreatNumber.toc"
toc = (root / toc_name).read_text(encoding="utf-8")
version = re.search(r"^## Version: ([\d.]+)$", toc, re.MULTILINE).group(1)
files = [toc_name, "README.md"] + [
    line.strip() for line in toc.splitlines()
    if line.strip() and not line.startswith("#")
]
output = root / "dist" / f"PlateThreatNumber-{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(root / name, f"PlateThreatNumber/{name}")
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist()) == len(files)
print(f"Created {output} ({output.stat().st_size:,} bytes; {len(files)} files)")
