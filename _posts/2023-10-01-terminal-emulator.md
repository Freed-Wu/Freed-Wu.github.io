---
title: 论终端模拟器的优劣
tags:
  - develop
---

这应该是全网第一篇终端模拟器比较的文章。

闲话少说：

| 终端模拟器比较          | 系统自带         | 跨平台（支持 Linux ） | 跨平台（支持 macOS ） | 跨平台（支持 win32 ） | 跨平台（支持 Android ） | 支持连字 | GPU 加速 | 背景透明（X11）  | 背景透明（Wayland） | 鼠标支持（URL） | 触控屏支持（单指滚动） | 触控屏支持（双指缩放） | 配置语言       | 开发语言 |
| ---------------- | ------------ | -------------- | -------------- | -------------- | ---------------- | ---- | ------ | ---------- | ------------- | --------- | ----------- | ----------- | ---------- | ---- |
| (u)xterm         | No           | Yes            | Yes            | No             | No               | No   | No     | No         | No            | No        | 拖动          | No          | No         | C    |
| gnome-terminal   | gnome        | Yes            | No             | No             | No               | No   | No     | Yes        | Yes           | No        | 拖动          | No          | dconf      | C    |
| konsole          | KDE          | Yes            | No             | No             | No               | Yes  | No     | Not test   | No            | No        | 拖动          | No          | dosini     | C++  |
| xfce4-terminal   | xfce         | Yes            | No             | No             | No               | No   | No     | Not test   | No            | No        | 长按拖动        | No          | xfconf     | C    |
| qterminal        | LXQt         | Yes            | Yes            | No             | No               | Yes  | No     | Yes        | Yes           | No        | 拖动          | No          | dosini     | C++  |
| kitty            | No           | Yes            | Yes            | No             | No               | Yes  | Yes    | Yes        | Yes           | Yes       | No          | No          | kitty conf | C++  |
| alacritty        | No           | Yes            | Yes            | Yes            | No               | No   | Yes    | Yes        | Yes           | Yes       | Yes         | Yes         | yaml       | rust |
| wezterm          | No           | Yes            | Yes            | Yes            | No               | Yes  | Yes    | Yes        | No            | Yes       | No          | No          | lua        | rust |
| termux           | termux       | No             | No             | No             | Yes              | Yes  | No     | Not needed | Not needed    | No        | Yes         | Yes         | properties | Java |
| mintty           | cygwin/msys2 | No             | No             | Yes            | No               | No   | No     | Not needed | Not needed    | No        | Not tested  | Not tested  | dosini     | C    |
| windows-terminal | Windows 10   | No             | No             | Yes            | No               | Yes  | Yes    | Not needed | Not needed    | Yes       | Not tested  | Not tested  | json       | C++  |

解释之前的温馨提醒：

