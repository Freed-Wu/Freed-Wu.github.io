---
title: C/C++ 构建系统简史：旧约
tags:
  - develop
  - c
---

C/C++ 不能没有构建系统，就像 GNU/Linux 不能没有包管理器。

## 创世记： `make`

> ![腾讯 1 号员工在 1999 年大年初六写的 Makefile 。知乎上有鹅厂员工分享过内部群的高清版，但后来删了。](https://picx.zhimg.com/80/v2-835fe62f2d1a722219c2f43566c55595_1440w.webp)

起初（应该是 20 世纪七八十年代吧，甚至可能更早），在打包这个概念还不存在的时候，所有的计算机用户都是软件开发者，他们从源代码为自己构建软件，就像这样：

```shell
gcc a.c -c -o a.o  # compile
gcc b.c -c -o b.o
...
gcc a.o b.o ... -o a-good-program  # link
```

后来，随着代码规模的一步步增加，第一个问题出现了：编译太慢了。不妨假设 `a.c` `#include "main.h"`。一旦 `main.h` 发生改变，就必须重新编译 `a.o` 。只能把所有的 `*.o` 都重新编译。这非常耗时——例如，在笔者上一台 PC 上编译 linux 需要整整 2 个小时——于是开发者们很快想到了解决方法：在一个文件中记录所有源代码文件的依赖关系，例如 `a.o` 依赖 `a.c` 和 `main.h`。然后每次编译时，看看 `a.o` 和 `a.c`, `main.h` 的时间戳，发现 `main.h` 的修改时间迟于 `a.o` 的修改时间：说明 `a.o` 需要重新编译，从而省下 `b.o`, `c.o`, ... 的时间。这样的文件叫做 `Makefile` ，这样的调用 `Makefile` 编辑的软件叫做 `make` 。

`make` 不是唯一加速编译的方式，但和其他方式相比（分布式编译的 `distcc` 和使用缓存的 `ccache`）相比，所需要的条件最少。

## 出埃及记： `./configure`

> 传统上，交叉开发是一门黑魔法，需要大量研究、反复试验和坚持不懈。
>
> -- Gentoo [嵌入式手册](https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Introduction)

很快新的问题出现了：软件运行需要平台（CPU，操作系统），编译需要编译器。当时世界上存在的 CPU, 操作系统，编译器五花八门，每一个都有不同的“怪癖”。为了支持它们， `Makefile` 也要写得五花八门。更特殊的情况是：用户需要另一个平台上的软件但有没有该平台的设备（例如用户使用 Linux 开发但需要发布支持别的操作系统和 CPU 的软件）或者有该平台的设备但该设备性能很弱，编译很慢所以用户宁愿用自己的另一个平台的电脑编译（例如用户想编译树莓派上的软件）甚至该平台根本不能为自己编译软件（例如 TI 的 DSP ）。所以交叉编译出现了--在一个平台上编译另一个平台的软件。

![cross-compile](https://hacks.mozilla.org/files/2019/03/04-01-portability-1.png)

不管怎样，开发者希望有一种方法能自动检测用户的平台和安装了哪些编译器，用合适的编译器生成适用于用户需要的平台的软件，就像这样：

```shell
./configure
make
```

开发者无需指定适用哪一个 `Makefile`, 因为 `./configure` 会为根据一个叫 `Makefile.in` 的模板生成适合开发者所在平台的 `Makefile` 。（也有生成 `config.mk`, 再在 `Makefile` 中 `include config.mk` 的 `./configure` ，例如 [proxychains-ng](https://github.com/rofl0r/proxychains-ng) 和 [x264](https://github.com/mirror/x264)）如果开发者想交叉编译，在拥有支持交叉编译的编译器的情况下：

### 生成 `x64 windows` 平台的 `Makefile`

```shell
./configure  --build=x86_64-pc-linux-gnu --host=x86_64-w64-mingw32
```

### 生成 `arm64 android` 平台 (API 版本为 32) 的 `Makefile`

```shell
./configure --build=x86_64-pc-linux-gnu --host=aarch64-linux-android32
```

### 生成 `arm` 无操作系统的 `Makefile`

```shell
./configure --build=x86_64-pc-linux-gnu --host=arm-none-eabi
```

还可以生成 `macOS` 平台的 `Makefile`, 参见 <https://github.com/tpoechtrager/osxcross>。但笔者没有尝试过，因为就算尝试了笔者也没有苹果电脑来测试程序到底能不能跑。

`./configure` 只是一个由开发者编写的 `shell` 脚本，它接受 `--build` 等命令行选项确定用户想要编译什么样的软件，并生成对应的 `Makefile` 。

## 利未记： `autoconf`

> 那些不了解 Autoconf 的人注定要重新发明它，而且很糟糕。
>
> -- GNU [autoconf](https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.71/autoconf.html#Introduction)

每个开发者都要为自己的软件写 `configure` ，每个 `configure` 都有相似的选项 `--build`, `--host`, ... 很快每个开发者发现自己只是找自己之前某个开源项目的 `configure`, 复制一份再二次修改。既然如此，为什么不让每个开发者在一个配置文件里写上自己项目独有的信息，再运行一个软件从把这些信息送到一个模板里自动生成一个 `configure` 呢？

```shell
autoconf
./configure
make
```

这样的软件叫 `autoconf` ，这样的配置文件叫 `configure.ac` 。

## 民数记： `autoheader`

> 当事情出错时， 但是，您会感谢 autoheader 。
>
> -- GNU [autoheader](https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.71/autoconf.html#autoheader-Invocation)

在编译 C/C++ 软件时开发者根据需要定义各种各样的宏，例如量化位数到底是 8 bit 还是 10 bit ？图像格式是 YUV422 还是 YUV 420 ？这样的宏可以写在 `Makefile` 在 `make` 的时候调用 `gcc -DX264_BIT_DEPTH=8 -DX264_CHROMA_FORMAT=0`。当宏越来越多的时候，`make` 时回显调用的命令的输出就会越来越长，影响开发者快速查看日志。而日志里的这些宏信息是不需要的，可以从类似 `./configure --enable-8-bit --enable-yuv420` 的命令中直接知道。一个简单的想法让 `configure` 生成 `config.h`:

```c
#define X264_BIT_DEPTH 8
#define X264_CHROMA_FORMAT 0
```

然后让需要这 2 个宏的 `*.c` `#include "config.h"` 。

当然，实际上是 `./configure` 从 `config.h.in` 生成 `configure.h` 的。而 `config.h.in` 从 `autoheader` 从 `configure.ac` 生成。

## 申命记： `automake`

> 这是一个公认的事实，作为一个开发者拥有一个新包，你一定需要一个构建系统。
>
> -- GNU [automake](https://www.gnu.org/software/automake/manual/automake.html#GNU-Build-System)

问题都解决了吗？不，开发者还需要手写一个 `Makefile.in` 的文件（忘了这是什么的回头看出埃及记）。就像 `autoconf` 从 `configure.ac` 生成 `configure` 一样， `automake` 从 `Makefile.am` 生成 `Makefile.in` 。 Gentoo [Autotools 基本知识](https://devmanual.gentoo.org/general-concepts/autotools/index.html)有一张完整的流程图：

![A basic overview of how the main autotools components fit together](https://devmanual.gentoo.org/general-concepts/autotools/diagram.png)

当然，又是这个 `auto` ，又是那个 `auto` ，把开发者都绕进去了。一般 `autoreconf` 就可以按正确的顺序完成所有 `auto*` ，然后用户只需要 `./configure && make` 就行了。一个小问题，用户必须要安装 `autoconf` （`autoheader` 已经是 `autoconf` 这个软件中的一个程序了，安装 `autoconf` 一定会有 `autoheader`）， `automake` 才能成功构建依赖 `autoconf` 的软件吗？读者先自己思考一会～

## 摩西五经之后： 新的构建系统

> 构建系统不仅适用于人工编写的代码；它们还允许机器自动创建构建，无论是用于测试还是用于发布到生产。
>
> -- Google [bazel](https://bazel.build/basics/build-systems)

`autotools` (`autoconf`, `automake` 和一系列其它软件和合称) 并不是唯一的构建系统。以 C/C++ 的构建系统为例，可以是：

![Build systems](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/5f072e58-8650-4630-8388-2856b49c2665)

### [`cmake`](https://github.com/Kitware/CMake)

笔者所有见过的 `C/C++` 项目，构建系统几乎要么是 `autotools` ，要么是 `cmake`。`autotools` 因为问世时间更早，所以使用的开源项目似乎更多，但很多新的开源项目开始使用 `cmake` 或者用 `cmake` 代替 `autotools`。 `autotools` 存在一个历史遗留问题造成的学习门槛： `configure.ac` 是一种宏语言，在当今指令式/面向对象大行其道的今天，学习一门与之不同的采用新的编程范式的计算机语言难度可能跟一个精通了欧洲各国语言的欧洲人去学中文差不多。而 `cmake` 作为一门动态类型指令式的 DSL 其实学习难度相对而言可能更容易接受。除此之外 `cmake` 对 [编译数据库文件](https://clang.llvm.org/docs/JSONCompilationDatabase.html) 的导出也有比 `autotools` 更好的支持。另外 `autotools` 主要支持 `gcc`, `clang`, `icc` 等，对 `MSVC` 的支持则被成为[“地狱”](https://www.reddit.com/r/cpp/comments/e0kxsy/autotools_windows_the_build_systems_tragedy/)[^msvc]，而 `cmake` 甚至支持直接生成 `MS Visual Studio` 的工程文件。（这也得益于 `cmake` 虽然比 `autotools` 问世时间迟但是一门新的计算机语言或多或少摸着 `automake` 见过的石头过河）。

| 比较           | autotools                                                                | cmake                                                          |
| ------------ | ------------------------------------------------------------------------ | -------------------------------------------------------------- |
| 源外构建         | `mkdir build && cd build && ../configure`                                | `cmake -Bbuild`                                                |
| 源内构建         | `./configure`                                                            | `cmake .`                                                      |
| 构建           | `make`                                                                   | `cmake --build build`                                          |
| 安装           | `make install`                                                           | `cmake --install build`                                        |
| 指定安装前缀       | `./configure --prefix=/usr`                                              | `cmake -Bbuild -DCMAKE_INSTALL_PREFIX=/usr`                    |
| 指定安装路径       | `DESTDIR=XXX make install`                                               | `DESTDIR=XXX cmake --install build`                            |
| 交叉编译         | `./configure --build=x86_64-pc-linux-gnu --host=aarch64-linux-android32` | `cmake -Bbuild -DCMAKE_TOOLCHAIN_FILE=cmake/android-ndk.cmake` |
| `autoheader` | `AC_CONFIG_HEADERS([config.h])`                                          | `configure_file(config.h.in config.h)`                         |

`cmake/android-ndk.cmake` 参见笔者学习 [C 构建](https://github.com/ustc-ivclab/x264-dsp) 练手的项目。

### [`bazel`](https://bazel.build/basics/build-systems)

`bazel` 几乎是公认最强的构建系统——没有之一。 google 包括 android 在内的大部分软件都在使用。`bazel` 使用 `python` 做配置语言，甚至完全舍弃了 `Makefile` 。但 google 以外似乎很少使用，网传原因是[“光使用 `bazel` 就需要一支 5 到 6 人的团队”](https://zhuanlan.zhihu.com/p/112712537)。

### [`scons`](https://github.com/SCons/scons)

`scons` 也使用 `python` 做配置语言。但除了它自己，笔者从未见过有开源项目使用过。可能是因为[“速度比 `cmake` 慢”](https://www.reddit.com/r/embedded/comments/q8foqe/scons_vs_cmake/)。

## 总结

除了 C/C++, 其实别的语言也有构建系统的概念，比如：

### `perl`

- `dzil build` 对应 `autoreconf`
- `perl Makefile.PL` 对应 `./configure`
- `make`, `make install`[^package] 一模一样。

### `python`

- `python -m build -s` 对应 `autoreconf`
- `python -m build -w` 对应 `./configure && make`
- `python -m installer` 对应 `make install`

### `plainTeX/LaTeX`

- `l3build tag` 对应 `autoreconf`
- `l3build ctan` 对应 `./configure && make`
- `l3build install` 对应 `make install`

所以，笔者个人认为了解 C/C++ 构建系统对学习其它语言也是有所裨益的。

回到前面埋下的一个问题：用户必须要安装 `autoconf` 才能成功构建依赖 `autoconf` 的软件吗？答案是否：开发者只需 `autoreconf -i` ，然后打包压缩发布就行（这种包被称为软件分发包 `sdist` ），用户下载之后解压缩然后直接 `./configure && make && make install` ，不需要任何 `autotools`。如果以 `python` 为例介绍可能大家会更亲切，因为大家 `pip install` 时如果下载到了 `python -m build -w` 生成的 `wheel` 包，就可以直接安装，否则就会下载 `python -m build -s` 生成的 `sdist` 包构建后再安装。有些读者可能知道 `setup.py` 但 `setup.py` 不符合 [PEP517](https://peps.python.org/pep-0517/) 标准已经被社区逐渐淘汰。这里介绍的 `python -m build` 是符合标准的。关于符合标准的 python 构建，可以参考笔者自己[学习 python 构建时写的项目](https://github.com/Freed-Wu/translate-shell/)，不会单独再写文章介绍。笔者学习 [C 构建 (autotools, cmake)](https://github.com/ustc-ivclab/x264-dsp)，[perl 构建](https://github.com/Freed-Wu/Reply-Plugin-Prompt/) 和 [LaTeX 构建](https://github.com/Freed-Wu/njustthesis/)写的项目也可参考，不过都只是学习时练手之作，不可和专业的开发者同日而语。

最后，因为有些观点笔者没有亲身验证过（例如 `scons` 速度比 `cmake` 慢），只能确保给出观点的引用来源。是真是假，请读者自行甄别。最后，即使是笔者亲身验证后得出的观点，也有可能是因为知识的局限性得出错误，笔者只能尽力确保主观上不要犯错。

[^msvc]: 毕竟 `MSVC` 是一个逼得 `ffmpeg` 写出 [`c99-to-c89`](https://github.com/libav/c99-to-c89) 的奇葩，出现任何问题都是毫不奇怪的 :smile:

[^package]: 安装软件的指令，在包管理器出现之后才有 `apt install` 和 `pacman -S`，关于包管理器，后面可能会写一篇文章介绍。
