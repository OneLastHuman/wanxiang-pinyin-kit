#!/usr/bin/env bash
# 万象拼音增强包安装脚本（幂等，可重复运行）
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RIME_DIR="${1:-${RIME_DIR:-}}"
if [ -z "$RIME_DIR" ]; then
  for d in "$HOME/.local/share/fcitx5/rime" "$HOME/.config/ibus/rime" "$HOME/Library/Rime"; do
    if [ -f "$d/wanxiang.dict.yaml" ]; then RIME_DIR="$d"; break; fi
  done
fi

if [ -z "${RIME_DIR:-}" ] || [ ! -f "$RIME_DIR/wanxiang.dict.yaml" ]; then
  echo "错误：找不到万象拼音的用户目录（里面应有 wanxiang.dict.yaml）。" >&2
  echo "用法：bash install.sh /path/to/rime/user/dir" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$RIME_DIR/backup-$STAMP"
mkdir -p "$BACKUP" "$RIME_DIR/lua" "$RIME_DIR/dicts"

echo "Rime 用户目录：$RIME_DIR"
echo "备份目录：$BACKUP"

for f in wanxiang.custom.yaml my_algebra.yaml; do
  if [ -f "$RIME_DIR/$f" ]; then cp "$RIME_DIR/$f" "$BACKUP/"; fi
done
[ -f "$RIME_DIR/wanxiang.dict.yaml" ] && cp "$RIME_DIR/wanxiang.dict.yaml" "$BACKUP/"

cp "$HERE/wanxiang.custom.yaml" "$RIME_DIR/"
cp "$HERE/my_algebra.yaml" "$RIME_DIR/"
cp "$HERE/lua/fuzzy_corrector.lua" "$RIME_DIR/lua/"
cp "$HERE/lua/fuzzy_dict.lua" "$RIME_DIR/lua/"
cp "$HERE/dicts/keji.dict.yaml" "$RIME_DIR/dicts/"
cp "$HERE/dicts/youxi.dict.yaml" "$RIME_DIR/dicts/"

python3 - "$RIME_DIR" <<'PY'
import re, sys
from pathlib import Path

rime = Path(sys.argv[1])
path = rime / 'wanxiang.dict.yaml'
lines = path.read_text(encoding='utf-8').splitlines()


def active(name):
    return any(re.match(rf'^\s*-\s*{re.escape(name)}(?:\s|$)', line) for line in lines)


changed = False

# 有诗词库文件时，把官方模板里注释掉的 shici 行恢复
if (rime / 'dicts/shici.dict.yaml').exists():
    for i, line in enumerate(lines):
        if re.match(r'^\s*#\s*-\s*dicts/shici(?:\s|$)', line):
            lines[i] = re.sub(r'^(\s*)#\s*', r'\1', line)
            changed = True

needed = []
if (rime / 'dicts/shici.dict.yaml').exists() and not active('dicts/shici'):
    needed.append(('dicts/shici', '更多诗词'))
needed += [('dicts/keji', '科技词汇'), ('dicts/youxi', '游戏术语与游戏名')]
missing = [(name, comment) for name, comment in needed if not active(name)]

if missing:
    anchors = [i for i, line in enumerate(lines) if re.match(r'^\s*-\s*dicts/', line)]
    if not anchors:
        raise SystemExit('无法在 wanxiang.dict.yaml 的 import_tables 中找到 dicts/ 条目，请手动添加')
    insert_at = anchors[-1] + 1
    new_lines = [f'  - {name:<16} # {comment}' for name, comment in missing]
    lines[insert_at:insert_at] = new_lines
    changed = True

if changed:
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('已更新 wanxiang.dict.yaml 的 import_tables')
else:
    print('wanxiang.dict.yaml 无需修改')
PY

cat <<EOF

完成。接下来：
  1) 重新部署（二选一）：
     rime_deployer --build "$RIME_DIR" /usr/share/rime-data "$RIME_DIR/build"
     或右键输入法托盘图标 →「重新部署」
  2) 重启输入法进程（让 Lua 插件和词库生效）
  3) 验证：输入 jvede → 觉得；huar → 花儿；zhonggup → 中国

如需诗词库：把官方 dicts.zip 里的 shici.dict.yaml 放进 $RIME_DIR/dicts/，再运行一次本脚本。
EOF
