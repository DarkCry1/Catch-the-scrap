#!/usr/bin/env python3
"""Run portable logic checks, compile Roblox scripts, and build both place formats."""
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLOUD_BIN = Path('/workspace/.catch-the-scrap-tools/bin')


def tool(name):
    path = shutil.which(name)
    if path:
        return path
    fallback = CLOUD_BIN / name
    if fallback.is_file():
        return str(fallback)
    raise SystemExit(f'Missing tool: {name}. See docs/STUDIO_START_SV.md.')


def run(*args):
    print('+', *map(str, args), flush=True)
    subprocess.run(list(map(str, args)), cwd=ROOT, check=True)


def main():
    sources = sorted((ROOT / 'src').rglob('*.luau'))
    tests = sorted((ROOT / 'tests').rglob('*.luau'))
    run(tool('luau-analyze'), *sorted((ROOT / 'src/shared').glob('*.luau')), *tests)
    for test in tests:
        run(tool('luau'), test)
    # The standalone analyzer has no Roblox engine globals/types. The compiler
    # still checks every engine-facing script; runtime checks need Studio.
    run(tool('luau-compile'), '--null', *sources, *tests)
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    for extension in ('rbxlx', 'rbxl'):
        run(tool('rojo'), 'build', 'default.project.json', '--output', build / f'Catch-the-scrap.{extension}')
    root = ET.parse(build / 'Catch-the-scrap.rbxlx').getroot()
    items = list(root.iter('Item'))
    scripts = [node for node in items if node.attrib['class'] in ('Script', 'LocalScript', 'ModuleScript')]
    embedded = [node.find("./Properties/string[@name='Source']").text for node in scripts]
    assert sorted(embedded) == sorted(path.read_text(encoding='utf-8') for path in sources), 'Build must include all source files exactly once'
    assert sum(node.attrib['class'] == 'LocalScript' for node in scripts) == 1
    assert sum(node.attrib['class'] == 'Script' for node in scripts) == 1
    remotes = [node for node in items if node.attrib['class'] == 'RemoteEvent']
    assert {node.find("./Properties/string[@name='Name']").text for node in remotes} == {'Action', 'Feedback'}
    binary = build / 'Catch-the-scrap.rbxl'
    assert binary.read_bytes().startswith(b'<roblox!'), 'Expected a binary Roblox place'
    print(f'Build verified: {len(scripts)} scripts/modules and 2 remotes; both place formats generated.', flush=True)
    with zipfile.ZipFile(build / 'Catch-the-scrap-source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for folder in ('src', 'tests', 'scripts', 'docs'):
            for path in sorted((ROOT / folder).rglob('*')):
                if path.is_file() and '__pycache__' not in path.parts:
                    archive.write(path, Path('Catch-the-scrap') / path.relative_to(ROOT))
        for name in ('README.md', '.gitignore', 'default.project.json'):
            archive.write(ROOT / name, Path('Catch-the-scrap') / name)
    print('Source bundle: build/Catch-the-scrap-source.zip', flush=True)


if __name__ == '__main__':
    main()
