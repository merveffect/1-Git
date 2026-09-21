#!/usr/bin/env python3
"""Bundle the app into one self-contained HTML file.

No npm, no toolchain, no third-party code: the modules are wrapped in a tiny
CommonJS-style registry and inlined together with the stylesheet, so the result
opens straight from disk (file://) and works offline.

    python3 finance/build.py
"""

from __future__ import annotations

import posixpath
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
ENTRY = "main.js"
OUT = ROOT / "dist" / "finance-tracker.html"

IMPORT_NAMED = re.compile(r"^\s*import\s*\{(.*?)\}\s*from\s*['\"]([^'\"]+)['\"];?\s*$", re.S | re.M)
IMPORT_STAR = re.compile(r"^\s*import\s*\*\s*as\s*(\w+)\s*from\s*['\"]([^'\"]+)['\"];?\s*$", re.M)
IMPORT_BARE = re.compile(r"^\s*import\s*['\"]([^'\"]+)['\"];?\s*$", re.M)
EXPORT_DECL = re.compile(r"^export\s+(async\s+function|function|const|let|var|class)\s+(\w+)", re.M)
EXPORT_LIST = re.compile(r"^export\s*\{([^}]*)\};?\s*$", re.M)


def resolve(importer: str, spec: str) -> str:
    """Resolve a relative specifier against the importing module's directory."""
    if not spec.startswith("."):
        raise SystemExit(f"{importer}: only relative imports are supported, got {spec!r}")
    return posixpath.normpath(posixpath.join(posixpath.dirname(importer), spec))


def transform(module_id: str, source: str) -> tuple[str, list[str]]:
    """Rewrite ES module syntax into registry calls. Returns (code, exported names)."""
    exported: list[str] = []

    def named(match: re.Match) -> str:
        bindings = ", ".join(
            re.sub(r"(\w+)\s+as\s+(\w+)", r"\1: \2", part.strip())
            for part in match.group(1).split(",")
            if part.strip()
        )
        return f'const {{ {bindings} }} = __require("{resolve(module_id, match.group(2))}");'

    code = IMPORT_NAMED.sub(named, source)
    code = IMPORT_STAR.sub(
        lambda m: f'const {m.group(1)} = __require("{resolve(module_id, m.group(2))}");', code)
    code = IMPORT_BARE.sub(
        lambda m: f'__require("{resolve(module_id, m.group(1))}");', code)

    if re.search(r"^\s*import\s", code, re.M):
        raise SystemExit(f"{module_id}: unsupported import syntax left after transform")
    if "export default" in code:
        raise SystemExit(f"{module_id}: default exports are not supported by this bundler")

    for match in EXPORT_DECL.finditer(code):
        exported.append(match.group(2))
    code = EXPORT_DECL.sub(lambda m: f"{m.group(1)} {m.group(2)}", code)

    for match in EXPORT_LIST.finditer(code):
        for part in match.group(1).split(","):
            name = part.strip().split(" as ")[-1].strip()
            if name:
                exported.append(name)
    code = EXPORT_LIST.sub("", code)

    return code, exported


def collect(entry: str) -> dict[str, str]:
    """Walk the import graph from the entry module and transform every file."""
    modules: dict[str, str] = {}
    queue = [entry]
    seen = set()
    while queue:
        module_id = queue.pop()
        if module_id in seen:
            continue
        seen.add(module_id)
        path = SRC / module_id
        if not path.exists():
            raise SystemExit(f"missing module: {module_id}")
        source = path.read_text(encoding="utf-8")
        for match in IMPORT_NAMED.finditer(source):
            queue.append(resolve(module_id, match.group(2)))
        for match in IMPORT_STAR.finditer(source):
            queue.append(resolve(module_id, match.group(2)))
        for match in IMPORT_BARE.finditer(source):
            queue.append(resolve(module_id, match.group(1)))
        code, exported = transform(module_id, source)
        assignments = ", ".join(exported)
        body = f"{code}\n  Object.assign(__exports, {{ {assignments} }});"
        modules[module_id] = body
    return modules


def build() -> None:
    modules = collect(ENTRY)
    parts = [
        "(function () {",
        "'use strict';",
        "const __factories = {};",
        "const __cache = {};",
        "function __require(id) {",
        "  if (__cache[id]) return __cache[id];",
        "  const __exports = {};",
        "  __cache[id] = __exports;",
        "  __factories[id](__exports, __require);",
        "  return __exports;",
        "}",
    ]
    for module_id in sorted(modules):
        parts.append(f'__factories["{module_id}"] = function (__exports, __require) {{')
        parts.append(modules[module_id])
        parts.append("};")
    parts.append(f'__require("{ENTRY}");')
    parts.append("})();")
    script = "\n".join(parts)

    html = (ROOT / "index.html").read_text(encoding="utf-8")
    css = (SRC / "styles.css").read_text(encoding="utf-8")
    html = html.replace(
        '<link rel="stylesheet" href="src/styles.css">',
        f"<style>\n{css}\n</style>",
    )
    html = html.replace(
        '<script type="module" src="src/main.js"></script>',
        f"<script>\n{script}\n</script>",
    )
    html = html.replace(
        "<body>",
        "<body>\n<!-- Built by finance/build.py - a single offline file, no external requests. -->",
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(html, encoding="utf-8")
    size = OUT.stat().st_size
    print(f"built {OUT.relative_to(ROOT.parent)} ({size / 1024:.0f} KB, {len(modules)} modules)")


if __name__ == "__main__":
    sys.exit(build())
