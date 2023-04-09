---
title: 工时统计工具汇总
tags:
  - develop
---

难道不想看看自己每天都干了啥嘛~

![statistic](https://github.com/wakatime/wakatime-cli/assets/32936898/e68845a0-5f3b-4818-9067-ba8ec23bb755)

统计工时的原理本质上就是：

1. 工作时工作需要使用的软件上的某个插件每隔一段时间发送数据到统计工具的服务器上
2. 统计工具的服务器每隔一段时间通过邮件、微信、钉钉机器人等发送工时信息的通知
3. 统计工具提供一个可视化的网站

## 统计工具

统计工具通过插件统计每天工作的时间。这些插件可以包括：

- 编辑器
- 浏览器
- REPL
- 办公软件（Office）
- 修图软件
- 翻译软件
- ...

为了防止挂机，插件要在规定时间间隔内发心跳信号。最终显示不同系统不同编辑器不同语言不同项目的工作时间。

或者统计操作次数，一次操作称为 1 点经验：

- 编辑器中插入、删除、粘贴等
- REPL 中输入一条命令。因为大多数 REPL 不支持统计插入、删除、粘贴次数，但 zsh 因为有强大的 zle (zsh line editor) 可以。

不用发心跳信号，可以计算经验后一次性 post 到统计工具的服务器上。

一般统计操作次数的统计工具插件更难实现。最终显示不同机器不同语言不同时间段的操作次数。

- [wakatime](https://wakatime.com/)
  - 服务器不开源、插件代码开源
  - 目前用户最多
  - 数据保留更多时间要付费
  - 引入了[排行榜](https://wakatime.com/leaders)：可以看到别人一天写多长时间代码，互相攀比非常好玩
  - 封装了 1 个[命令行接口](https://github.com/wakatime/wakatime-cli)。可以直接调用此接口降低插件开发难度。
  - 插件数量多。笔者也参与了一些插件开发，比如统计 [python REPL](https://github.com/wakatime/repl-python-wakatime/) / [perl REPL](https://github.com/Freed-Wu/Reply-Plugin-Prompt/) 的使用时间
  - 不光统计编程，浏览网页、修图甚至翻译都会被统计。笔者在编写[一个命令行的翻译软件](https://github.com/Freed-Wu/translate-shell/)时就利用其功能统计翻译时间。
- [codetime](https://codetime.dev/)
  - 服务器、插件代码开源
  - 国人出品
  - 目前只支持 3 个插件
- [rescuetime](https://www.rescuetime.com/)
  - 不开源
  - 不支持显示具体每个项目，只能看到所有项目的时间总和
  - 数据保留更多时间要付费
- [codestats](https://codestats.net/)：目前唯一一个统计操作次数的统计工具
  - 服务器、插件代码开源
  - 靠官网上广告盈利
  - 引入了等级设定：按开方关系从经验计算等级。等级越高升级所需经验越多。笔者个人感觉看编程语言升级是一件非常有成就感的事情。

可以查看开源代码来了解插件需要获取哪些信息防止数据盗取。

## 徽章

可以通过统计工具的接口获取工时信息。用途是实现徽章以放置在你的主页上或者下载以备份。一般统计工具都提供了封装好的接口。

- [![wakatime](https://wakatime.com/badge/user/4472c829-ef20-4823-ae4b-4ed0954e0b44.svg)](https://wakatime.com/@wzy)
- [![codestats](https://img.shields.io/badge/dynamic/json?url=https://codestats.net/api/users/Freed-Wu&query=%24.total_xp&label=xp&logo=data:image/png%3Bbase64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfjAwcHLTn8E0WHAAACqUlEQVRIx+3US2tdVRQH8N953OTaRqgvQm1iwApiSyG11Maq0IAJjVAH4kALnRQEFVp0YgXrA8kXUFD8Ag7qRBR8IBbEKtSIpRGVSlMdNBVsFaFptCW5Zzk4556cm1r8ALr35Oy9zl6P//+/Fv+vpOeUSRDVbShEw5pKG6fV1urxtQIksn+25tVHqiO3zZiNblA477RZP1ioo3dsMGmLm4Xf/WTWrIsr0XnEt6JndyzYi1wi8ZLFKu1yFy4aLzNIdbzmIC47Zsa8wpCtths0jNSy1x3Aae+as2TQ3R6w3mA3+rQQjrqzrjrBgP0eAvcohCNalSXBWk+7vyxgh47wqRyZtpZcXoOa40Vhwe3ok1fWxnpbWLQZrVUoZ1I53hR+NiBtMJXIJaQG7cInvpdb0rLbTWDAlLZCggWsN6KQyKrswnKpg0khHEQ/JoTDYL+wr7rdI4Rv7Kxo72YHnhLC7qraG71qM7jNtCGq3z4QOjp+dMTzJqxbUeYLQhir+LiW3Nd6w5WGDn7zlltL9//uoFQqIw54x3cuCR3hvFF4UghTFQcjPjQOtvrYlrqElV7IDHvcjBC+lvOgEJ6p4BoXngP7hMdowJZW/Cc1KmGKW8wL71e/JjbqrwR0R/24t0/Tmq9wKHXBUUwYtawlnHEFdMzV/R6yBkKFJfxBV3rbLAmf60emT6uWauo6sEZaaa/cfXhCCHtL7A8L4QubGun22+kjz4JXvGe0nkcJtjsnnDOY60hNG3DIfU44ZsYF19tkzJDcZ6DtYVNO+dKcv6yzw6Q2XvZrlxr2OLlqoFzylV1KuR+32LAUwhmPIu0mnFUj7V4j1vjTL0456WwD+2Gj7rJB26J5Jxx3Wapotu7VQ7U7h3vncReJ7GqGm07KVJvOkh7rqqH+X15/A4KR4pXr8wp+AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE5LTAzLTA3VDA3OjQ1OjU3KzAxOjAwlMWKwgAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxOS0wMy0wN1QwNzo0NTo1NyswMTowMOWYMn4AAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAV3pUWHRSYXcgcHJvZmlsZSB0eXBlIGlwdGMAAHic4/IMCHFWKCjKT8vMSeVSAAMjCy5jCxMjE0uTFAMTIESANMNkAyOzVCDL2NTIxMzEHMQHy4BIoEouAOoXEXTyQjWVAAAAAElFTkSuQmCC)](https://codestats.net/users/Freed-Wu)

XP 是经验的缩写！！！

## 数据同步

因为不少统计工具的数据保留更多时间要付费，所以可以将每天的数据下载下来以备份。

- [wf2311/wakatime-sync](https://github.com/wf2311/wakatime-sync)
  - 用 java 开发
  - 把 wakatime 的信息下载后保存为 mysql 的数据库格式
  - 支持 [Server 酱](https://sct.ftqq.com/)、钉钉机器人的通知。即可以每天在微信、钉钉收到昨天的 wakatime 信息提醒
- [superman66/wakatime-sync](https://github.com/superman66/wakatime-sync)
  - 用 javascript 开发
  - 把 wakatime 的信息下载后保存为 json
  - 保存到 github gist
  - 提供 github action 。例如，笔者就在点文件对应的 github 仓库中设置了 [定时的 CI/CD](https://github.com/Freed-Wu/Freed-Wu/blob/main/.github/workflows/wakatime.yml)
  - 支持 [Server 酱](https://sct.ftqq.com/)的通知。由 github action 的 `SCU_KEY` 控制

```yaml
on:
  schedule:
    # modify by yourself
    - cron: MM HH dd mm ww
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: superman66/wakatime-sync@v1.0.0
        env:
          GH_TOKEN: ${{secrets.GH_TOKEN}}
          GIST_ID: ${{secrets.GIST_ID}}
          WAKATIME_API_KEY: ${{secrets.WAKATIME_API_KEY}}
          SCU_KEY: ${{secrets.SCU_KEY}}
```

## 数据可视化

需要对下载的数据进行可视化。

- [wf2311/wakatime-sync](https://github.com/wf2311/wakatime-sync): 也包含可视化代码
  - [效果不错](https://wakatime.wangfeng.pro/)，支持：
    - ![每日项目持续时间图](https://camo.githubusercontent.com/748d4fbebcb3442e720c06fed357cf95495a4a0d898310f210af989ad1540ed5/68747470733a2f2f66696c652e7766323331312e636f6d2f696d616765732f32303139303131353138303733382e706e67)
    - ![时间范围内活动情况](https://camo.githubusercontent.com/5384323285b085902d452d4d81282f510d620fbcbe49393a5f9e4f2aef50dd69/68747470733a2f2f66696c652e7766323331312e636f6d2f696d616765732f32303139303131353138303833382e706e67)
    - ![每日编码耗时日历图](https://camo.githubusercontent.com/34961a95032d589a037c74404e8779dc53e8b96446cefaf21b86399e6e6f1f58/68747470733a2f2f66696c652e7766323331312e636f6d2f696d616765732f32303139303131353138303934362e706e67)
- [superman66/wakatime-dashboard](https://github.com/superman66/wakatime-dashboard):
  - [仅支持项目持续时间图](https://wakatime.chenhuichao.com/)

![wakatime-dashboard](https://github.com/superman66/wakatime-dashboard/blob/master/screenshot/wakatime-dashboard.jpg)

## 插件开发

再多提一嘴关于插件的开发。因为普通用户对这个可能不感兴趣所以放在了最后。

按编程范式来分，这是典型的事件驱动编程：当某个事件触发时，执行一个回调函数，在回调函数中向 wakatime / codestats 的服务器发送信息。
wakatime 因为提供了 [wakatime-cli](https://github.com/wakatime/wakatime-cli) 所以会简单一点，只需要在后台另起一个 detach 的子进程即可。

笔者负责了 wakatime 的[一些编程语言的 REPL ， gdb 的插件](https://wakatime.com/terminal)开发：

![wakatime](https://github.com/wakatime/prompt-style.lua/assets/32936898/b4397806-0ab3-4751-baaa-d9dfed92ace7)

不同的软件提供了不同的回调函数（钩子 hook 或句柄 handle ）：

- vim: `autocmd InsertEnter * call namespace#function_name()` 每次进入插入模式调用函数。
- REPL:
  - 有些 REPL 的命令提示符是一个函数，相关截图参见
    [REPL 主题](https://freed-wu.github.io/2023/09/01/dotfiles.html#repl-%E4%B8%BB%E9%A2%98)。所以我们可以把向服务器发送信息的指令放在命令提示符的函数体内。
    - python 的命令提示符是 `str(sys.ps1)`, 定义 `sys.ps1.__str__()` 即可
    - perl reply 的命令提示符是 `prompt()`
    - lua prompt 的命令提示符是 `(require "prompt").prompts[0]`, 可以是字符串或函数
    - tcl readline 的命令提示符是函数 `::tclreadline::prompt1`
  - 有些 REPL 的命令提示符是一个格式化字符串。例如 `$PS1` 可以是类似 `\w`, `\t`
    构成的格式化字符串， `\\` 开头的子字符串会被替换为当前目录名，时间等等。这些 REPL 需要提供别的钩子函数。
    - bash: `$PROMPT_COMMAND` 是一个由若干函数名通过 `;` 连接的字符串。每个函数会在每次命令提示符重新生成的时候被调用
    - zsh: `precmd_functions` 是一个由若干函数名组成的数组。每个函数会在每次命令提示符重新生成的时候被调用
    - gdb:
      - 函数 `hook-XXX` 会在执行 `XXX` 命令的时候被调用
      - 函数 `hook-stop` 在每次单步调试 next ，步入 step 等都会被调用。

笔者也希望更多开发者尝试开发相关插件，以便更好地统计大家每天使用各种软件的时间 :smile:

## 总结

工时统计主要是用于个人编写周报时回顾工作内容。然而似乎也有一些公司部门试图用其做 KPI 考核。私以为不妥。在有开源软件代码审核员呼吁大公司不要刷 KPI 的前车之鉴下，古德哈特定律必将再次灵验：

> 若一个经济学的特性被用作经济指标，那这项指标最终一定会失去其功能，因为人们会开始玩弄这项指标。
>
> -- 查尔斯·古德哈特
