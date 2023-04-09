---
title: Windows 平台开发踩坑汇总
tags:
  - develop
  - windows
---

之前因为老师的某个横向只提供 Windows 平台的工具链的缘故（搞笑的是它竟然依赖 `cygwin1.dll` ）不得不开了一台虚拟机搞开发，结果发现对 POSIX 平台的开发者而言 Windows 平台有不少从未见过的坑，做一汇总。

警告：是面向 POSIX 平台（GNU/Linux, BSD, Darwin (macOS) 等）开发者！非 POSIX 平台的开发者就别带节奏啦！不回复就是承认您说得对~

再次警告：笔者非 Windows 用户，因为提（xi）高（ai）效（zhui）率（xing）的缘故从一开始就选择了 GNU/Linux ，对 Windows 的理解不会超过 GNU/Linux （虽然对 GNU/Linux 的理解也仅限学习驱动开发和网络编程时翻过的一点内核源码了，在这两方面有 [Linux-Device-Driver](https://github.com/d0u9/Linux-Device-Driver) 和 [大佬的博客](https://www.zhihu.com/column/c_1561724947151405056) 在前，不敢班门弄斧）。

## 安装操作系统

### 物理机

主要就 2 个方案：

先准备一个分过区的 U 盘、 SD 卡等存储设备。（必须的）

如果你的 Android 手机拥有 root 权限，你也可以直接把用 [UMS-Interface](https://github.com/oufm/UMS-Interface) 让电脑把手机识别为 U 盘。有时 OS 启动太快电脑刚连上手机还没识别到 U 盘就启动了，可以先进 UEFI/BIOS 再退出。

- 在某一个分区里写入操作系统启动镜像，每次都要格式化，只能支持一个操作系统
  - [rufus](https://github.com/pbatard/rufus) 只支持 Windows
  - [etcher](https://github.com/balena-io/etcher)
  - [etchdroid](https://github.com/EtchDroid/EtchDroid) 只支持 Android ，不需要 root 权限
  - `dd` 只支持 GUN/Linux ，另外会导致分区变为只读的 iso 格式，可能是好事（不会被破坏）也可能是坏事（无法再往该分区放入其他文件）
- 在某一个分区里写入 UEFI/BIOS 启动镜像，每支持一个操作系统就把该操作系统的启动镜像放入到一个指定分区就好，无需再格式化
  - [ventoy](https://github.com/ventoy/Ventoy)

![ventoy](https://camo.githubusercontent.com/0280fc6415276f7940c16341aa4c484a3a7a4ba85bb0e9f71e877a01707198c6/68747470733a2f2f7777772e76656e746f792e6e65742f7374617469632f696d672f73637265656e2f73637265656e5f756566692e706e67)

### 虚拟机

直接加载操作系统启动镜像就好啦~

## 包管理器

“幸福的人总是相似的，比如用包管理器能成功安装软件，不幸的人各有各的报错。” Windows 没有系统级包管理器，第三方包管理器倒是可以分为两类：

- 采用 Windows 路径安装软件的，例如 scoop ， choco ， PortableApps, conda 等。软件通常装在 `C:\Program Files` 下面， PortableApps 则装在 U 盘目录下便于携带。除了 `conda` 外都没有镜像。软件生态都比较少。
- 采用 POSIX 路径安装软件的软件发行版，目前还在维护的主要有 cygwin 和 msys2 。通过利用 cygwin 和 mingw 来将大量开源软件移植到 Windows 平台来填补其生态漏洞。
  - cygwin
    - 所有软件都使用 `cygwin1.dll` 。有对 X 的支持 (Cygwin/X，见[图形化用户界面](https://freed-wu.github.io/2023/08/01/combine-two-monitors-to-one-screen.html#%E5%9B%BE%E5%BD%A2%E5%8C%96%E7%94%A8%E6%88%B7%E7%95%8C%E9%9D%A2)) ，可以运行依赖 X 的图形化用户界面软件。
    - 安装软件有一个 `apt-cyg` 语法类似 `apt-get` 但功能严重确实，比如不支持查询某个文件属于哪个软件包
  - msys2
    - 少量基本软件都使用 `msys2.dll` (`cygwin1.dll` 的分支)，大量软件使用 mingw-w64 (mingw 的 分支)，性能会好一点。没有对 X 的支持，提供原生 Windows 的图形化用户界面软件。
    - 安装软件用 `pacman` ，比 `apt-cyg` 体验好太多

软件数量的对比如下。可以清楚地看到两者的区别。

- Ubuntu: 36114 + 36101 ([PPA](https://launchpad.net/ubuntu/+ppas?name_filter=)) = 72215
- ArchLinux: 11129 + 74523 (AUR) = 85652
- Gentoo: 17622 + 68076 ([overlay](https://gpo.zugaina.org/Search?search=)) = 85698
- NixOS: 88754 + 4008 ([NUR](https://nur.nix-community.org/)) = 92762
- Android Termux: 2324 + 170 (TUR) = 2494
- Windows Msys2: 517 (cygwin) + 2303 (mingw) + 0 (?) = 2820
- Windows Cygwin: 3148 (cygwin) + 0 (?) = 3148

一般包管理器的软件仓库分为两种，一种是官方维护的软件仓库，质量高，出 bug 会有官方维护，另一种是第三方维护的软件仓库，质量参差不齐，出 bug 需要联系打包人。比如 PPA ， AUR ， overlay ， NUR 等等。官方软件仓库的软件数量可以在 [repology](https://repology.org/repositories/statistics) 查到。第三方软件仓库见相应链接。

对 Windows 平台，

- cygwin 的原理是提供一个 POSIX 兼容层 (`cygwin1.dll`)，将 POSIX C 的库函数翻译为 Windows 系统调用，导致这些软件：
  - 独立分发时必须要提供 POSIX 兼容层
  - 性能不如只依赖 Windows C 语言运行时的软件
- 或者直接使用一个开源的 C 编译器将软件编译为只依赖依赖 Windows C 语言运行时的软件的 Windows PE 格式。但该软件的代码只包含 ANSI C 不包含 POSIX C：
  - mingw： 将 gcc 移植到 windows 平台的分支
  - clang： 原生支持 windows

考虑到 Windows 支持 3 个架构 (x86, x64, arm64) 以及 2 个 C 语言运行时 (msvcrt 和 Windows 10 之后发布的对 Unicode 支持更好的 ucrt) 和 2 个 C++ 运行时 （libstdc++ 和 libc++）, 所以一共有 2 x 3 x 2 x 2 = 24 种组合， msys2 官方也只提供了其中 [6 种组合](https://www.msys2.org/docs/environments/)。当然代码都是一样的，只是编译条件不一样。

注：在 wine 的支持下，msys2 提供的软件是可以在 GNU/Linux 下运行的，特别是使用 `pacman` 的 GNU/Linux 发行版，只要把 msys2 软件仓库的地址添加到 `/etc/pacman.conf` 并导入对应的公钥就行~

![msys2](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/f5b4a5cb-8950-43bc-946b-e28969d87766)

### 软件

很多软件，即使移植到了 Windows 平台，因为工作原理的缘故，功能仍然大打折扣。

比如 `tmux` ，允许用户开一个父进程为 init 进程的 shell 进程。这样就不会出现 ssh 远程连接突然网络断了，于是 shell 也退出，在 shell 中跑了一半的进程被 HUP 信号 kill 了（除非你用 nohup ）的悲惨遭遇。问题是 Windows 没有 init 进程，退出 msys 的话进程一样被杀。当然 Android termux 的 tmux 因为没有 root 权限也有表现类似但原理不同的问题。

### 文件权限/模式

POSIX 有 12 权限 `ls -l` ：所有者、同组成员、其它用户的读、写、可执行权限外加 3 个特殊权限以及 14 种属性 `lsattr` 。但 Windows 它也只有只读、隐藏、系统、存档 4 种模式和若干属性，根本没有可执行，靠识别 PATHEXT 的后缀名的文件来判断是否可执行。 `ls -l` 在 Windows 平台会显示一个模拟的 12 权限，例如文件后缀名属于 PATHEXT 就会有 `x` 。所以 `chmod +x` 并不会真正有效。

但无论这个文件是否可执行， shebang 都会生效，当你强制执行一个脚本的时候，例如 `./main.py` 。

`exa` （现在改名 `eza`） 可以查看 Windows 平台 4 种模式和 POSIX 平台 12 权限。其余软件 `lsd` 测试只有对

![exa](https://user-images.githubusercontent.com/4710575/112973291-bd716280-9183-11eb-8def-b3567f6272bc.png)

一个使用 git 的误区是很多人认为 git 会保留文件的 12 权限。实际上 git 只保留 `x` ：用于目录和可执行脚本。因为 `chmod +x` 在 Window 无效，必须改用 `git update-index --chmod=+x` 。

### 用户

Windows 没有 UID 、 GID 的概念。 POSIX 兼容环境是用 SID 模拟的 UID 和 GID 。所以在 GNU/Linux 上看到的 root 用户 id 为 0，第一个普通用户 id 为 1000 这样整齐 的 id 在 Windows 平台就变成一个 hash 出来的难记住的数字。

没有 root 等用户，但有 SYSTEM ， ADMINISTRATOR 等用户。

### 路径

Msys2 安装的软件在 Windows 路径看来被安装在了 `C:\Msys2\usr\bin` (Cygwin 换成 `C:\Cygwin\usr\bin`)，在 POSIX 路径看来被安装在了 `/usr/bin` 。
Windows 安装的软件在 Windows 路径看来被安装在了 `C:\Program Files` （这个带空格的路径绝对是败笔），在 POSIX 路径看来被安装在了 `/proc/cygdriver/c/Program\ Files` 。当然这个路径太长了， Msys 默认把 `/proc/cygdriver` “挂” 到了 `/` 下。（Cygwin 则是 `/cygdriver`）。希望和 WSL 保持一致的开发者可以修改 `/etc/fstab`:

```fstab
none /mnt cygdrive binary,posix=0,noacl,user 0 0
```

### 文件类型

`~/.config/git/config`:

```ini
[core]
  symlink = true
```

当你启用 `symlink` 再 `git clone` 一个含有符号链接的仓库时会遇到一个问题： Windows 默认不允许创建符号链接。所以 Msys2 和 Cygwin 默认的逻辑是把符号链接改为内容为该链接指向的文件的纯文本文件。这么一来很多代码就运行不了了。想象一下 `ln -s main.py ../test.py && chmod +x main.py`,  然后 `main.py` 的内容变成了 `../test.py` ： 这甚至不是一个合法的 python 文件！

方法是启用开发者模式以允许创建符号链接（插句题外话，笔者好像从未在 GNU/Linux 平台见过这种选项）。然后在 `~/.bash_profile` 修改设置：

```sh
if [[ $OSTYPE == cygwin ]]; then
    export CYGWIN=winsymlinks:nativestrict
elif [[ $OSTYPE == msys ]]; then
    export MSYS=winsymlinks:nativestrict
fi
```

如果不能开启开发者模式，就修改选项将符号链接改为该链接指向的文件的复制。这样也能使代码正常运行。

补充一下。老版本的 git 的 HEAD 指针就是指向一个 committish blob 的 符号链接。就是因为要支持当时还不支持符号链接的 Windows 才改成了内容为该链接指向的文件的纯文本文件。你可以 `cat .git/HEAD` 看到这个纯文本文件。

你以为坑踩完了？这才哪跟哪！

## 编程

### 换行符

bash、zsh 等程序只支持使用 `\n` 做换行符。用 `\r\n` 就会见到这个错误：

```sh
$ cat test.sh
ls
$ bash test.sh
test.sh: line 1: $'ls\r': command not found
$ zsh test.sh
test.sh: command not found: ls^M
```

既然 bash、zsh 不能支持 `\r\n`, 为什么有人会下载到使用 `\r\n` 换行的文件呢？当然是因为 git 贴心地帮你把在别人电脑上能正常运行的脚本中的 `\n` 在 `checkout` 时全部替换成了 `\r\n` 啦~

```ini
[core]
  eol = lf ; use \n
  ; eol = crlf ; use \r\n
  ; default
  ; eol = native ; use \n in POSIX and \r in Windows
```

请用 `lf` ！（破嗓门）

### 路径分隔符

各种编程语言为了应对 `\\` 都封装了一些函数，例如 python 的 `os.path` 和 vim script 的 `fnmodify()` ，不要自己手动应付这个，否则你会被疯狂转义！（惨痛教训）

### 终端

POSIX 命令行程序 (cygwin, msys) 使用 ANSI 转义码在终端中显示颜色， 但 Windows 命令行程序 (mingw) 使用 Win32 API。 conhost （Windows 默认终端仿真器）仅支持 Win32 API。 mintty（msys 和 cygwin 的默认值 终端仿真器）仅支持 ANSI 转义码。 `windows-terminal` 两个都支持，但仍然存在一些 [bug](https://github.com/microsoft/terminal/issues/13714)。关于终端模拟器的比较参见[论终端模拟器的优劣](https://freed-wu.github.io/2023/10/01/terminal-emulator.html)。

### 字符编码

从 Windows 10 的某个版本开始已经支持 utf-8 。被 utf-16 的 code page 折磨的小伙伴可以出一口气了。

![utf-8](https://i.stack.imgur.com/dv0tU.png)

## WSL

啊！终于轮到万众瞩目的 WSL 了。在虚拟机中运行的 Windows 显然不需要这个，毕竟物理机上就是 GNU/Linux 。但国内大多数开发者似乎走了跟笔者相反的路子。所以姑且一提吧。

- WSL 1 ： 技术上很厉害的模拟器，类似 wine ，将 POSIX 系统调用翻译为 Windows 系统调用
  - 因为没有真正的内核，所以一些依赖内核的软件是不能跑的，比如 Anbox、Waydroid、Darlin 这样允许 GNU/Linux 运行 android, macOS 软件的容器。
  - GNU/Linux 读写 NTFS 速率很慢
- WSL 2 ： 也很厉害但不如 WSL 1 技术含量更高的自带的虚拟机。在不用容器的情况下也只有如此了。
  - 虚拟机虚拟的是硬件，软件基本都兼容了
  - GNU/Linux 读写虚拟机里的 ext4 速率能不快吗？

互联网上经常有人喊“Windows 是最好的 GNU/Linux 发行版”，笔者听来仿佛在说男娘是最好的女人似的。笔者并不评价任何人的取向，但还请尊重客观事实： Windows 从来就不是 GNU/Linux ，心理和生理都不是。
