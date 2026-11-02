# 第三方组件与许可

本仓库包含或改写了以下第三方内容，使用时请保留相应署名。

## rime-fuzzy-pinyin

- 来源：<https://github.com/linnin233/rime-fuzzy-pinyin>
- 许可：MIT License，Copyright (c) 2026 linnin233（全文见 `licenses/rime-fuzzy-pinyin-MIT.txt`）
- 使用方式：`lua/fuzzy_corrector.lua` 在其基础上做了三处修改：
  1. 补充 `v` 当 `ü` 与儿化音 `r` 的合法音节；
  2. 预计算词表字符计数、按输入缓存匹配结果，降低单次计算耗时；
  3. 匹配逻辑改为使用预计算数据。
- `scripts/seed_fuzzy_dict.lua` 为其原始词表（254 条），用于合并生成新词表。

## 万象拼音（rime-wanxiang）

- 来源：<https://github.com/amzxyz/rime_wanxiang>
- 许可：Creative Commons Attribution 4.0 International（CC BY 4.0）
- 使用方式：`lua/fuzzy_dict.lua` 由万象基础词库 `dicts/jichu.dict.yaml` 的词条与词频生成；`dicts/keji.dict.yaml` 在生成时用万象词库去重。未复制万象的配置文件。

## THUOCL（清华大学开放中文词库）

- 来源：<https://github.com/thunlp/THUOCL>
- 许可：MIT License，Copyright (c) 2018 THUNLP
- 使用方式：`dicts/keji.dict.yaml` 的词条来自其 `THUOCL_IT.txt`，拼音由本仓库脚本标注，并剔除万象基础词库已有的词。

## 雾凇拼音（rime-ice）

- 来源：<https://github.com/iDvel/rime-ice>
- 用途：生成科技词库时仅用于校对多音字读音，未在本仓库中分发其任何文件。
