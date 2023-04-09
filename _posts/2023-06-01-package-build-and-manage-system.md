---
title: 包构建/管理系统简史
tags:
  - develop
  - package
---

多年以后，面对开源社区的欢呼， Eelco Dolstra
工程师将会回想起他撰写[博士毕业论文](http://nixos.org/~eelco/pubs/phd-thesis.pdf)
的某个遥远的下午。

以下表格只列举了笔者熟悉的例子。

| 计算机语言    | 构建系统               | 包管理系统 |
| -------- | ------------------ | ----- |
| C/C++ 为主 | make               | vcpkg |
| C/C++ 为主 | ninja              | /     |
| C/C++ 为主 | msbuild            | /     |
| C/C++ 为主 | Xcode build system | /     |
| C/C++ 为主 | Bazel              | /     |
| C/C++ 为主 | autotools'         | /     |
| C/C++ 为主 | meson'             | /     |
| C/C++ 为主 | Blade'             | /     |
| C/C++ 为主 | cmake'             | /     |
| python   | python -m build    | pip   |
| perl     | Makefile.PL        | cpan  |
| perl     | Build.PL           | cpanm |
| perl     | dist::zilla        | /     |
| TeX      | l3build            | tlmgr |

`'` 代表元构建系统，即生成其他构建系统配置的构建系统。另外 C/C++ 的包通常用软件发行版的包管理系统管理。

| 软件发行版                 | 构建系统          | 包管理系统          |
| --------------------- | ------------- | -------------- |
| Arch Linux'           | makepkg       | pacman         |
| Windows Msys2         | makepkg-mingw | pacboy         |
| Android termux        | build.sh      | apt + dpkg     |
| Android termux-pacman | build.sh      | pacman         |
| Gentoo'               | ebuild        | emerger        |
| Debian'               | debmake       | apt + dpkg     |
| Nix                   | nix-build     | nix-env        |
| NixOS'                | nix-build     | nixos-rebuild  |
| Nix Darwin            | nix-build     | darwin-rebuild |
| homebrew              | brew          | brew           |
| openembedded          | bitbake       | dnf            |

`'` 代表操作系统。一般软件发行版的构建系统既可以当元构建系统（为某一特定计算机语言构建包时调用该计算机语言的构建系统）也可以直接当构建系统（直接调用编译器）。

## 包的管理

> 包管理器在 Linux 软件管理中扮演了重要角色。
>
> -- Steve Ovens
> [evolution-package-managers](https://opensource.com/article/18/7/evolution-package-managers)

笔者认为引文的这段观点不够全面，因为无论是什么系统，只要涉及到依赖关系（某个操作系统里各种各样的软件，某种编程语言里形形色色的库），就务必需要引入一个管理依赖关系的角色，而不仅仅是 Linux 的软件管理。在下文中，考虑到 Windows Msys2 和 Android Termux 这样的环境，笔者不会使用“ Linux 发行版”这样的术语，而是会使用更一般的“软件发行版”的术语。

### 软件发行版包管理器和编程语言包管理器

从形式上看，软件发行版的包管理器和编程语言的包管理器最大的区别是路径是否硬编码：

软件发行版的包管理器中的路径通常是硬编码的。例如这是一个 pacman (ArchLinux, Windows Msys2, Android Termux-pacman 的包管理器)
的包，可以 `sudo pacman -S ninja`
或者下载[这个包](https://archlinux.org/packages/ninja)后通过
`sudo pacman -U ninja-1.11.1-3-x86_64.pkg.tar.zst` 安装它。

```shell
$ tar taf ninja-1.11.1-3-x86_64.pkg.tar.zst
.BUILDINFO
.MTREE
.PKGINFO
usr/
usr/bin/
usr/bin/ninja
usr/lib/
usr/lib/python3.11/
usr/lib/python3.11/site-packages/
usr/lib/python3.11/site-packages/ninja_syntax.py
usr/share/
usr/share/bash-completion/
usr/share/bash-completion/completions/
usr/share/bash-completion/completions/ninja
usr/share/doc/
usr/share/doc/ninja/
usr/share/doc/ninja/manual.asciidoc
usr/share/emacs/
usr/share/emacs/site-lisp/
usr/share/emacs/site-lisp/ninja-mode.el
usr/share/emacs/site-lisp/ninja-mode.elc
usr/share/licenses/
usr/share/licenses/ninja/
usr/share/licenses/ninja/COPYING
usr/share/vim/
usr/share/vim/vimfiles/
usr/share/vim/vimfiles/syntax/
usr/share/vim/vimfiles/syntax/ninja.vim
usr/share/zsh/
usr/share/zsh/site-functions/
usr/share/zsh/site-functions/_ninja
```

除去隐藏的元信息的文件，其他都会被直接安装在根目录下，例如 `usr/bin/ninja`。

作为比较，这是一个 `pip` (python 的包管理器) 的包，可以 `pip install ninja`
或者下载[这个包](https://pypi.org/project/ninja/#files)后通过
`pip install ninja-1.11.1-py2.py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl` 安装它。

```shell
$ unzip -l ninja-1.11.1-py2.py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl
Archive:  ninja-1.11.1-py2.py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl
  Length      Date    Time    Name
---------  ---------- -----   ----
        6  11-06-2022 00:46   ninja-1.11.1.dist-info/top_level.txt
      211  11-06-2022 00:46   ninja-1.11.1.dist-info/WHEEL
      142  11-06-2022 00:46   ninja-1.11.1.dist-info/AUTHORS.rst
     1033  11-06-2022 00:46   ninja-1.11.1.dist-info/RECORD
    10273  11-06-2022 00:46   ninja-1.11.1.dist-info/LICENSE_Apache_20
     5348  11-06-2022 00:46   ninja-1.11.1.dist-info/METADATA
       38  11-06-2022 00:46   ninja-1.11.1.dist-info/entry_points.txt
        0  11-06-2022 00:46   ninja/py.typed
       88  11-06-2022 00:46   ninja/__main__.py
     1783  11-06-2022 00:46   ninja/__init__.py
      498  11-06-2022 00:46   ninja/_version.py
     6948  11-06-2022 00:46   ninja/ninja_syntax.py
   302712  11-06-2022 00:46   ninja/data/bin/ninja
---------                     -------
   329080                     13 files
```

注意到差别了吗？路径没有硬编码意味着根本不会有形如 `/usr` 之类的东西。
因为编程语言的包管理器需要确保在软件发行版中都可以正常工作，所以
`pip install ninja` 会安装：（注意，在 Windows 上 `ninja/data/bin/ninja` 将是 `ninja/data/bin/ninja.exe`）

- GNU/Linux: `/usr/lib/python3.11/site-packages/ninja/data/bin/ninja` ，
- Android Termux: `/data/data/com.termux/files/usr/lib/python3.11/site-packages/ninja/data/bin/ninja` ，
- Windows Msys2/MinGW64: `C:\Msys2\mingw64\lib\python3.11\site-packages\ninja\data\bin\ninja.exe` ，
- Windows: `C:\Python311\Lib\site-packages\ninja\data\bin\ninja.exe`

如果有 `ninja-1.11.1.dist-info/headers/ninja.h` 或者 `ninja-1.11.1.dist-info/scripts/ninja.py`，
`pip install` 也会安装：

- GNU/Linux: `/usr/include/ninja.h`, `/usr/bin/ninja.py`
- Windows: `C:\Python311\include\ninja.h`, `C:\Python311\Scripts\ninja.py`

其他软件发行版不再赘述。

除了根据软件发行版决定某些安装路径之外， `pip install` 也允许用户决定前缀根据 `--prefix` 。
默认的前缀会根据用户管理员权限的有无分别为 `/usr` 和 `~/.local` 。这又一次佐证了“最大的区别是路径是否硬编码”的观点。
此处读者可以先停下来想一想，为什么软件发行版的包管理器必须硬编码？

### 系统级包管理器和第三方包管理器

同样是软件发行版的包管理器，大多数 Linux 发行版预装的包管理器（Debian 系的 apt ，Redhat 系的 yum ， Arch 系的 pacman ， Gentoo 系的 emerge 等，称为系统级包管理器）和用户因为诸多原因（通常是预装的包管理器没有需要的软件）额外安装的包管理器（Homebrew (Linuxbrew) ，Nix (Nix-darwin) ， Anaconda (Miniconda) ， Flatpak ， Snap 等，称为第三方包管理器）也有很大差异。包括但不限于：

- 系统级包管理器是自举的，比如你可以卸载掉包管理器本身（安装回去就比较麻烦了，一般得用 LiveUSB ）。第三方包管理器都是用户独立安装的，自然也要独立卸载。对于 Linux 发行版的包管理器，甚至连 OS 内核也是被管理的一部分，一般只用来更新。如果用某些命令行选项无视依赖关系的警告可以卸载（不要尝试！后果自负。）。
- 系统级包管理器的包通常路径硬编码的前缀是根目录，除非某些特殊情况，例如 Android Termux 因为没有管理员权限所以选择 `/data/data/com.termux/files/usr` 作为前缀， Windows Msys2 属于 POSIX 下的根目录对应 Windows 下的 `C:\Msys2` ，不属于特殊情况。第三方包管理器的前缀可能是 Homebrew 的 `/usr/local`, `/opt/homebrew`, `/home/linuxbrew/.linuxbrew` ， nix 是个例外， `nar` 的前缀就是根目录，因为 Nix 既可以是 NixOS 的系统级包管理器，也可以是 macOS 和 GNU/Linux 的第三方包管理器。

回答之前的一个问题： 为什么软件发行版的包管理器必须硬编码？因为对这些包管理器管理的软件而言，如果不安装在指定路径下，软件就无法正常工作。例如一个用 C 编写的软件包 `coreutils` 中有一个程序 `ls` ：

在 GNU/Linux 上：

```shell
$ patchelf --print-interpreter $(which ls)
/lib/ld-linux-x86-64.so.2
$ patchelf --print-rpath $(which ls)
/lib
```

在 Android 上：

```shell
$ patchelf --print-interpreter $(which ls)
/system/bin/linker64
$ patchelf --print-rpath $(which ls)
/data/data/com.termux/files/usr/lib
```

在 NixOS 上：

```shell
$ patchelf --print-interpreter $(which ls)
/nix/store/yaz7pyf0ah88g2v505l38n0f3wg2vzdj-glibc-2.37-8/lib/ld-linux-x86-64.so.2
$ patchelf --print-rpath $(which ls)
/nix/store/p0ikbnq88v649sk7rdrwhdp8qaqqjill-acl-2.3.1/lib:/nix/store/w237hnxridnmjjwxfz1s1lfyppdzrrrb-attr-2.5.1/lib:/nix/store/19diy37d1q2mnvpmgaa9xkmjz830gmbj-gmp-with-cxx-6.2.1/lib:/nix/store/31hpxybx1h1ivhfrmc4xa8nw6g9y8b2i-openssl-3.0.8/lib:/nix/store/yaz7pyf0ah88g2v505l38n0f3wg2vzdj-glibc-2.37-8/lib
```

注意到了吗？这些 `ls` 都是动态链接的，运行时需要一个动态链接器 (interpreter) 去运行时路径 (rpath) 查找需要的动态链接库。而 interpreter 和 rpath 是以绝对路径的形式硬编码到二进制文件中的。如果包管理器安装软件包时不把这些路径硬编码到指定位置，这些 `ls` 根本无法正常工作。当然对静态链接的程序而言就无所谓了，但大多数软件出于减少硬盘和内存的占用的目的（动态链接库被多个软件重复使用从而减少软件的大小以及消除内存中库的重复加载）都会选择动态链接，从而使得软件发行版的包管理器必须硬编码。

### 包管理器的本质

#### 版本约束

回到包管理器的讨论来。无论是什么包管理器，本质上都是一个 SAT 求解器。例如：

- 软件 a 1.0 依赖软件 `x > 1.0, y < 3.0`
- 软件 b 1.5 依赖软件 `c > 2.0, y < 2.5`
- 软件 c 2.5 依赖软件 `x < 5.0`
- 软件 c 3.0 依赖软件 `x < 6.0, y > 3.0`

用户希望同时安装 `pip install 'a>0.5' b c` ，或者依次安装 `pip install 'a>0.5' && pip install b && pip install c` 。 请在满足用户要求的版本约束和依赖关系定义的版本约束的情况下尽可能安装版本最高的软件。

#### USE 约束

有的包管理器管理的依赖关系除了版本约束还有别的约束，比如 gentoo 引入 `USE` 和 `package.use` 。例如：

- 软件 a 1.0 支持可选 USE f1
- 软件 b 1.5 支持可选 USE f2, f3
- 软件 a 1.0 如果使能 f1 会额外依赖 `u < 6.0`
- 软件 b 1.5 如果使能 f2 会额外依赖 `u > 6.0`
- 软件 b 1.5 不能同时使能 USE f2 和 f3

`USE` 是全局的，例如 `USE='f1 f3'` 意味着所有软件都使用了 f1 和 f3 。 `package.use` 是局部的，例如 `/etc/portage/package.use/my-use` 中有内容 `b f2` 意味着所有版本的 b 都使用了 f2 。用户可以指定 `USE` ， 请在满足用户要求的版本约束， USE 约束和依赖关系定义的版本约束和 USE 约束的情况下尽可能选择最少的 USE 并安装版本最高的软件。如果无解，包管理器需要给出用户可以修改哪些 `USE` 来继续安装。

通常 USE 可能会是：

- 是否安装某些文件
  - doc: 文档
  - bash: shell 补全
  - zsh: shell 补全
  - vim: vim 语法高亮文件
  - emacs: emacs 语法高亮文件
  - 支持哪些版本的 python
- 使用哪些库编译软件
  - openssl/libressl: 这 2 个 USE 不可以同时使用
  - jpeg/png/...: 使用某些库使得安装的图像格式转化软件支持对应的图像格式

因为 USE 的不同选择会导致构建的软件包数量繁多，通常 gentoo 只对某些构建耗时较长的软件包提供了构建好的二进制包（在某些 USE 下），对其他软件包需要用户手动构建，以致于有人[吐槽](https://www.zhihu.com/question/20047345/answer/1176966252)：

> 我装了 gentoo，学校派人来我们实验室调查是不是有人挖矿。

当然， gentoo 的卖点是选择和性能，不是耗电量 :smile:

- 选择：选择安装哪些文件，例如 zsh 用户就不需要安装 bash 补全，或支持哪些功能，通过去掉对某些不常用的图像格式的支持减少图像格式转化软件的大小
- 性能：从源代码构建软件可以比下载在别的设备上构建好的软件针对用户的硬件条件做出更具体的优化

### 解决方案

众所周知，SAT 作为 NPC 问题，目前没有多项式时间算法。所以所有包管理器（nix 除外），实际上都是用的启发式算法。用户在安装软件前等待了很长的时间，最终得到的也不一定是最优解，或者得到的是无解。类似 ArchLinux 之类的发行版，干脆每个软件只提供一个最新的版本，减少求解空间。

另一个问题是多个不同版本的软件共存的问题。有 2 种可能用户需要安装多个不同版本的软件：

- 软件 i 1.0 需要 软件 x 大于 1.0 ，软件 j 1.0 需要 软件 x 小于 1.0 ，用户 `pip install i j` 时被告知无解，或在 `pip install i && pip install j` 时安装成功 i 再在安装 j 时停下来被询问要不要卸载 i 。
- 用户真的需要多个不同版本的软件，例如 `python2` 和 `python3` 完全是 2 个不同的语言。

开源社区对房间里的大象也并非视而不见。例如：

- 每个子版本号 `X` 不同的 `python` 都会把把库安装到 `/usr/lib/python3.X` ，防止冲突， `perl`, `ruby` 等同理
- 对于一定会冲突的文件，例如 `/usr/bin/python` ，每个子版本号 `X` 不同的 `python` 都会先安装 `/usr/bin/python3.X` ，再由另外一个软件管理 `/usr/bin/python` 到底是指向哪一个 `/usr/bin/python3.X` 的符号链接。这个版本管理器在 Debian 系上是 `update-alternative` ，在 Gentoo 系上是 `eselect` ，在 `Arch` 系上不存在（`Archlinux` 直接把 `/usr/bin/python` 设为最新的稳定版 `/usr/bin/python3.X` ）。
- 上面的方案对不同子版本号 `X` 的 `python` 有效，但不同修订版本号的 `Y` 的 `python3.X.Y` ，会因为都需要 `/usr/lib/python3.X` 而失败。需要专门针对某一种语言的虚拟环境，例如 `pyenv` 把不同版本的 python 发行版（包括 Cpython, pypy, anaconda, miniconda） 安装在不同路径，再通过修改符号链接的方式实现上面的方案提供的功能。

面对这 2 个问题， nix 的创举是它作为一个包管理器，一举绕开了问题。为什么不能同时安装 `python3.11.0` 和 `python3.11.1` ？因为路径冲突了啊。现在 nix 把所有软件往形如 `/nix/store/XXX-python-3.X.Y` 的路径里安装，让每个软件都只能看到自己想要版本的依赖。

![all](https://picx.zhimg.com/80/v2-2095e2414ccd16d317ae5267749d7d4b_1440w.webp)

为此，我们要考虑另一个问题：一般所有的 GNU/Linux 发行版都遵循 FHS 标准，即希望所有的动态链接库都在 `/lib` (`/usr/lib` 的符号链接)下。即 `rpath` 就是 `/lib` 。同样，需要使用用户手册的软件都希望用户手册在 `/usr/share/man` 下，需要使用字体的软件希望字体在 `/usr/share/fonts` ，等等。怎么解决这个问题？使用符号链接吗？那如果我们提供从
`/nix/store/XXX-python-3.11.0/lib/libpython3.11.so` 指向 `/usr/lib/libpython3.11.so` 的链接，那 `python3.11.1` 该怎么办？

Nix 干脆不破不立——彻底废弃 FHS ，所有二进制库和可执行文件通过 `patchelf` 修改 `interpreter` 和 `rpath` ，这也是为什么你会在之前看到 NixOS 上如此奇怪的 `rpath` 和 `interpreter` 的原因。对于其他软件也通过用 `shell` 脚本封装起来等方式确保可以正常工作。

当然， Nix 创始人 Eelco Dolstra 那 200 多页的博士毕业论文远不止笔者说的这么简单。他的博士论文主题是确定性系统，在这个以 Nix 为核心的系统中，通过使用 Nix Lang 来构建包从而确保一切包的构建都是可复现的——下面让我们谈谈包的构建。

## 包的构建

一般软件包的构建脚本分为 2 个过程：

- 元信息的声明：最终被写入到 `ninja-1.11.1-3-x86_64.pkg.tar.zst` 中的隐藏文件和 `ninja-1.11.1-py2.py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.whl` 中的 `ninja-1.11.1.dist-info/*`
  - 软件的作者
  - 许可证
  - 版本号
  - ...
- 实际的构建需要完成的命令

Debian 系和 Redhat 系的包构建一般被称为分布式包构建系统，即每个项目的代码仓库中包含构建的代码（例如，通常会在一个叫 debian 的目录下包含所有构建需要的文件）。在 cmake 中可以通过 `cpack -G DEB` 和 `cpack -G RPM` 获得对应的包。与之相对的是集中式包构建系统，存在一个集中的代码仓库，里面每个包都拥有一个属于自己的包构建脚本，例如：

- Homebrew: `*.rb`
- ArchLinux: `PKGBUILD`
- Android Termux: `build.sh`
- Gentoo: `ebuild`

下面给出更详细的介绍。

### 指令式包构建

指令式包构建对应编程语言中的指令式编程语言。以 [GNU hello](https://www.gnu.org/software/hello/) 为例。 GNU hello 是 GNU/Linux 中输出 hello world 的一个软件，它存在的意义是像所有 GNU/Linux 用户展示一个标准的 C 语言项目应该是什么样的。关于 C/C++ 构建系统，特别是 autotools 的 `./configure && make && make install`，笔者在之前的博文里介绍过，不再赘述。

#### [AUR](https://aur.archlinux.org/packages/hello)

`PKGBUILD`:

```bash
# Maintainer: Michał Wojdyła < micwoj9292 at gmail dot com >
#Contributor: leo <leotemplin@yahoo.de>
pkgname=hello
pkgver=2.12.1
pkgrel=1
pkgdesc="Prints Hello World and more"
arch=(i686 x86_64)
url='https://gnu.org'
license=('GPL')

source=(https://ftp.gnu.org/gnu/hello/$pkgname-$pkgver.tar.gz)
md5sums=('5cf598783b9541527e17c9b5e525b7eb')

build(){
    cd "$pkgname-$pkgver"
    ./configure --prefix=/usr
    make
}
package(){
    cd "$pkgname-$pkgver"
    make DESTDIR="$pkgdir/" install
}
```

#### [termux](https://github.com/termux/termux-packages/tree/master/packages/hello)

`build.sh`:

```bash
TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/hello/
TERMUX_PKG_DESCRIPTION="Prints a friendly greeting"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=2.12.1
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://ftp.gnu.org/gnu/hello/hello-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=8d99142afd92576f30b0cd7cb42a8dc6809998bc5d607d88761f512e26c7db20
TERMUX_PKG_DEPENDS="libiconv"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    LDFLAGS+=" -liconv"
}
```

2 段脚本都使用 bash 编写，这是所有 GNU/Linux 上都确定一定安装的软件（Android 和 musl/Linux 不是 GNU/Linux）。
使用别的语言的包构建脚本也存在，例如 macOS 上 bash 不是预装的，所以出现了使用 tcl 的 mac Ports 和使用 ruby 的 homebrew ，或者一些编程语言的包管理器可以确保某种编程语言一定是安装好的，所以选择该编程语言。

可以看到 2 段脚本除最后一段外均为元信息的声明。 termux 甚至因为 autotools 在开源社区的广泛使用让缺省的 `termux_step_make`, `termux_step_configure`, `termux_step_make_install` 都为对应的指令。也可以通过类似 `TERMUX_PKG_FORCE_CMAKE=true` 的方式换其他构建系统。

总而言之，指令式包构建中实际的构建需要完成的命令是以可以执行的指令的形式直接编写在脚本中的。这带来了以下 2 个问题：

- 如果需要获得对应包的元信息，必须得用对应的脚本语言的解释器执行该脚本。可能有人会想为什么不用正则表达式匹配 `PKGBUILD` 中的 `(?=^pkgver=)(.*)$`? 假如该 bash 脚本含有 `_pkgver="v2.12.1"; pkgver=${_pkgver##v}` 呢？任何合法的 bash 脚本都要支持的话，靠正则表达式是行不通的。为此，AUR 甚至要求所有 ArchLinux 的包提供一个 PKGBUILD 生成的 `.SRCINFO` 记录元信息，这样就不必读取 `PKGBUILD` 这个 bash 脚本了。
- 难以确保包是否需要重新构建。例如 `PKGBUILD` 没有正确的缩进，如果添加了缩进后，再 `makepkg` 构建包会重新开始，原因是包构建器难以知道前后 2 个 `PKGBUILD` 在语义上是等价的。
- 难以复现。考虑这样一个 `PKGBUILD`:

```bash
# ...
build(){
    cd "$pkgname-$pkgver" || return 1
    cmake -Bbuild -DCMAKE_INSTALL_PREFIX=/usr
    make -Cbuild
}

package(){
    cd "$pkgname-$pkgver" || return 1
    DESTDIR="$pkgdir" make -Cbuild install
}
```

这看上去可以正常工作，实际测试起来也可以——如果你没有 `export CMAKE_GENERATOR=Ninja` 的话。正确的代码是：

```bash
# ...
build(){
    cd "$pkgname-$pkgver" || return 1
    cmake -Bbuild -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build
}

package(){
    cd "$pkgname-$pkgver" || return 1
    DESTDIR="$pkgdir" cmake --install build
}
```

同样，在 perl 包构建时也要避免 `$PERL5LIB`, `$PERL_MM_OPT`, `$PERL_LOCAL_LIB_ROOT` 的影响。参见 [ArchLinux Wiki](https://wiki.archlinux.org/title/Perl_package_guidelines#PKGBUILD_examples):

```bash
build() {
    cd $pkgname-$pkgver || return 1
    unset PERL5LIB PERL_MM_OPT PERL_LOCAL_LIB_ROOT
    export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps
    perl Makefile.PL
    make
}

check() {
    cd $pkgname-$pkgver || return 1
    unset PERL5LIB PERL_MM_OPT PERL_LOCAL_LIB_ROOT
    export PERL_MM_USE_DEFAULT=1
    make test
}

package() {
    cd $pkgname-$pkgver || return 1
    unset PERL5LIB PERL_MM_OPT PERL_LOCAL_LIB_ROOT
    make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
}
```

所以，比起想方设法教育包构建脚本的编写者不要犯任何愚蠢的错误， 我们更希望犯下这些错误的包根本就不该被成功构建，换言之——不可复现（在某些用户的环境下能被成功构建，在某些用户的环境下不能）的包——本不该存在！

### 声明式包构建

#### 数据描述语言

最初编程语言的包构建一般都是通过一个脚本语言完成，例如 python 的 `setup.py` ， `perl` 的 `Makefile.PL` ，但后来它们几乎通通都转向了数据描述语言:

- javascript: `package.json`
- perl: `dist.ini`
- python: `pyproject.toml`
- julia: `project.toml`
- rust: `cargo.toml`
- ...

数据描述语言显然功能不可能超过图灵完备的脚本语言，但所幸大多数时候也够用了，毕竟对某一种确定的编程语言而言，它的包构建步骤通常也是确定的，所以完全可以省略，像 Android termux 就默认所有项目都是用 C 编写的，自然构建方式要么 autotools 要么 cmake ，自然 `build.sh` 就不用写 `termux_step_make`, `termux_step_configure`, `termux_step_make_install` 这些函数了。如果忽略钩子函数，剩下的元信息完全可以用数据描述语言描述。

数据描述语言解决了以下问题：

- 可以直接获得元信息
- 包构建文件（不能成为脚本了）读取完就是一个字典，判断前后 2 个字典是否相同判断 2 个包是否相同。

至于可复现性问题，例如 `python -m build` 默认会用 `venv` 来创建虚拟环境，尽可能减少用户环境中的变量对 python 包构建的影响。但即便如此，仍然不能完全避免。注意到之前的 `pip install ninja` 了吗？这可是核心部分用 C 实现的 python 包，你以为逃得掉的 `$CMAKE_GENERATOR` 吗？

#### 函数式编程语言

在复现性上， docker 是一个解决方案，但不能用户系统上所有软件都用 docker ，那样还不如鼓励开发者静态链接——为了驱逐这房间里的最后一只大象， Eelco Dolstra 在他的博士毕业论文里提出了一种引入函数式编程来实现包构建的系统。这就是 Nix ，简而言之， `nix-instantiate` 将 `default.nix` “编译”为 `/nix/store/XXX-*.drv`, 一种数据描述语言，其中包含了构建一个包所有需要的一切，包括环境变量、依赖项、构建的指令，再通过 `nix-store -r /nix/store/XXX-*.drv` 来实际执行包构建。关于个中细节， [Nix Pill](https://nixos.org/guides/nix-pills/index.html) 有更加入门级的介绍。在此不做赘述。

首先是犯下难以读取元信息之罪的指令式包构建系统，其次是犯下不可复现之罪的数据描述式包构建系统……至此，我们终于得到一个看上去还行的方案，但问题结束了吗？ nix 已经问世 20 年，正如当年的 git 、 docker 等开源项目一样，[提供 nar 托管服务的商业公司](https://cachix.org)也已经存在——但没有人能判断未来会如何。毕竟：

> 一个人无法预见未来，这也许是一件好事。
>
> —— 阿加莎·克里斯蒂 《无人生还》
