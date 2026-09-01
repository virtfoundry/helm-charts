#!/usr/bin/env python3
"""Render kubectl-style terminal output as a documentation PNG."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True).rstrip("\n")


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFMono-Regular.otf",
        "/System/Library/Fonts/Menlo.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size, index=1 if bold and path.endswith(".ttc") else 0)
            except OSError:
                continue
    return ImageFont.load_default()


def colorize(line: str) -> tuple[str, tuple[int, int, int]]:
    if line.startswith("$"):
        return line, (120, 220, 255)
    if "Running" in line or "Ready" in line:
        return line, (120, 230, 160)
    if "NAME" in line and ("PHASE" in line or "CREATED" in line or "NAMESPACE" in line):
        return line, (180, 190, 210)
    if ".virtfoundry.io" in line:
        return line, (210, 180, 255)
    if line.startswith("virtfoundry-"):
        return line, (255, 210, 120)
    return line, (220, 225, 235)


def render(title: str, lines: list[str], out: Path, width: int = 1440) -> None:
    pad_x, pad_y = 48, 44
    line_h = 28
    font = load_font(18)
    title_font = load_font(22, bold=True)
    chrome_h = 52

    height = pad_y * 2 + chrome_h + len(lines) * line_h + 24
    img = Image.new("RGB", (width, height), (12, 16, 28))
    draw = ImageDraw.Draw(img)

    # window chrome
    draw.rounded_rectangle((24, 24, width - 24, height - 24), radius=18, fill=(18, 24, 40), outline=(45, 58, 86))
    draw.text((48, 38), title, font=title_font, fill=(230, 235, 245))
    draw.ellipse((width - 120, 40, width - 92, 68), fill=(255, 95, 86))
    draw.ellipse((width - 88, 40, width - 60, 68), fill=(255, 189, 46))
    draw.ellipse((width - 56, 40, width - 28, 68), fill=(39, 201, 63))

    y = 24 + pad_y + chrome_h
    for line in lines:
        text, fill = colorize(line)
        draw.text((48, y), text, font=font, fill=fill)
        y += line_h

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kubeconfig", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    import os

    def k(*cmd: str) -> str:
        return subprocess.check_output(
            ["kubectl", *cmd],
            text=True,
            env={**os.environ, "KUBECONFIG": args.kubeconfig},
        ).rstrip("\n")
    crds = k("get", "crd", "-o", "custom-columns=NAME:.metadata.name,SHORT:.spec.names.shortNames[0]", "--no-headers")
    crd_lines = ["$ kubectl get crd | grep virtfoundry.io", "NAME                              SHORTNAME"]
    for row in crds.splitlines():
        if "virtfoundry.io" not in row:
            continue
        parts = row.split()
        name = parts[0]
        short = parts[1] if len(parts) > 1 and parts[1] != "<none>" else "-"
        crd_lines.append(f"{name:<33} {short}")

    tenants = k(
        "get",
        "tenants.virtfoundry.io",
        "-o",
        "custom-columns=NAME:.metadata.name,PHASE:.status.phase,NAMESPACE:.status.namespace",
        "--no-headers",
    )
    tenant_lines = ["$ kubectl get vf-tenant", "NAME              PHASE   NAMESPACE"]
    for row in tenants.splitlines():
        parts = row.split()
        if len(parts) >= 3:
            tenant_lines.append(f"{parts[0]:<17} {parts[1]:<7} {parts[2]}")

    instances = k(
        "get",
        "instances.virtfoundry.io",
        "-A",
        "-o",
        "custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase,IP:.status.ip",
        "--no-headers",
    )
    inst_lines = ["$ kubectl get vf-instance -A", "NAMESPACE                    NAME     PHASE     IP"]
    for row in instances.splitlines():
        parts = row.split()
        if len(parts) >= 4:
            inst_lines.append(f"{parts[0]:<28} {parts[1]:<8} {parts[2]:<9} {parts[3]}")

    pods = k(
        "get",
        "pods",
        "-n",
        "virtfoundry-system",
        "-l",
        "app.kubernetes.io/part-of=virtfoundry",
        "-o",
        "custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,STATUS:.status.phase",
        "--no-headers",
    )
    pod_lines = ["$ kubectl get pods -n virtfoundry-system", "NAME                              READY   STATUS"]
    for row in pods.splitlines():
        parts = row.split()
        if len(parts) >= 3:
            ready = "true" if parts[1] == "true" else parts[1]
            pod_lines.append(f"{parts[0]:<33} {ready:<7} {parts[2]}")

    out = Path(args.out)
    all_lines = crd_lines + [""] + tenant_lines + [""] + inst_lines + [""] + pod_lines
    render("virtfoundry.io CRD store — homelab", all_lines, out)


if __name__ == "__main__":
    main()
