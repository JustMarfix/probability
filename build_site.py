"""Assemble the GitHub Pages site into ./_site.

Copies the static viewer from ./site, adds the PDFs listed in
site/manifest.json, and stamps the build info the viewer shows in its header.

Run it after compile_all.py; with no arguments it derives the version from git,
which is handy for checking the viewer locally:

    python compile_all.py && python build_site.py && python -m http.server -d _site
"""

import argparse
import json
import shutil
import subprocess
import tarfile
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).parent
SRC = ROOT / "site"
OUT = ROOT / "_site"
CACHE = ROOT / ".cache"

PDFJS_VERSION = "4.10.38"
PDFJS_TARBALL = f"https://registry.npmjs.org/pdfjs-dist/-/pdfjs-dist-{PDFJS_VERSION}.tgz"
# Only the ES module build and its worker; everything else in the package is
# the stock viewer, which we do not use.
PDFJS_FILES = ("build/pdf.min.mjs", "build/pdf.worker.min.mjs")


def git(*args: str, default: str = "") -> str:
    try:
        return subprocess.run(
            ["git", *args], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return default


def vendor_pdfjs(dest: Path) -> None:
    """Copy the pdf.js runtime into the site, downloading it once if needed."""
    cached = CACHE / f"pdfjs-dist-{PDFJS_VERSION}.tgz"
    if not cached.is_file():
        CACHE.mkdir(exist_ok=True)
        print(f"Downloading pdf.js {PDFJS_VERSION}")
        with urllib.request.urlopen(PDFJS_TARBALL, timeout=120) as response:
            cached.write_bytes(response.read())

    dest.mkdir(parents=True, exist_ok=True)
    with tarfile.open(cached) as tar:
        for name in PDFJS_FILES:
            member = tar.extractfile(f"package/{name}")
            if member is None:
                raise SystemExit(f"{name} is missing from {cached.name}")
            (dest / Path(name).name).write_bytes(member.read())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", help="label shown in the viewer, e.g. v2026-10-06-0de91ba")
    parser.add_argument("--commit", help="full commit sha")
    parser.add_argument("--date", help="build date, YYYY-MM-DD")
    parser.add_argument("--repo", default="JustMarfix/probability", help="owner/name on GitHub")
    args = parser.parse_args()

    build_date = args.date or date.today().isoformat()
    commit = args.commit or git("rev-parse", "HEAD", default="")
    short = commit[:7] or "local"
    version = args.version or f"v{build_date}-{short}"

    manifest = json.loads((SRC / "manifest.json").read_text(encoding="utf-8"))

    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)
    vendor_pdfjs(OUT / "vendor" / "pdfjs")

    missing = []
    for edition in manifest["editions"]:
        pdf = ROOT / edition["file"]
        if pdf.is_file():
            shutil.copy2(pdf, OUT / edition["file"])
        else:
            missing.append(edition["file"])

    if missing:
        raise SystemExit(
            "Missing compiled PDFs: " + ", ".join(missing) + "\nRun compile_all.py first."
        )

    manifest.update(
        version=version,
        pdfjs=PDFJS_VERSION,
        commit=commit,
        date=build_date,
        releaseUrl=f"https://github.com/{args.repo}/releases/latest",
    )
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    total = sum(f.stat().st_size for f in OUT.rglob("*") if f.is_file())
    print(f"Built {OUT.relative_to(ROOT)} for {version} ({total / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
