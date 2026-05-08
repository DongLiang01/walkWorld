#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


VAR_PATTERN = re.compile(
    r'(?P<prefix>=["\'])var\(\s*--[^,)\s]+(?:\s*,\s*(?P<fallback>[^)]+?))?\s*\)(?P<suffix>["\'])'
)


def normalize_svg_text(content: str) -> tuple[str, int, int]:
    replaced = 0
    skipped = 0

    def replacer(match: re.Match[str]) -> str:
        nonlocal replaced, skipped
        fallback = match.group("fallback")
        if fallback is None:
            skipped += 1
            return match.group(0)

        normalized = fallback.strip()
        if not normalized:
            skipped += 1
            return match.group(0)

        replaced += 1
        return f'{match.group("prefix")}{normalized}{match.group("suffix")}'

    updated = VAR_PATTERN.sub(replacer, content)
    return updated, replaced, skipped


def iter_svg_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path] if path.suffix.lower() == ".svg" else []
    if path.is_dir():
        return sorted(file for file in path.rglob("*.svg") if file.is_file())
    return []


def main() -> int:
    parser = argparse.ArgumentParser(
        description="将 SVG 中的 CSS 变量 var(--token, fallback) 替换为 fallback。"
    )
    parser.add_argument("paths", nargs="+", help="SVG 文件或目录路径")
    args = parser.parse_args()

    files: list[Path] = []
    for raw_path in args.paths:
        path = Path(raw_path)
        matched = iter_svg_files(path)
        if not matched:
            print(f"[skip] 未找到可处理的 SVG: {path}")
            continue
        files.extend(matched)

    unique_files = sorted(set(files))
    if not unique_files:
        print("没有可处理的 SVG 文件。")
        return 1

    changed_files = 0
    total_replaced = 0
    total_skipped = 0

    for file_path in unique_files:
        original = file_path.read_text(encoding="utf-8")
        updated, replaced, skipped = normalize_svg_text(original)
        total_skipped += skipped

        if replaced == 0:
            print(f"[ok] {file_path} 无需修改")
            continue

        file_path.write_text(updated, encoding="utf-8")
        changed_files += 1
        total_replaced += replaced
        print(f"[fix] {file_path} 替换 {replaced} 处")

    print(
        f"处理完成：共修改 {changed_files} 个文件，替换 {total_replaced} 处，保留 {total_skipped} 处无 fallback 的 var(...)。"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
