#!/usr/bin/env python3
"""从万象拼音词库生成乱序纠错词表 lua/fuzzy_dict.lua。

用法：
    python3 scripts/gen_fuzzy_dict.py --rime-dir ~/.local/share/fcitx5/rime --top 4000
"""
import argparse
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

TONE = {}
for chars, base in [('āáǎà', 'a'), ('ēéěè', 'e'), ('īíǐì', 'i'),
                    ('ōóǒò', 'o'), ('ūúǔù', 'u'), ('ǖǘǚǜ', 'v'),
                    ('ńňǹ', 'n'), ('ḿ', 'm')]:
    for c in chars:
        TONE[c] = base


def strip_tone(s):
    return ''.join(TONE.get(c, c) for c in s).replace('ü', 'v')


def load_valid_syllables():
    lua = (REPO / 'lua/fuzzy_corrector.lua').read_text(encoding='utf-8')
    valid = set(re.findall(r'\["([a-z]+)"\]=1', lua))
    valid |= {'jve', 'qve', 'xve', 'yve', 'jvan', 'qvan', 'xvan', 'yvan',
              'jvn', 'qvn', 'xvn', 'yvn', 'r'}
    return valid


def load_seed():
    seed = {}
    text = (REPO / 'scripts/seed_fuzzy_dict.lua').read_text(encoding='utf-8')
    for m in re.finditer(r'\["([a-z]+)"\] = \{ (.*) \}', text):
        seed[m.group(1)] = re.findall(r'"([^"]+)"', m.group(2))
    return seed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rime-dir', default=str(Path.home() / '.local/share/fcitx5/rime'))
    ap.add_argument('--top', type=int, default=4000)
    ap.add_argument('--output', default=str(REPO / 'lua/fuzzy_dict.lua'))
    args = ap.parse_args()

    rime = Path(args.rime_dir)
    jichu = rime / 'dicts/jichu.dict.yaml'
    if not jichu.exists():
        raise SystemExit(f'找不到 {jichu}，请确认万象拼音已安装，或用 --rime-dir 指定目录')

    valid = load_valid_syllables()
    words, seen = [], set()
    for line in jichu.read_text(encoding='utf-8').splitlines():
        if line.startswith('#') or '\t' not in line:
            continue
        parts = line.split('\t')
        if len(parts) < 3:
            continue
        word, code = parts[0], parts[1].strip()
        try:
            weight = int(parts[2])
        except ValueError:
            continue
        if not re.fullmatch(r'[\u4e00-\u9fff]{2,4}', word) or word in seen:
            continue
        syls = [strip_tone(x) for x in code.split()]
        if not syls or any(x not in valid for x in syls):
            continue
        seen.add(word)
        words.append((weight, word, ''.join(syls)))

    words.sort(reverse=True)
    groups = {}
    for _, word, key in words[:args.top]:
        bucket = groups.setdefault(key, [])
        if len(bucket) < 3 and word not in bucket:
            bucket.append(word)

    for key, items in load_seed().items():
        bucket = groups.setdefault(key, [])
        for word in items:
            if word not in bucket and len(bucket) < 4:
                bucket.append(word)

    out = ['-- 自动生成的模糊纠错词典：万象基础词库高频词 + 插件原词表',
           'return {']
    for key in sorted(groups):
        items = ', '.join(f'"{w}"' for w in groups[key])
        out.append(f'  ["{key}"] = {{ {items} }},')
    out.append('}')
    Path(args.output).write_text('\n'.join(out) + '\n', encoding='utf-8')
    print(f'写入 {args.output}：{len(groups)} 组拼音，'
          f'{sum(len(v) for v in groups.values())} 个词')


if __name__ == '__main__':
    main()
