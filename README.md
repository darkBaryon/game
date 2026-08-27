# 星舰火种：最后方舟

一个面向 macOS 的 2D 生存经营 + Roguelite 探索原型。

当前版本验证最小核心循环：

1. 使用备用废料重启方舟反应堆。
2. 登陆废土，移动并自动攻击敌人。
3. 在战斗中选择异能强化，击败废土守卫。
4. 回收材料并返回星舰。
5. 使用材料修复生态舱，点亮方舟第一层并发现未知文明信号。
6. 继续恢复居民舱，唤醒首位具名幸存者并获得支援。

当前包含可跳过的“机器人唤醒舰长”序章、三种行动强化、三阶段方舟修复以及无需外部音频素材的程序化音效。

## 本机运行

项目使用 Godot 4.7.1 Standard 和 GDScript。

在 macOS 终端直接运行：

```bash
./run.sh
```

`run.sh` 会自动查找 Godot；如果安装在其他位置，可以使用 `GODOT_BIN=/path/to/Godot ./run.sh`。

## Codex 接第三方模型

如果你要让 Codex 通过 JD Cloud 的 Anthropic 接口工作，可以先起本地桥接服务：

```bash
export JD_MODEL_API_KEY='你的 JD Cloud key'
export JD_MODEL_ID='T-C-4-jy'
./tools/run_jdcloud_responses_bridge.sh --port 8000
```

然后在 `~/.codex/config.toml` 里配置：

```toml
model = "T-C-4-jy"
model_provider = "jdcloud-bridge"

[model_providers.jdcloud-bridge]
name = "JDCloud Anthropic bridge"
base_url = "http://127.0.0.1:8000/v1"
wire_api = "responses"
```

这个桥把 Codex 的 Responses 请求翻译成你现有的 `anthropic/v1/messages` 接口，所以不用改上游服务。

1. 使用 Godot 打开仓库根目录中的 `project.godot`。
2. 点击编辑器右上角运行按钮，或按 `F6/F5`。
3. 序章使用空格、回车或界面按钮推进。
4. 废土场景中使用 `WASD` 或方向键移动，武器会自动攻击最近目标。

命令行验证：

```bash
godot --headless --path . --editor --quit
godot --headless --path . --scene res://tests/smoke_test.tscn
```

## 技术约定

- 使用 typed GDScript。
- 文件和目录采用小写 `snake_case`。
- 游戏数值优先使用 Godot Resource，存档写入 `user://`。
- `.godot/`、导出产物和构建缓存不进入 Git。
- 二进制美术和音频素材后续使用 Git LFS 管理。

## 第三方资源

- Noto Sans SC（GB2312 字符子集），SIL Open Font License 1.1，许可证见 `assets/fonts/OFL-1.1.txt`。
