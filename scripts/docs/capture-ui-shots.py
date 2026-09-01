#!/usr/bin/env python3
"""Capture VirtFoundry UI screenshots for helm-charts docs."""

from __future__ import annotations

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:18080"
OUT = Path(__file__).resolve().parents[2] / "docs" / "assets" / "screenshots"
PAGES = [
    ("02-dashboard.png", "/dashboard"),
    ("03-vms.png", "/vms"),
    ("08-vm-snapshots.png", "/vm-snapshots"),
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1440, "height": 900}, device_scale_factor=2)
        page.goto(f"{BASE}/login", wait_until="networkidle")
        page.get_by_role("button", name="EN", exact=True).click()
        page.get_by_placeholder("root or tenant-admin").fill("root")
        page.get_by_placeholder("••••••••").fill("virtfoundry")
        page.get_by_role("button", name="Sign in").click()
        page.wait_for_url("**/dashboard", timeout=30000)
        for filename, path in PAGES:
            page.goto(f"{BASE}{path}", wait_until="networkidle")
            page.wait_for_timeout(2000)
            target = OUT / filename
            page.screenshot(path=str(target), full_page=False)
            print(f"wrote {target}")
        browser.close()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)
