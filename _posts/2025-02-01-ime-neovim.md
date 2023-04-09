---
title: 输入法的奇妙冒险： neovim 之风
tags:
  - develop
  - ime
---

你最喜欢的输入法——现在在 neovim 中可以使用了！ [rime.nvim](https://github.com/Freed-Wu/rime.nvim)

![IME inside Vim](https://github.com/user-attachments/assets/e35e9848-ba5d-478c-be80-953830cd8a65)

## 插件开发

我们在上一篇文章中讨论了 NeoVim 插件开发的一些方案。大体上分类如下：

- vim script: 很容易写出与 Vim 兼容的插件
- vim script 9: 一个性能更快但语法不兼容 vim script 的语言。目前对 Neovim 的支持还是[试验阶段](https://github.com/tjdevries/vim9jit)
- lua 但走 [lua-vimscript 桥](https://neovim.io/doc/user/lua.html#lua-vimscript)：大多数 Neovim 插件
- lua/python/ruby/perl/js 走 [msgpack-rpc 协议](https://neovim.io/doc/user/api.html#RPC)：利好一些依赖某些库的插件。比如将 VS Code 插件移植到 Vim 上需要的 coc.nvim 就要求用 nodejs 开发 Vim 插件
- 转译流： teal/fennel 翻译成 lua, ts/coffee script 翻译成 js
- C/C++/Rust: 走 FFI ，略过了 msgpack 的开销，性能更好（甚至都没必要这么好？），但开发难度就……

用 vim script 开发插件简单入门。但随着需求的变化很多问题暴露出来：

- 很多语言支持用 C 开发模块。比如 `#include <emacs-module.h>` 就可以用 C 开发
Emacs Lisp 模块等等。但 vim script 没有。
- vim script 到现在都没有标准化的依赖声明方法。想一想你用 `pip install
matplotlib` 时， `pip` 会自动发现 `numpy` 是一个依赖并将其提前安装好。而 Vim 社
区的开发者不得不在 README 中要求用户手动安装缺失的依赖。
- 一个统一的插件发布平台，就像 PYPI 之于 python, npm 之于 nodejs 。

在引入其他编程语言开发 Vim 插件前，社区也进行了一些有限但貌似徒劳的尝试：

- 用 C 语言开发一个动态链接库，然后在 vim script 中 `dlopen()` 它。例子： [vimtweak](https://github.com/mattn/vimtweak), [vim-xkbswitch](https://github.com/lyokha/vim-xkbswitch) 。或者用 C 语言开发一个可执行文件，然后在 vim script 中 `system()` 它。
- [`pkg.json`](https://packspec.org/): 语法是 npm 的 `package.json` 的子集。由
lazy.nvim 引入。未被 Vim 社区广泛采纳。
- vim.org: 该网站已近乎被废弃。社区中大多数开发者在 github 等代码托管网站上发布插件。

在引入其他编程语言后，一个非常棒的例子是 coc.nvim:

- 用 nodejs 开发 Vim 插件。 `#include <node_api.h>`, 轻轻松松 C 语言走起。
- `package.json` 声明依赖，然后 `npm install`。
- 使用 npm 托管 Vim 插件

在 Neovim 社区， lua 很快成了官方强推的插件开发语言：

- neovim 自带一个 luajit 解释器： `nvim -l`
- neovim 为 lua 提供了一个运行时 `vim` 。你可以使用 `vim.XXX` 调用自带的函数，而
不仅仅是 lua 的 `os`, `table`, `package`, ...
- neovim 除了 RPC 通讯的 `vim.api.nvim_*` 函数，更提供了 lua-vimscript 桥，允许
直接在 lua 中操作 vim script 环境

那么，一个类似 coc.nvim 但使用 lua 来解决上述难题的方案已经呼之欲出：

### rocks.nvim

[rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim) 完成了：

- 用 lua 开发 Vim 插件。现在是 `#include <lauxlib.h>`!
- `*.rockspec` 声明依赖，然后 `luarocks install`
- 使用 luarocks.org 托管 Vim 插件

除此外， rocks.nvim 还引入了 `rocks.toml` 让用户用 `Cargo.toml` 的语法声明需要安装的 Vim 插件。

作为一个尝试， rocks.nvim 面临和 coc.nvim 一样的问题：

生态。很多 Vim 插件并未被发布到 luarocks.org 上。所以该作者发起 [nurr](https://github.com/nvim-neorocks/nurr) 来将一些 Vim 插件发布到 luarocks.org 上。

打个比喻：先有充电桩还是先有电动汽车呢？如果我们担忧 luarocks.org 上没有足够多的
Vim 插件而拒绝将 luarocks 带入到 Vim 插件开发社区，那么我们永远也不会享受到 luarocks 带来的好处～

### 基于 lua 的 NeoVim 插件开发

Vim 插件的常见目录：

- plugin/: 必定会被加载的代码
- ftplugin/: 当某一特定类型文件被打开时会被加载的代码
- ftdetect/: 根据文件名和文件内容确定文件类型的代码
- lua/: lua 模块
- autoload/: Vim 模块
- doc/: 文档
- after/: 与当前目录相同的目录结构，例如 after/plugin ，但加载会被延迟以确保不会被覆盖。

作为一个输入法插件，我们只需要在 lua/ 中放置一个 lua 模块。然后让用户在配置中导入即可：

```lua
vim.keymap.set('i', '<C-^>', require('rime.nvim').toggle)
```

`rime.nvim` 实际上是 `lua/rime/nvim/init.lua` ……所有与 vim 运行时有关的代码都放
在 `lua/rime/nvim/` 下了 QAQ

当用户按下 Ctrl + 6 时，输入法会被切换到 rime 模式。

Neovim 提供了一些 API `vim.api.nvim_open_win()` 创建一个浮动窗口。我们在浮动窗口内绘制输入法的菜单界面。

然后是和前面相同的算法逻辑。

### 其他

- luaspec 的单元测试文件默认是 `spec/*_spec.lua` 。
- 目前并没有从 lua 代码注释生成 vim 文档的方法。但从 vim script 代码注释生成 vim 文档的方法有一个： [vimdoc](https://github.com/google/vimdoc)
- CI/CD 有 [luarocks-tag-release](https://github.com/nvim-neorocks/luarocks-tag-release)
- ldoc 可以从 lua 代码注释和 README 生成网站代码用于建设官网

一些奇特的地方：

用 C 语言开发 lua 的模块： lua 的栈设计太奇特了。这个恐怕只有体验过的开发者才能
get 到其中含义 ^_^

以上。我们成功地为 rime 增加了一堆命令行的前端。因为大多数算法逻辑是完全一样的，所以从第二篇文章开始后面就省略了这部分，侧重于每个平台移植的不同难点。

最后，贴上佛振本人的评价：

![interesting](https://github.com/user-attachments/assets/a1ee2f5d-5dbf-45f5-96d5-e34fad904e7e)
