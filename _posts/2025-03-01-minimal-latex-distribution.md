---
title: 一个超级小的 LaTeX 发行版
tags:
  - develop
  - tex
---

> “Every time I read a LaTeX document, I think, wow, this must be correct!”
>
> -- Prof. Christos Papadimitriou, [CS 170](https://cs170.org/resources/latex-guide/) Spring 2015

TeX Live, 绝大多数 LaTeX 用户使用的 LaTeX 发行版，在最近的版本 2024 中总体积已经
达到了惊人的 11 GB 。对此：

- 不少用户使用 [overleaf](https://www.overleaf.com/) 之类的在线平台免去本地安装
  的麻烦。不过针对离线脱机的情况就束手无策了。
- @clerkma 写了篇[文章](https://zhuanlan.zhihu.com/p/678423622)介绍怎么在安装
  TeX Live 时安装最小的内容，再通过 `tlmgr install` 安装用户需要的包。最终得到了
  一个体积 600 M ，不包含任何文档和源代码的 TeX Live 。最后他说：

> 600M的安装大小，好像还是很大。这是因为 TeX Live 中某些包的依赖关系比较模糊，还有一些优化的空间。

- @RadioNoiseE 写了[中文](https://zhuanlan.zhihu.com/p/13285492139)、
  [英文](https://kekkan.org/article/apltex-dist.xml)两篇文章介绍了如何开发一个最
  小的 plainTeX 发行版： aplTeX 。顺带一提这是一个递归缩写：
  aplTeX Provides Lean/Lite TeX

而笔者希望有这样一个 LaTeX 发行版：

- 体积足够小，本地安装非常方便，不必诉诸于在线平台。
- 能正确处理包的依赖关系，进一步优化空间。
- 支持 LaTeX ，而不仅仅是 plainTeX

下面介绍针对这一问题的一些技术选型和实验。

## 编译器

- 高德纳于 1978, 1982, 1990 年分别发布了 TeX 的三个大版本。此后， TeX 的开发被冻结，
  不再增加任何新功能。只有当小的 bug 修复时，才会有更新：版本号从 3.1 到 3.14 一
  直到如今的 3.141592653 ，象征着 TeX 像圆一样完美无缺。无独有偶，他的另一个字体
  设计软件 Metafont 版本号也是趋向于自然指数。传说如果你发现 bug ，高德纳就会寄
  一张他亲笔签名的支票给你。在国内因为《完全用 Linux 工作，抛弃 windows 》一文而
  赫赫有名的王垠竟然有两张。 :)
- TeX 3 停止开发急坏了希望得到更多新功能的开发者们。于是 NTS (新排版系统) 的项目
  启动了。他们 fork 了 TeX 3 开发了一个名为 eTeX (扩展 TeX) 的新编译器。相较原始
  的 TeX 3 ， eTeX 有如下改进。可以说后来所有的 TeX 编译器都是兼容 eTeX 的。
  - 寄存器可用数目从 256 增加到了 32768 。
  - 支持更多原语，例如读取文件的 \readline 和数学计算的 \numexpr
- 迄今为止所有的 TeX 输出的文件格式都是 dvi 。这是一种设备无关文件，可以方便的送
  到打印机打印，或者在电脑上用 xdvi 查看。新的文件格式， ps 和 pdf 等很快占据了
  dvi 的市场。与时俱进的， pdfTeX 诞生了，提供了一个 `--output-format={dvi,pdf}`
  的命令行支持直接输出 pdf 。而此前必须用 dvipdf 或 dvipdfmx 的软件进行格式转换。
  pdfTeX 不支持 Unicode 。因为体积小巧，在只需要 ASCII 字符的英语国家仍然很受欢
  迎。
- 另一个编译器 XeTeX 克服了之前的 TeX 编译器不支持 Unicode 的问题，从而在国内流
  行起来。它输出 dvi 文件的一个扩展： xdvi 文件。然后调用 dvipdfmx 生成 pdf 文件。
- pTeX, upTeX, apTeX 等支持 Unicode ，输出 dvi 文件。在日本很受欢迎。
- LuaTeX 最早是 pdfTeX 的一个 fork ，添加了 Unicode 支持。合并了另一个编译器
  Aleph 的代码从而支持四个方向的文字排版。 Aleph 前身的 Omega 甚至支持八个方向。
  相比较其他编译器只能先从左到有排版再旋转特定角度，这意味对从右到左的阿拉伯文，
  从上到下的文言文有着极好的支持。 LuaTeX 的另一个改进是内置了一个 Lua 解释器，
  允许用户通过编写 Lua 输出 pdf 文件。
  [speedata Publisher](https://github.com/speedata/publisher/) 就是这样的一个项
  目。此外 LuaTeX 将最大可用寄存器增加到了 65536 。
- LuaJITTeX 是为了解决 LuaTeX 性能问题引入的。区别是将 Lua 解释器从 PUC Lua 5.3
  换成了 LuaJIT 。不过 LaTeX 的代码中因为使用了一些 Lua 5.3 的用法（整除语法 //
  和内置模块 utf8 ）没有办法支持 LuaJITTeX 。
- Lua(JIT)HBTeX 相比 Lua(JIT)TeX 增加了一个内置模块 hurfbuzz ，提供了对文本塑形
  引擎 [HarfBuzz](https://github.com/harfbuzz/harfbuzz) 的支持。 LaTeX 使用了这
  个。

TeX Live 提供了以上除了 TeX 3 和 eTeX 外所有的编译器。笔者认为这没必要。就像
Python 的解释器有 CPython, PyPy, Jython, GraalPython, IronPython, rustpython 等等，但
官方的 Python 发行版或者第三方的 AnaConda, miniconda 也只提供了一个 CPython 一样。

笔者选择 LuaHBTeX 。它支持 LaTeX ，而且提供了一个名为 texlua 的 lua 解释器。目前
LaTeX 的打包工具 [l3build](https://github.com/latex3/l3build) 和文档搜索工具
[texdoc](https://github.com/TeX-Live/texdoc) 都运行在 texlua 上。所以 texlua 是
必不可少的。

## 格式文件

TeX 是一门宏语言。所有的宏语言都有一个特点：很容易创造一门新的语言。以 C 语言的
宏为例：

`习.h`:

```c
#define 整数 int
#define 字符 char
#define 返回 return
```

于是我们创造了一门新的语言，不妨称为习语言：

```c
#include "习.h"

#include <stdio.h>
#include <stdlib.h>
整数 main(整数 argc, 字符 *argv[]) {
  puts("你好，世界！");
  返回 EXIT_SUCCESS;
}
```

以此类推，我们还可以有喜语言、戏语言等等，这些语言都共用相同的编译器，只需要加载
不同的 `喜.h`, `戏.h` 等。 plainTeX, LaTeX, ConTeXt, TeXinfo 等的关系类似。
它们都使用相同的编译器，但需要加载不同的初始化文件。其中最广受欢迎的 LaTeX 也只是
数学家 Leslie Lamport 最初为满足自己需求设计的一种“习语言”而已。

相较 plainTeX 和 TeXinfo ，在笔者看来 LaTeX 最大的优点是在检测到编译器是 eTeX 和
LuaTeX 时，会充分利用更多的寄存器。例如 plainTeX 的 `\newcount` 会从小到大分配寄
存器。`\newinsert` 会从 256 到小分配寄存器。当两个分配的范围重叠时就会报错没有足
够空间。而 LaTeX 先根据是否是 eTeX 和 LuaTeX 将 `\e@alloc@top` 赋值为
255/32767/65535 。再增加了一个条件判断，当 `\newcount` 和 `\newinsert` 都小于
255 且重叠时，`\newcount` 从 256 到大开始分配寄存器， `\newinsert` 从
`\e@alloc@top` 到小开始分配寄存器。只有再次重叠时才会报错。故在笔者看来，在绝大
多数 TeX 编译器兼容 eTeX 的如今，继续使用 plainTeX 类似在 64 位电脑上运行 32 位
程序，是一种不能充分利用资源的行为。

对三种编译器 pdfTeX, XeTeX, LuaTeX 和三种 TeX 方言 plainTeX, LaTeX, ConTeXt, 我
们可以造出九种组合 pdfTeX, pdfLaTeX, pdfConTeXt, 以此类推。这样的组合称为格式。
一般用编译器决定格式名的前缀，用语言决定格式名的后缀。对 plainTeX ，就用编译器名
作为格式名。那么对于 Alpha, Omega 这样名字不带 TeX 的编译器，它们和 LaTeX 等组合
的格式会使用专门的名字，比如 Lamed, Lambda 。

C/C++ 支持将包含的头文件预编译成 pch 文件加快编译速度：

- [meson](https://mesonbuild.com/Precompiled-headers.html)
- [xmake](https://xmake.io/#/manual/project_target?id=targetset_pcheader)

类似的，使用后缀名 ini 的 TeX 初始化文件也可以被预编译为后缀名 fmt 的二进制格式
文件：

```sh
luatex --ini XXX.ini
luatex --fmt XXX.fmt main.tex
```

每次编译 `main.tex` 都需要通过命令行传入 `--fmt XXX.fmt`，太麻烦了。我们知道所有
可执行文件都有一个文件名：

`main.c`:

```c
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char *argv[]) {
  char *name = basename(argv[0]);
  if (strcmp(name, "luatex") == 0) {
    puts("now use luatex.fmt");
  } else if (strcmp(name, "lualatex") == 0) {
    puts("now use lualatex.fmt");
  } else {
    puts("not support!");
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
```

我们可以通过检测文件名执行不同的代码逻辑：

```c
$ cc main.c -o luatex
$ ./luatex
now use luatex.fmt
$ cp luatex lualatex
$ ./lualatex
now use lualatex.fmt
```

于是，所有 TeX 编译器约定：

- luatex 会默认使用 `luatex.fmt`
- lualatex 会默认使用 `lualatex.fmt`
- texinfo 会默认使用 `texinfo.fmt`
- 以此类推

不过 texlua 会直接运行一个 lua 的解释器，不会调用 `texlua.fmt` 。

笔者提供了 plainTeX, LaTeX, TeXinfo 与 LuaTeX 组合的格式文件，没有提供 ConTeXt
是因为这种语言笔者从未用过。

此外， TeX 的编译器有一个特性：当编译遇错的时候会停下来询问怎么办。在静默安装时
这会无限等待下去。请添加 `--interaction=nonstopmode` 。（别问笔者怎么发现的 QAQ）

## 依赖

[CTAN](https://ctan.org/) 时一个专门收录 TeX 相关的项目的网站，然而相比 PYPI,
npmjs.org, luarocks.org, CTAN 的包没有依赖信息。笔者通过将包发布到 luarocks.org
来利用其依赖信息。注意到和 LuaTeX 相关的 TeX 包中会有大量 Lua 代码，这样做其实挺
合理。

另一个例子是 NeoVim 的包管理器
[rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim) 。 NeoVim 是一个新的
vimscript 解释器，正如 LuaTeX 与 TeX 的关系一样， NeoVim 相比 vim 内置了一个
LuaJIT 。 rocks.nvim 通过利用 luarocks 来声明各种 Vim 插件的依赖关系。顺带一提，
rocks.nvim 3.0 将用 rust
[重写底层](https://github.com/nvim-neorocks/rocks.nvim/issues/539)，有望成为最快
的 Vim 包管理器。

Luarocks 支持声明构建时依赖和运行时依赖。对格式文件而言，生成格式文件的 TeX 源代
码所在的包就是构建时依赖。对于普通的包， `\RequirePackage{}` 的 LaTeX 代码和
`\input` 的 TeX 代码所在的包就是运行时依赖。

## Lua

LuaTeX 和 NeoVim 的某些相似的 API 如下：

- 在 TeX/vimscript 中调用 lua:
  - LuaTeX: `\directlua{XXX}`
  - NeoVim: `lua XXX`
- 在 Lua 中调用 TeX/vimscript:
  - LuaTeX: `tex.print[[XXX]]`
  - NeoVim: `vim.cmd[[XXX]]`

Lua 的引入允许用户更好的看清 TeX 的一些细节。
[An Introduction to LuaTeX (Part 2): Understanding \directlua](https://www.overleaf.com/learn/latex/Articles/An_Introduction_to_LuaTeX_(Part_2)%3A_Understanding_%5Cdirectlua)
给出了一张图解释 LuaTeX 的词法分析：

![token](https://images.ctfassets.net/nrgyaltdicpt/3DRjCN8AL5r4uGKjWlCc87/9900d8efe53d880eb8804f138eab7019/list_schematic--plain2.svg)

每个 token 都会计算一个 token value, 原文给出了 token value 的计算公式。
但如果利用 LuaTeX 提供的 API ，可以直接看到计算后的结果：

![REPL](https://github.com/user-attachments/assets/cd63bf68-fbcb-4e79-9d4e-d2798c0a692d)

这个 REPL 的代码在[这](https://github.com/wakatime/prompt-style.lua/)。

更多 API 请查询 [LuaTeX 文档](https://texdoc.org/serve/luatex/0) 。确保你拥有一
门 TeX 方言的先验知识。笔者推荐 plainTeX ，因为它真的是太简单了，对照
[TeX 急就帖](https://texdoc.org/serve/impatient-cn/0)，高德纳写的 1200 行代码一
天就可以读完。

## 标准

Lua 的包搜索路径取决于 `package.path` 和 `package.cpath`：它们是用分号连接的一组
路径，用于 Lua 脚本和二进制 Lua 模块。 NeoVim 额外提供了 `vim.o.runtimepath` ，
用逗号连接的一组路径，用于 Lua 脚本和 vimscript 脚本。 LuaTeX 则额外提供了
`kpse.lookup()` 用于搜索 Lua 脚本和 TeX 文件。 `kpse` 是 kpathsea (卡尔路径海)
的一个 Lua 模块，其配置文件 texmf.cnf 中的 LUAINPUTS, TEXINPUTS 是用分号连接的一
组路径。只需要再每次安装完后更新 texmf.cnf 即可让新安装的 TeX 包被找到。

此外， Unix 有 [XDG](https://specifications.freedesktop.org/basedir-spec/latest/)
标准，规定字体文件路径在 `${XDG_DATA_HOME:-$HOME/.local/share}/fonts` 下。而 TeX
有 [TDS](https://www.tug.org/tds/tds.pdf) 标准规定字体文件按文件类型路径在

- opentype 字体： 当前路径，`$TEXMF/fonts/opentype`
- truetype 字体： 当前路径，`$TEXMF/fonts/truetype`
- type1 字体： 当前路径，`$TEXMF/fonts/type1`
- 以此类推

可以在 `texmf.cnf` 中添加 XDG 字体路径到 `OPENTYPEFONTS` 等变量中兼容 XDG 。

同样的，对于 texmf.cnf 默认的一些路径：

```texmf
TEXMFHOME = ~/texmf
TEXMFVAR = ~/.texlive2023/texmf-var
TEXMFCONFIG = ~/.texlive2023/texmf-config
```

参考 [ArchLinux wiki](https://wiki.archlinux.org/title/XDG_Base_Directory#Partial)
后指定：

```texmf
TEXMFHOME     = $XDG_DATA_HOME/texmf
TEXMFVAR      = $XDG_CACHE_HOME/texmf
TEXMFCONFIG   = $XDG_CONFIG_HOME/texmf
```

## 包

笔者将一些常见的包如 PGF/TikZ, beamer 打包了。

- 包管理器代码在[这](https://github.com/Freed-Wu/texrocks)
- 包在[这](https://luarocks.org/m/texmf)

将目前所有包安装在本地后，占据空间大概如下：

- 编译器： 8.2 MiB
- Lua 脚本： 13.1 MiB
- TeX 代码： 30.4 MiB
- 字体文件： 92.0 MiB, TeX 缺省使用 computer modern 字体。此外还打包了一些别的字
  体。
- pdf 文档： 162.5 MiB, 文档其实可以删掉，用在线的 <https://texdoc.org/>

作为比较，以下是其他文档排版系统的大小（没有包含字体）：

- [groff](https://www.gnu.org/software/groff/): 10.1 MiB 。 GNU roff 也是一门宏
  语言。除了支持输出 pdf 外，还支持输出终端。目前 Unix 的 man 手册是用 roff 编写。
  像 plainTeX, LaTeX, TeXinfo 等一样， roff 也有诸如 man, mm 等多个通过
  `groff -m XX` 预加载的宏，但 roff 比 TeX 语法弱，不能通过类似 `\catcode` 的原语
  修改词法解析的流程。
- [typst](https://github.com/typst/typst): 33.1 MiB 。 这是一个相当现代的标记语
  言，使用命令式编程而非宏语言，带有增量编译、语言服务器协议等相当新的技术，从而
  改善编译性能和提高开发效率。强烈推荐新的文档使用 Typst 。相比 Typst, 笔者认为
  TeX 更适合作为一种智力测试题而非文档排版系统。 :)

很多东西仍然是缺失的：

- 笔者不太熟悉 LuaTeX 的字体加载机制，所以 ctex 打包仍然有问题
- 参考文献常用的工具 bibtex, [biber](https://github.com/plk/biber) 是用 pascal,
  perl 编写的，不太合适打包到 Luarocks 。 lua 写的替代品
  [citeproc-lua](https://github.com/zepinglee/citeproc-lua)
  索引常用的工具 makeindex 是用 C 编写的。 lua 写的替代品
  [xindex](https://gitlab.com/hvoss49/xindex) 还未打包。
- 一些用 Lua 编写的工具如 texdoc, l3build 被打包了，但用 perl 编写的
  [texdef](https://github.com/MartinScharrer/texdef/) 就没有。在 texlua 问世前，
  TeX 社区的很多工具是用 perl 编写的。
- 构建系统 [latexmk](https://ctan.org/pkg/latexmk),
  [latexrun](https://github.com/aclements/latexrun),
  [arara](https://github.com/islandoftex/arara) 分别使用了 perl, python, java
  编写。目前没有基于 texlua 的可用替代品。
- 打包脚本有很多使用了 `cp`, `mv`, `rm`, `which` 等 bash 和 coreutils 的命令。
  没有使用 Lua 跨平台的 API 。所以暂时没法在纯 Win32 上运行。（不纯的指
  Msys2/Cygwin ）

总之，相较 NeoVim 仅靠 Lua 就可以满足近乎所有需求，一个仅靠 LuaTeX 的生态仍然缺
失大量工具软件。但一个去除 pdf 文档后仅占据 143.7 MiB 就可以绘制如下流程图的
LaTeX 发行版，也何尝不会是一个类似 rocks.nvim 的好的开始呢？

```tex
% 施法前摇
\documentclass[tikz]{standalone}
\usetikzlibrary{arrows.meta, quotes, graphs, graphdrawing, shapes.geometric}
\usegdlibrary{layered}
\usepackage{hyperref}
\usepackage{hologo}
\title{graph}
\begin{document}
\begin{tikzpicture}[rounded corners, >=Stealth, auto]
  \graph[layered layout, nodes={draw, align=center}]{

    % 开始施法
    "\TeX" -> "\hologo{eTeX}" -> "\hologo{pdfTeX}" -> "\hologo{LuaTeX}";
    "\hologo{eTeX}" -> "\hologo{XeTeX}"

    % 施法后摇
  };
\end{tikzpicture}
\end{document}
```

![graph](https://github.com/user-attachments/assets/131a8a31-0dd4-49fa-84dd-1531c89da55c)
