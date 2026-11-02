# 万象拼音增强包（Linux / fcitx5-rime）

给 [万象拼音](https://github.com/amzxyz/rime_wanxiang) 补上主流输入法的使用习惯：`v` 当 `ü`、儿化音、模糊音、乱序拼音自动纠错，以及科技 / 游戏 / 诗词分类词库。

全部离线运行，不联网、不上传输入内容。

在线介绍页：<https://onelasthuman.github.io/wanxiang-pinyin-kit/>

## 功能一览

| 功能 | 输入示例 | 效果 |
| --- | --- | --- |
| `v` 当 `ü` | `jvede` / `jvan` / `jvn` | 觉得 / 卷 / 均 |
| 儿化音 | `huar` / `yihuir` / `dianr` | 花儿 / 一会儿 / 点儿 |
| 模糊音（6 组） | `zi` 与 `zhi`、`lan` 与 `nan`、`ren` 与 `reng`、`jin` 与 `jing` | 互通的候选 |
| 乱序纠错 | `wxoianig` / `niaoh` / `zognghu` | 我想你 / 你好 / 中国 |
| 科技词库（6310 条） | `zhengzebiaodashi` | 正则表达式 |
| 游戏词库（118 条） | `shuangrenchengxing` | 双人成行 |
| 诗词库（可选，官方 33 万条） | `chunjianghuayueye` | 春江花月夜 |

## 适配环境

- 已在 Arch Linux + fcitx5-rime 实测：fcitx5-rime 5.1.16、librime 1.17、万象拼音 LTS 18.1.8
- 其他 Rime 前端（Weasel / Squirrel / ibus-rime）理论上通用，只是用户目录不同
- 需要已安装万象拼音（方案 `wanxiang`）

## 安装

### 一键安装

```bash
git clone https://github.com/OneLastHuman/wanxiang-pinyin-kit.git
cd wanxiang-pinyin-kit
bash install.sh
```

脚本会备份原文件、复制配置和词库、在 `wanxiang.dict.yaml` 里登记新词库，然后提示重新部署。

### 手动安装

1. 复制文件到 Rime 用户目录（fcitx5 通常是 `~/.local/share/fcitx5/rime`）：
   - `wanxiang.custom.yaml`、`my_algebra.yaml` → 用户目录根
   - `lua/fuzzy_corrector.lua`、`lua/fuzzy_dict.lua` → `lua/`
   - `dicts/keji.dict.yaml`、`dicts/youxi.dict.yaml` → `dicts/`
2. 编辑 `wanxiang.dict.yaml`，在 `import_tables` 末尾（`dicts/yiren` 之后）加：
   ```yaml
     - dicts/keji
     - dicts/youxi
   ```
3. 重新部署：`rime_deployer --build <用户目录> /usr/share/rime-data <用户目录>/build`
   或右键输入法图标 →「重新部署」。
4. 重启输入法进程（fcitx5 可直接重启对应服务，或结束进程后重新启动）。

### 诗词库（可选）

诗词数据较大（约 16 MB、33 万条），不在本仓库内。从万象官方发布页下载：

- <https://github.com/amzxyz/rime-wanxiang-data/releases/tag/dict-nightly> 的 `dicts.zip`
- 把其中的 `shici.dict.yaml` 放进 `dicts/`
- 在 `wanxiang.dict.yaml` 的 `import_tables` 里加一行 `- dicts/shici`
- 重新部署

## 各项功能说明

### 1. `v` 当 `ü`

万象默认只覆盖单音节 `jv → ju`，`jve` 会被拆成 `jv + e`（`jvede` 出「巨额的」）。`my_algebra.yaml` 补齐了 j/q/x/y 的所有韵母：

- `jve / qve / xve / yve` → `jue / que / xue / yue`
- `jvan / qvan / xvan / yvan` → `juan / quan / xuan / yuan`
- `jvn / qvn / xvn / yvn` → `jun / qun / xun / yun`

`lv / nv / lve / nve` 万象原本就支持。

### 2. 儿化音

`huar → 花儿`、`nar → 哪儿`、`zher → 这儿`、`yihuir → 一会儿`、`dianr → 点儿`、`haowanr → 好玩儿`。

副作用：单打一个 `r` 时，第一候选会变成「而 / 儿 / 二」（`r` 现在也是儿化音后缀）；打 `ren` 不受影响。

### 3. 模糊音

默认开启 6 组：

| 组 | 效果 |
| --- | --- |
| `z / zh` | `zi` 与 `zhi` 候选相同 |
| `c / ch` | `ci` 与 `chi` 相同 |
| `s / sh` | `si` 与 `shi` 相同 |
| `n / l` | `lan` 与 `nan` 相同 |
| `en / eng` | `ren` 与 `reng` 相同 |
| `in / ing` | `jin` 与 `jing` 相同 |

万象还提供 4 组可选项，按需在 `wanxiang.custom.yaml` 的 `__patch` 列表里加一行即可：

```yaml
      - wanxiang_algebra:/模糊音_hf   # h / f
      - wanxiang_algebra:/模糊音_rl   # r / l
      - wanxiang_algebra:/模糊音_ry   # r / y
      - wanxiang_algebra:/模糊音_kg   # k / g
```

### 4. 乱序拼音自动纠错

基于 [linnin233/rime-fuzzy-pinyin](https://github.com/linnin233/rime-fuzzy-pinyin)（MIT）改造：

- 只在输入无法切分为合法拼音时触发，正常拼音不受影响
- 算法：字符重合度（Sørensen–Dice）+ 顺序保留度（LCS）+ 长度匹配，取综合分最高的候选
- 词表由万象自身 149 万词条按词频生成：3962 组拼音、4362 个常用词
- 每个拼音键的字符计数在加载时预计算，结果按输入缓存，单次约 20–30 ms

实测：

| 输入 | 候选 |
| --- | --- |
| `wxoianig` | 我希望、我想、**我想你** |
| `niaoh` | **你好**、你要、那是 |
| `jinaitn` | **今天**、金钱、今年 |
| `zognghu` | 公主、总会、终于、中午、**中国** |
| `rugo` | **如果**、国、过 |
| `jnjii` | 基金、**经济**、仅仅 |
| `nihap` | **你好**、遗憾、害怕 |
| `zhonggup` | **中国**、正规、众多 |

限制：排序只看字母相似度，不看词频，个别时候想打的词不是第一位（如 `zognghu` 的「中国」在第 5 位）。

### 5. 分类词库

- **科技**（6310 条）：来自清华大学开源中文词库 THUOCL 的计算机词表，加上现代科技词；只保留万象基础词库中缺失的词，带声调拼音。
- **游戏**（118 条）：常用游戏术语与热门游戏名（如「双人成行」「崩坏星穹铁道」「艾尔登法环」）。
- **诗词**（可选）：万象官方 `shici` 词库，诗题、诗句、作者齐全。

## 重新生成纠错词表

词表按你本机安装的万象词库生成，不同版本略有差异：

```bash
python3 scripts/gen_fuzzy_dict.py --rime-dir ~/.local/share/fcitx5/rime --top 4000
```

脚本会读取 `dicts/jichu.dict.yaml`，按词频取前 N 个 2–4 字词，与 `scripts/seed_fuzzy_dict.lua`（插件原词表）合并，输出 `lua/fuzzy_dict.lua`。

## 验证清单

部署并重启输入法后，依次输入：

| 输入 | 期望 |
| --- | --- |
| `jvede` | 觉得（第一候选） |
| `huar` | 花儿（第一候选） |
| `zi` / `zhi` | 两组候选相同 |
| `wxoianig` | 出现「我想你」 |
| `zhonggup` | 中国（第一候选） |
| `zhengzebiaodashi` | 正则表达式 |
| `shuangrenchengxing` | 双人成行 |

## 注意事项

- 万象升级会覆盖 `wanxiang.dict.yaml`，需要重新登记词库（重跑 `install.sh` 即可，脚本是幂等的）。`wanxiang.custom.yaml`、`my_algebra.yaml`、`lua/`、`dicts/` 不会被覆盖。
- 若你已自定义过 `wanxiang.custom.yaml`，请先备份并手动合并 `speller/algebra` 与 `engine/translators` 两段。
- 纠错只在「打乱」时追加候选，不会修改输入串，也不会影响正常拼音。

## 目录结构

```
.
├── wanxiang.custom.yaml          # 模糊音 + 纠错翻译器注册
├── my_algebra.yaml               # v 当 ü、儿化音规则
├── lua/
│   ├── fuzzy_corrector.lua       # 乱序纠错翻译器（改造版）
│   └── fuzzy_dict.lua            # 纠错词表（自动生成）
├── dicts/
│   ├── keji.dict.yaml            # 科技词库
│   └── youxi.dict.yaml           # 游戏词库
├── scripts/
│   ├── gen_fuzzy_dict.py         # 词表生成脚本
│   └── seed_fuzzy_dict.lua       # 插件原词表（254 条）
└── install.sh
```

## 许可与致谢

- 本仓库的配置、脚本、词库：MIT
- 纠错插件：[linnin233/rime-fuzzy-pinyin](https://github.com/linnin233/rime-fuzzy-pinyin)，MIT，见 `THIRD-PARTY.md`
- 万象拼音：CC BY 4.0，<https://github.com/amzxyz/rime_wanxiang>；纠错词表的词频来自万象词库
- 科技词库词条：清华大学开放中文词库 THUOCL，MIT