- 关于终端、终端模拟器和伪终端看这篇[文章](https://xie.infoq.cn/article/a6153354865c225bdce5bd55e)就够了
- 如果没有看懂，记住：
  - 没有 GUI 界面的是终端
  - 有 GUI 界面的是终端模拟器
  - 终端模拟器（终端复用器也是）连接了伪终端

开始解释：

## 系统自带

在
[桌面环境](https://freed-wu.github.io/2023/08/01/combine-two-monitors-to-one-screen.html#%E6%A1%8C%E9%9D%A2%E7%8E%AF%E5%A2%83)
中已经知道：

> 桌面环境通常包含：
>
> - 终端模拟器

所以四大桌面都有自己的终端模拟器。除此之外，某些操作系统和软件发行版 (termux, cygwin, msys2) 也会预装终端模拟器。

## 跨平台

- 某些终端模拟器会使用跨平台的 GUI 库开发
  - gtk: gnome, xfce
  - qt: KDE, LXQt
- 某些不会
  - WinRT: windows-terminal [不会支持 Linux](https://github.com/microsoft/terminal/issues/504)
- 在
  [图形化用户界面](https://freed-wu.github.io/2023/08/01/combine-two-monitors-to-one-screen.html#%E5%9B%BE%E5%BD%A2%E5%8C%96%E7%94%A8%E6%88%B7%E7%95%8C%E9%9D%A2)
  中，已经讨论过支持 GNU/Linux/X 的软件基本都可以通过
  - Cygwin/X 支持 Windows
  - termux/X 支持 Android
- kitty 因为使用 GLFW 对输入法的支持配置比较麻烦

## 连字

![doesn't support](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/5c938b14-bc53-4abc-8c3d-2d536a940bd5)

![support](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/3b22eb5b-5e51-4142-8aa1-7ffec033660b)

支持连字需要满足 2 个条件：

- 终端模拟器支持
  - alacritty 因为连字影响性能[选择不支持](https://github.com/alacritty/alacritty/issues/50)
    据说 alacritty 比 kitty 和 wezterm 性能快一倍就是因为放弃了连字
- 字体支持
  - [Firacode](https://github.com/tonsky/FiraCode) 是第一个支持连字的字体
  - 笔者目前在用 [JetBrainsMono](https://github.com/JetBrains/JetBrainsMono)
  - 建议选用有 [nerd-fonts](https://github.com/ryanoasis/nerd-fonts) 补丁过的字体

## GPU 加速

可以通过以下方式查看终端模拟器是否使用了 GPU ：

- [intel_gpu_top](https://gitlab.freedesktop.org/drm/igt-gpu-tools): intel GPU
- [nvidia-smi](http://www.nvidia.com): nvidia GPU

## 背景透明

coding 时可以看到后面的窗口：

- 参考网页浏览器上的代码
- 写 HTML，LaTeX 时看输出的效果

注意， [window_background_opacity cannot work on wayland](https://github.com/wez/wezterm/issues/3766)
指出同时在以下条件下因为设计原因无法透明：

- 使用 Wayland
- 全屏

## 鼠标支持

<!-- markdownlint-disable MD033 -->

- 当鼠标移动到某个 URL 时改变鼠标形状
- 当鼠标移动到某个 URL 时可以用 <kbd>Shift</kbd> + 单击之类的快捷键打开该 URL 。

<!-- markdownlint-enable MD033 -->

## 触控屏支持

触控屏不是触控板。

支持触控屏需要满足 2 个条件：

- 终端模拟器支持触控屏（不仅仅是鼠标）
  - 目前仅有 alacritty [支持](https://github.com/alacritty/alacritty/pull/6695)
  - kitty [不支持](https://github.com/kovidgoyal/kitty/issues/5432)
  - wezterm [不支持](https://github.com/wez/wezterm/issues/792)
  - 四大桌面的终端模拟器在单指上下滑动的情况下只会拖动选中高亮文本，不会滚动。和设置 `export MOZ_USE_XINPUT2=1` 前的火狐浏览器类似。
    考虑到使用触控屏 GNU/Linux 设备的用户不多，所以对触控屏的支持之糟糕倒也情有可原。
- 终端软件支持鼠标，例如：
  - [tmux](https://github.com/tmux/tmux): `set -g mouse on`
  - ([neo](https://github.com/neovim/neovim))[vim](https://github.com/vim/vim): `set mouse=a`
  - [less](https://www.greenwoodsoftware.com/less/): `export LESS=--mouse`
  - [fzf](https://github.com/junegunn/fzf)/[skim](https://github.com/lotabout/skim): 默认开启，用 `--no-mouse` 关闭
  - [ptpython](https://github.com/prompt-toolkit/ptpython): `repl.enable_mouse_support = True`
  - [visidata](https://github.com/saulpw/visidata): 默认开启
  - ([neo](https://github.com/neomutt/neomutt))mutt: [不支持](https://github.com/neomutt/neomutt/issues/309)
  - [newsboat](https://github.com/newsboat/newsboat): [不支持](https://github.com/newsboat/newsboat/issues/1433)

## 配置语言

- 不少终端模拟器使用 dosini, json, yaml, properties 之类的数据描述语言。
  - 优点：可以轻易的提供一个图形化用户界面的配置按钮来修改配置。但注意 alacritty 没有提供图形化用户界面的配置按钮
  - 缺点：不能使用条件逻辑
- Kitty 使用 kitty config（一门 DSL ）来配置
  - 缺点：不能使用常见数据描述语言的语言服务器，语法高亮，必须另造轮子：
    - [vim-kitty](https://github.com/fladson/vim-kitty)
  - 优点：有一个 `include` 语法，可以在各个平台包含不同的文件 （这个文件需要被 gitignore ）实现不同平台统一一份点文件
- wezerm 使用 lua
  - 优点：可以用 `if`/`else`/`end` 实现不同平台统一一份点文件。例如，笔者希望在笔记本电脑和台式电脑上使用不同的字体（两台电脑屏幕大小不一样，字体自然也要不一样）

```lua
local wezterm = require 'wezterm'
local hostname = wezterm.hostname()
local font_size
if hostname == 'desktop' then -- 2560x2880
    font_size = 16
elseif hostname == 'laptop' then -- 3120x2080
    font_size = 12
else
    font_size = 12
end
```

## 开发语言

不说了，会挨打。

![best language](https://pic3.zhimg.com/80/v2-c93dfcee55886d5d3a18fd3c2edb8c56_1440w.webp)

## 其它

笔者根本不关心以下功能：

<!-- markdownlint-disable MD033 -->

- 分屏：这是终端复用器的工作
- 选择模式：选择终端上的某些字符。这是终端复用器的工作
- 下拉模式：有些终端模拟器可以按一个快捷键在显示和隐藏间切换，比如：
  - [guake](https://github.com/Guake/guake)
  - 笔者早年也用过，但后来随着时间推移，笔者基本上大多数情况下电脑只会开 2 个软件
    - 终端模拟器。在里面运行所有 TUI 软件，包括文本编辑器 (neovim) ，邮件客户端 (neomutt) ，版本控制 (git)
    - 网页浏览器
  - 所以直接 <kbd>Alt</kbd> + <kbd>Tab</kbd> 切换就可以了 :smile:

<!-- markdownlint-enable MD033 -->

终端复用器一般有如下功能：

- 分屏
- attach/detach: 把某个伪终端放在后台运行。嗯，笔者的惨痛教训：
  - 当年在图书馆 `ssh` 服务器跑深度学习模型，大概训练了一天到最后一个 epoch 了，然后图书馆关门就抱着笔记本电脑刚离开图书馆，网就断了，于是 `ssh` 失败， `shell` 向所有子进程发送 `HUP` 信号，笔者辛苦训练一天的结果就全没了。然后笔者就学会了怎么开 `tmux` 在后台 `detach` 一个进程了 :smile:
- 选择模式：通常会提供 vi 和 emacs 两种键盘映射

终端复用器目前的选择有如下：

<!-- markdownlint-disable MD033 -->

- [abduco](https://github.com/martanne/abduco/): 只支持 attach/detach 。通常和 dvtm 一起使用
- [dvtm](https://github.com/martanne/dvtm/): 只支持分屏。通常和 abduco 一起使用
- [screen](https://www.gnu.org/software/screen/): 最早的终端复用器
  - 默认使用 <kbd>Ctrl</kbd> + <kbd>A</kbd> 做前缀键
- [tmux](https://github.com/tmux/tmux): 目前最流行的终端复用器
  - 有一门 DSL
  - 拥有大量的插件生态。笔者也贡献了不少插件
  - 默认使用 <kbd>Ctrl</kbd> + <kbd>B</kbd> 做前缀键
- [zellij](https://github.com/zellij-org/zellij): rust 派的作品
  - 支持 wasm 格式的插件，插件开发门槛高于 tmux ，插件生态不如 tmux
  - 支持一个非常惊艳的分屏算法，比如 tmux 里先左右二等分屏再左右两边都上下二等分屏，这时增加左上屏的宽度，左下屏的宽度也会随之增加。因为在 tmux 的“认知”里，左边 2 个屏幕是一个整体，增加的是这个整体的宽度。相对的，增加左上屏的高度，右上屏的高度不会增加，因为它们不是一个整体。 `zellij` 用一个奇特的算法解决了这个问题。
  - 默认使用 <kbd>Ctrl</kbd> + <kbd>G</kbd> 做前缀键

为了不影响终端程序，终端复用器通常只有在一个前缀键按下的情况下才会通过等待第二个键来执行相对应的操作（分屏、attach/detach 等）。
这是常见设定，例如

- docker 拿 <kbd>Ctrl</kbd> + <kbd>p</kbd> 做前缀键，按 <kbd>Ctrl</kbd> + <kbd>P</kbd>, <kbd>Ctrl</kbd> + <kbd>Q</kbd> 或暂停。
- ssh 按 <kbd>CR</kbd>, <kbd>Ctrl</kbd> + <kbd>Z</kbd> 暂停。

笔者本人选择前缀键为 <kbd>Ctrl</kbd> + <kbd>Q</kbd> ，原因如下：

- <kbd>Ctrl</kbd> + <kbd>Q</kbd> 用左手按方便。 `tmux` 的 <kbd>Ctrl</kbd> + <kbd>A</kbd> 也是同样的原因
- <kbd>Ctrl</kbd> + <kbd>Q</kbd> 是用途最少的键。例如：
  - <kbd>Ctrl</kbd> + <kbd>A</kbd>:
    - 支持 readline 的软件：移动光标到行首
    - vi 风格软件：光标下的数字增加
  - <kbd>Ctrl</kbd> + <kbd>B</kbd>
    - 支持 readline 的软件：光标前移
    - vi 风格软件：向前翻页
  - <kbd>Ctrl</kbd> + <kbd>Q</kbd>
    - 支持 readline 的软件：解除屏幕冻结。默认 <kbd>Ctrl</kbd> + <kbd>S</kbd> 是屏幕冻结，但使用 `tmux` 后可以用：
      - 前缀键, <kbd>\[</kbd> 屏幕冻结
      - `q` 解除屏幕冻结
      - 所以建议直接在 `zsh` 中 `setopt noflowcontrol` 取消屏幕冻结相关的原生功能
    - vi 风格软件：功能与 <kbd>Ctrl</kbd> + <kbd>V</kbd> 相同，都是进入块选择模式。
    - 所以笔者使用一个功能都有重复的快捷键做前缀键不过分吧？

<!-- markdownlint-enable MD033 -->

## 总结

笔者目前选择如下：

- Android 手机上只能选 termux
- 虚拟机里的 Windows 上使用默认的 Windows terminal 即可
- 没有触控屏的 GNU/Linux 使用 wezterm
- 有触控屏的 GNU/Linux 使用 alacritty

撒花！
