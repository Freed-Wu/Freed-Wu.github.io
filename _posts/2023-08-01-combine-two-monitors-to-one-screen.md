---
title: 将两块显示器组合成一块超大的屏幕
tags:
  - develop
---

> 程序员永远不会停止对显示器、键盘、处理器、内存、存储等设备的追求
>
> -- [醉卧沙场](https://www.zhihu.com/question/377137694/answer/2317443703)

## 动机

导师为每个学生配备了一台主机和两台 2560x1440 的显示器。本着物尽其用的原则，现将两台 2560x1440 的显示器拼接为一个 2880x2560 的大显示屏。

展示效果：

### Video

无论是顶部弹幕和底部弹幕都不会遮挡 16:9 的视频。

[![video](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/b5d75eac-9b0e-4aa0-93d8-fc480c3938f1)](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/872b01a8-257a-40fb-84b7-fde2eb0acbec)

### Coding

分割屏幕的空间变大了。

[![coding](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/44ffb5fc-a967-4619-8ec2-35f0134e0edf)](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/b0d50018-a2e3-4ad4-8be6-f4a6a1a01854)

### Reading

主流的双栏论文刚好被两块显示器的顶部边框一分为二。 nice!

[![reading](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/9e853ea1-70af-48e9-adc5-f93b5b25e6d0)](https://user-images.githubusercontent.com/32936898/203045646-d485b86d-e3dc-46b5-8ebc-13aa0b25294f.jpg)

## 背景

### 交互方式/用户界面

用户界面通常分为文本用户界面 (TUI) 和 图形化用户界面 (GUI) 。
除此之外还有无用户界面的命令行 (CLI) 交互方式。

并非只有操作系统才能显示图形化用户界面。例如可以利用
[framebuffer](https://en.wikipedia.org/wiki/Framebuffer):

- UEFI/BIOS
- boot loader: grub 让用户选择到底要进入哪一个操作系统。

[![fallout-grub-theme](https://camo.githubusercontent.com/09da64b6fe7adbd45f30689f805d956c5a242de0e47c09a325114861b527954c/68747470733a2f2f692e696d6775722e636f6d2f374c555977546e2e676966)](https://github.com/shvchk/fallout-grub-theme)

### 图形化用户界面

排除一些软件直接利用 framebuffer 而非 X11/Wayland 去显示图像或 pdf 。
Linux 的图形化用户界面主要分为 X11 和 Wayland 2 个方案。

- X11: X window system 的 第 11 个版本，很有可能会是最后一个版本
  - 历史悠久： 1984 年 X window system 的第一版就已问世。
  - 兼容性好（bug 少，或者说笔者压根没遇到过）
  - 跨平台：已被移植到（笔者用过的）：
    - Windows: [Cygwin/X](https://x.cygwin.com)
    - Android: [Termux/X](https://wiki.termux.com/wiki/Graphical_Environment)
    - X 被移植到这些平台的主要用途还是丰富这些平台的软件生态。
      不少依赖 POSIX 和 FHS 标准的 Linux 独有的图形化用户界面软件只能靠这种方式才能被移植过去。
      但注意 X11 性能并不好。如果能找到这些平台的不依赖 X 的替代软件建议更换。
- Wayland
  - 新： 2008 年 Wayland 项目正式启动
  - 被寄予厚望：基本就是作为 X11 的接班人被培养的。 gdm 等登录管理器甚至默认使用 wayland （或者说想让用户多汇报 bug ）
  - 实时帧率远高于 X11 ，这对于 Steam OS 等用于游戏机的 Linux 发行版是极其重要的
  - 触屏体验个人认为比 X11 好，但你得买台触屏电脑才能体验到
  - 兼容性不如 X11 。例如：

早期在 nvidia 显卡下被报道过有屏幕撕裂的 bug 。不过此 bug 已被某些用户报告消失（可能是 nvidia 驱动开源的缘故？）。

> 整体动画和特效很惊艳，没有了 X11 那种山寨的感觉，纯 wayland 环境下完全没有屏幕撕裂，实时帧率远高于 X11 环境
>
> -- [2022 年,用 Wayland 开启 linux](https://zhuanlan.zhihu.com/p/531205278)

某些视频会议的软件无法投屏，得额外用 X11 启动。

> 原生 Wayland 下无法使用摄像头，无法直接进行屏幕共享。如有上述需求请使用 wemeet-x11 启动。
>
> -- [腾讯会议](https://aur.archlinux.org/packages/wemeet-bin)

某些支持背景透明的软件（例如终端模拟器）无法支持。

> [window_background_opacity cannot work on wayland](https://github.com/wez/wezterm/issues/3766)

### 桌面环境

<!-- markdownlint-disable MD033 -->

| Linux 桌面环境（DE）九宫格           | 用户善良<br/>功能多才是好桌面环境                                                                                                                                                                                                                                                           | 用户中立<br/>功能够用才是好桌面环境                                                                                                                                                                                           | 用户邪恶<br/>桌面环境是什么？能吃吗？                                                                                                                                                                                                          |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 语言保守<br/>C 才是 Linux 软件开发的正统 | ![Gnome](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/a39b103d-6171-42b7-bc85-796b5186175a)<br/>[Gnome](https://www.gnome.org/)<br/>[Ubuntu](https://ubuntu.com/) 默认桌面<br/>我占用率大我先说话                                                                        | ![Xfce](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/17bf0061-7e09-49ff-a08c-a1dd37bf6d55)<br/>[Xfce](https://www.xfce.org/)<br/>[稚晖君](https://github.com/peng-zhihui/)代言<br/>比什么功能，我们比内存占用  | ![i3](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/14ef9c8c-1a28-4899-a87a-1bc91b2d971a)<br/>[i3](https://i3wm.org/)<br/>i3 大法好<br/>退 DE 保全家                                                                 |
| 语言中立<br/>OOP 才是桌面环境开发的王道    | ![KDE](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/b38919ef-4936-448c-b188-7fdd0a66a031)<br/>[KDE](https://kde.org/)<br/>[钛山](https://tysontan.com/)认证，[ArchLinux](https://archlinux.org/) [投票榜](https://pkgstats.archlinux.de/fun/)第一<br/>是我，是我先，明明都是我先来的 | ![LXQt](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/28835666-7bb4-43f8-90d6-f75c236a25e5)<br/>[LXQt](https://lxqt-project.org/)<br/>不[会写桌面环境的内科医生](https://github.com/PCMan/)<br/>不是好的软件工程师 | ![awesome](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/54cc93c1-d5d3-4874-8eb8-eebba7058948)<br/>[awesome](https://awesomewm.org/)<br/>如果我拿出 [lua](https://www.lua.org/)<br/>阁下又该如何应对呢                      |
| 语言混乱<br/>邪教                 | ![WSL2](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/5d5c9664-4446-4cf4-9dc4-a449f530b006)<br/>[WSL2](https://learn.microsoft.com/en-us/windows/wsl/about)<br/>WSL2 也是 GNU/Linux ~的虚拟机~<br/>Windows 才是最好的桌面环境                                               | ![Android](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/939b115a-f468-4d4e-8771-9379c9696eec)<br/>[Android](https://www.android.com/)<br/>Android 也是 Android/Linux<br/>Android 才是最好的桌面环境     | ![OpenWrt](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/9848a414-0b1e-41da-aa5e-dc86e90a4ed5)<br/>[OpenWrt](https://openwrt.org/)<br/>OpenWrt 也是 [musl](https://www.musl-libc.org/)/Linux<br/>都有命令行了还要什么自行车？ |

<!-- markdownlint-enable MD033 -->

桌面环境通常包含：

- 窗口管理器。现在的窗口管理器基本已经定型，通常都是：
  - 在窗口的上方增加一个标题栏
  - 标题栏左侧或右侧放置最小化、最大化/还原、关闭、始终最上、隐藏窗口仅保留标题栏等若干个按钮。
  - 右键标题栏弹出菜单。注意早期的窗口管理器并非如此——那是鼠标还只有一个键，类似 twm 的窗口管理器要用先长按再拖动的方式选中菜单。
- 登录管理器。输入用户名和密码的第一个界面。
- 会话管理器。解除锁屏后的会话恢复。
- 文件管理器
- 终端模拟器
- 控制中心（设置）
- 桌面壁纸、任务栏、状态栏、开始菜单等若干远不如前几个重要但能大大提升桌面颜值的部件。有的桌面所谓最美桌面就靠颜值来吸引用户。

目前用户占有量最大的四大桌面：

- Gnome: 用 C (gtk) 开发的重量级桌面
- KDE: 用 C++ (qt) 开发的重量级桌面
- xfce: 用 C (gtk) 开发的轻量级桌面
- lxqt: 用 C++ (qt) 开发的轻量级桌面

重量级桌面通常功能多但耦合严重（例如 gnome 的登录管理器基本不能换成 gdm 以外的登录管理器），
轻量级桌面则倾向于所有部件都可更换。但功能少，例如：

- 不支持用 javascript 编写插件
- [不支持 HiDPI](https://discourse.nixos.org/t/different-behaviour-about-hidpi-set-scale-to-2x-in-different-desktop-environment/28381)

四大桌面的历史有些颇有意思。例如内科医生写代码呀， qt 改许可证呀，在此不作赘述。

## 技术方案

> TwinView 是一种操作模式，其中两个显示设备 （数字平板、CRT 和电视）可以显示任意配置中的单个 X 屏幕。
> 这种使用显示器的方法与其他技术相比，具有几个明显的优势：
> ...
>
> -- [英伟达加速 Linux 图形驱动程序自述文件和安装指导](https://download.nvidia.com/XFree86/Linux-x86/275.28/README/configtwinview.html)

搜索手册不难发现解决问题的方法之一是 TwinView.

### 窗口管理器

进一步以 TwinView 为关键词搜索可以发现：

> 某些桌面环境尚不支持此功能。 Openbox 已经过测试并且可以使用此功能。
>
> -- [多显示器](https://wiki.archlinux.org/title/Multihead#Combine_screens_into_virtual_display)

笔者[测试了四大桌面的结果](https://bbs.archlinux.org/viewtopic.php?pid=2064528)也是如此。

lxqt 默认使用 openbox 作为窗口管理器，并在设置里提供了配置方法：

![Monitor Settings](https://user-images.githubusercontent.com/32936898/203046539-15272426-f8ec-48b2-ad71-22afab7eb373.jpg)

[![DE](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/cca052c3-d748-4a79-853c-71bc5abb4a7f)](https://user-images.githubusercontent.com/32936898/203045565-56fde3d9-4c53-465f-8606-1d098b38632a.jpg)

### 登录管理器

lxqt 默认使用的登录管理器是不支持 TwinView 的。需要更换 xdm 。 xdm 没有图形化用户界面的配置方法。

此主机共有 4 个媒体接口。 2 台显示器被分别连接到了 DP-0 和 HDMI-1 。假设我们不知道 2 台显示器被连接到了哪里，我们可以通过以下方法查看：

```shell
$ xrandr
Screen 0: minimum 8 x 8, current 2880 x 2560, maximum 32767 x 32767
DVI-D-0 disconnected (normal left inverted right x axis y axis)
HDMI-0 disconnected (normal left inverted right x axis y axis)
DP-0 connected primary 1440x2560+0+0 left (normal left inverted right x axis y axis) 597mm x 336mm
2560x1440     59.95*+  74.97
1920x1080     74.97    60.00    59.94    50.00
1680x1050     59.95
1440x900      59.89
1280x1024     75.02    60.02
1280x960      60.00
1280x720      60.00    59.94    50.00
1024x768      75.03    70.07    60.00
800x600       75.00    72.19    60.32    56.25
720x576       50.00
720x480       59.94
640x480       75.00    72.81    59.94    59.93
DP-1 disconnected (normal left inverted right x axis y axis)
HDMI-1 connected 1440x2560+1440+0 right (normal left inverted right x axis y axis) 597mm x 336mm
2560x1440     59.95*+  74.97
1920x1080     74.97    60.00    59.94    50.00
1680x1050     59.95
1440x900      59.89
1280x1024     75.02    60.02
1280x960      60.00
1280x720      60.00    59.94    50.00
1024x768      75.03    70.07    60.00
800x600       75.00    72.19    60.32    56.25
720x576       50.00
720x480       59.94
640x480       75.00    72.81    59.94    59.93
```

修改 `/etc/X11/xorg.conf.d/10-monitor.conf` 去告诉 xdm 桌面的设置：

```xf86conf
Section "Monitor"
    Identifier "DP-0"
    Option "Rotate" "left"
EndSection

Section "Monitor"
    Identifier "HDMI-1"
    Option "Rotate" "right"
    Option "RightOf" "DP-0"
EndSection
```

使能 TwinView ：

```xf86conf
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    Option "NoTwinViewXineramaInfo" "1"
EndSection
```

[![xdm](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/c861ea2d-f7ff-41c7-ae93-9dcea31dd072)](https://user-images.githubusercontent.com/32936898/203045505-86867194-4c5a-474a-9227-7aedb88b5dc8.jpg)

### 屏幕保护程序

目前没有任何屏幕保护程序支持 TwinView 。它们将分别对待两台显示器。以下是 lxqt 默认的屏幕保护程序 `xscreensaver` 显示的结果：

[![xscreensaver](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/7398b05c-766e-4b43-adf6-57948695f063)](https://user-images.githubusercontent.com/32936898/203047977-1cbfabe7-e5d3-4251-a2a2-467129d56f22.jpg)

### 问题

不能扫描位于屏幕中间的二维码：

![qr](https://github.com/Freed-Wu/fit-the-screen-consisting-of-two-monitors/assets/32936898/86aeb75e-db4e-4175-8a1e-590d813506b4)

呃，笔者目前只能写了个[用户脚本](https://github.com/Freed-Wu/fit-the-screen-consisting-of-two-monitors)对每个网页符合某些条件的元素进行微调来尽可能让某些主要元素避开中间的分隔线：

![qr-after](https://github.com/Freed-Wu/fit-the-screen-consisting-of-two-monitors/assets/32936898/2e8eb4f9-9b76-4eb6-a036-e9fc3f574428)

关于如何判断哪些元素是符合某些条件的要微调的元素充满了经验主义，如果有读者想到了更好的办法可以分享给笔者。 TIA!
