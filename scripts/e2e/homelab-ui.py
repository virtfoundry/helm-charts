#!/usr/bin/env python3
"""UI end-to-end on a live VirtFoundry: deploy a VM through the wizard and check the post-deploy panel.

Covers: wizard steps, review, deploy, IP shown, "copy ssh" button, console button, "Open VM" link,
VM detail page. The VM is deleted through the API at the end, also when a check fails.

  VF_PASSWORD=... [VF_USER=root] [VF_UI_URL=http://virtfoundry.homelab] \
    [VF_TEMPLATE=Cirros] [VF_SSH_KEY=<name>] python scripts/e2e/homelab-ui.py

Needs: pip install playwright && playwright install chromium. Creates one VM named vf-ui-e2e-<n>
in the default tenant; the cluster must be able to schedule it (the default offering is small).
"""

from __future__ import annotations

import json
import os
import random
import re
import sys
import time
import urllib.request

from playwright.sync_api import sync_playwright

BASE = os.environ.get("VF_UI_URL", "http://virtfoundry.homelab").rstrip("/")
USER = os.environ.get("VF_USER", "root")
PASSWORD = os.environ.get("VF_PASSWORD", "")
TEMPLATE = os.environ.get("VF_TEMPLATE", "Cirros")
SSH_KEY = os.environ.get("VF_SSH_KEY", "")
NAME = f"vf-ui-e2e-{random.randint(10000, 99999)}"
IP_RE = re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b")

results: list[tuple[bool, str]] = []


def check(ok: bool, what: str) -> bool:
    results.append((ok, what))
    print(("PASS  " if ok else "FAIL  ") + what, flush=True)
    return ok


def api(method: str, path: str, token: str, body: dict | None = None, tenant: str = "") -> dict:
    req = urllib.request.Request(f"{BASE}/api/v1{path}", method=method, data=json.dumps(body).encode() if body is not None else None)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    if tenant:
        req.add_header("X-Tenant-ID", tenant)
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    return json.loads(raw) if raw else {}


def login_token() -> str:
    req = urllib.request.Request(f"{BASE}/api/v1/auth/login", method="POST", data=json.dumps({"username": USER, "password": PASSWORD}).encode())
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)["token"]


def cleanup() -> None:
    try:
        token = login_token()
        tenant = next(t["id"] for t in api("GET", "/tenants", token)["tenants"] if t["slug"] == "default")
        api("POST", "/vms/delete", token, {"name": NAME}, tenant)
        for _ in range(40):
            names = [v["name"] for v in api("GET", "/vms", token, tenant=tenant).get("vms", [])]
            if NAME not in names:
                check(True, f"cleanup: {NAME} deleted")
                return
            time.sleep(3)
        check(False, f"cleanup: {NAME} still listed after 120s")
    except Exception as exc:  # noqa: BLE001 - report, never mask the test result
        check(False, f"cleanup failed: {exc}")


def body_text(page) -> str:
    return re.sub(r"\s+", " ", page.inner_text("body"))


def run() -> None:
    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True)
        ctx = browser.new_context(viewport={"width": 1440, "height": 900})
        page = ctx.new_page()
        try:
            page.goto(f"{BASE}/login", wait_until="networkidle")
            page.get_by_role("button", name="EN", exact=True).click()
            page.get_by_placeholder("root or tenant-admin").fill(USER)
            page.get_by_placeholder("••••••••").fill(PASSWORD)
            page.get_by_role("button", name="Sign in").click()
            page.wait_for_url("**/dashboard", timeout=30000)
            check(True, "login")

            page.goto(f"{BASE}/vms", wait_until="networkidle")
            page.wait_for_timeout(4000)  # let the catalogs load before opening the wizard
            page.get_by_role("button", name=re.compile("Deploy VM", re.I)).first.click()

            page.get_by_placeholder("web-server-01").fill(NAME)
            card = page.get_by_text(TEMPLATE, exact=False).first
            card.wait_for(timeout=15000)
            card.click()
            check(True, f"wizard: name and template {TEMPLATE}")

            nxt = page.get_by_role("button", name=re.compile(r"^(Next|Próximo)$"))
            for _ in range(2):  # Compute -> Disk -> Network
                nxt.first.click()
                page.wait_for_timeout(600)
            check(bool(re.search("isolat|isolad", body_text(page), re.I)), "wizard: network step offers isolated networks")
            nxt.first.click()  # -> Access
            page.wait_for_timeout(600)
            sel = page.locator("select").filter(has_text=re.compile("SHA256|None|Nenhuma|—")).first
            if SSH_KEY:
                sel.select_option(label=re.compile(f"^{re.escape(SSH_KEY)}"))
            else:
                sel.select_option(index=1)
            nxt.first.click()  # -> Review
            page.wait_for_timeout(800)
            review = body_text(page)
            check(NAME in review and "Offering" in review, "wizard: review shows the name and the offering")

            page.get_by_role("button", name=re.compile(r"^(Deploy|Implantar)$")).last.click()
            page.get_by_text(re.compile("Deploy progress|Progresso do deploy")).first.wait_for(timeout=30000)
            check(NAME in body_text(page), "post-deploy: progress panel shows the VM name")

            ip = ""
            deadline = time.time() + 240
            while time.time() < deadline:
                m = IP_RE.search(body_text(page).split("Primary IP")[-1]) if "Primary IP" in body_text(page) else None
                if m:
                    ip = m.group(0)
                    break
                page.wait_for_timeout(3000)
            check(bool(ip), f"post-deploy: IP shown ({ip or 'never appeared'})")

            # Match the visible text: the VM list behind the modal has icon buttons with the same aria-label.
            copy = page.locator("button").filter(has_text=re.compile(r"Copy ssh|Copiar ssh"))
            check(copy.count() > 0 and copy.first.is_enabled(), "post-deploy: copy ssh button enabled")
            if copy.count() and copy.first.is_enabled():
                # The UI is often served over plain HTTP, where navigator.clipboard does not exist and the
                # UI falls back to execCommand: check the visible feedback instead of reading the clipboard.
                copy.first.click()
                page.wait_for_timeout(500)
                check(page.get_by_text(re.compile("Copied|Copiado")).count() > 0, "post-deploy: copy ssh gives 'Copied' feedback")

            console = page.locator("button").filter(has_text=re.compile(r"Open VNC console|Abrir console VNC"))
            check(console.count() == 1 and console.first.is_enabled(), "post-deploy: console button enabled")

            page.get_by_role("link", name=re.compile(r"Open VM|Abrir VM")).first.click()
            page.wait_for_url(f"**/vms/{NAME}", timeout=15000)
            try:
                page.get_by_text(NAME).first.wait_for(timeout=15000)
                check(True, "Open VM: detail page loads with the VM")
            except Exception:  # noqa: BLE001
                check(False, "Open VM: detail page never showed the VM name")
        except Exception as exc:  # noqa: BLE001
            check(False, f"unexpected error: {type(exc).__name__}: {str(exc).splitlines()[0]}")
        finally:
            browser.close()


if __name__ == "__main__":
    if not PASSWORD:
        sys.exit("set VF_PASSWORD (and VF_USER, VF_UI_URL if needed)")
    try:
        run()
    finally:
        cleanup()
    bad = [w for ok, w in results if not ok]
    print(f"RESULT: {len(results) - len(bad)} pass, {len(bad)} fail")
    sys.exit(1 if bad else 0)
