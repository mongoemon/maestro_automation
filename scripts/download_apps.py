"""
Download app binaries (APK / IPA) defined in scripts/apps.yaml.

Usage:
    python scripts/download_apps.py              # download both platforms
    python scripts/download_apps.py --android    # Android only
    python scripts/download_apps.py --ios        # iOS only
    python scripts/download_apps.py --force      # re-download even if file exists

Private GitHub repos: set GITHUB_TOKEN env var before running.
    Windows:  $env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
    Mac/CI:   export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
"""

import argparse
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = Path(__file__).resolve().parent / "apps.yaml"
APPS_DIR = REPO_ROOT / "app"


def load_config() -> dict:
    with open(CONFIG_FILE, encoding="utf-8") as f:
        return yaml.safe_load(f)


def resolve_url(platform_cfg: dict, source: str) -> str:
    key = f"{source}_url"
    url = platform_cfg.get(key, "").strip()
    if not url:
        print(f"  [ERROR] '{key}' is empty in apps.yaml. Fill in the URL and retry.")
        sys.exit(1)
    return url


def download(url: str, dest: Path, token: str | None, force: bool) -> bool:
    if dest.exists() and not force:
        print(f"  [SKIP]  {dest.name} already exists (use --force to re-download)")
        return False

    print(f"  [GET]   {url}")
    dest.parent.mkdir(parents=True, exist_ok=True)

    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"token {token}")
    # GitHub redirects release assets — follow redirects transparently
    req.add_header("Accept", "application/octet-stream")

    try:
        with urllib.request.urlopen(req) as response:
            total = response.headers.get("Content-Length")
            total_mb = f"{int(total) / 1_048_576:.1f} MB" if total else "unknown size"
            print(f"  [SIZE]  {total_mb}")
            with open(dest, "wb") as f:
                chunk_size = 1024 * 64
                downloaded = 0
                while chunk := response.read(chunk_size):
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total:
                        pct = downloaded * 100 // int(total)
                        print(f"\r  [....] {pct:3d}%", end="", flush=True)
            print(f"\r  [OK]   {dest.name}")
            return True
    except urllib.error.HTTPError as e:
        print(f"\r  [FAIL] HTTP {e.code}: {e.reason}")
        if e.code == 401:
            print("         Set GITHUB_TOKEN env var for private repos.")
        if e.code == 404:
            print("         URL not found — check the tag/filename in apps.yaml.")
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"\r  [FAIL] {e.reason}")
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Download app binaries for testing.")
    parser.add_argument("--android", action="store_true", help="Android only")
    parser.add_argument("--ios", action="store_true", help="iOS only")
    parser.add_argument("--force", action="store_true", help="Re-download if file exists")
    args = parser.parse_args()

    # Default: download both when no flag given
    do_android = args.android or not (args.android or args.ios)
    do_ios = args.ios or not (args.android or args.ios)

    config = load_config()
    source = config.get("source", "saucelabs").strip()
    token = os.environ.get("GITHUB_TOKEN")

    if source == "private" and not token:
        print("[WARN] source=private but GITHUB_TOKEN is not set.")
        print("       Public private_url will still work; private repos will get HTTP 401.")
        print()

    print(f"Source : {source}")
    print(f"Token  : {'set' if token else 'not set'}")
    print()

    if do_android:
        print("-- Android --")
        cfg = config["android"]
        url = resolve_url(cfg, source)
        dest = APPS_DIR / "android" / cfg["filename"]
        download(url, dest, token, args.force)
        print()

    if do_ios:
        print("-- iOS --")
        cfg = config["ios"]
        url = resolve_url(cfg, source)
        dest = APPS_DIR / "ios" / cfg["filename"]
        download(url, dest, token, args.force)
        print()

    print("Done.")


if __name__ == "__main__":
    main()
