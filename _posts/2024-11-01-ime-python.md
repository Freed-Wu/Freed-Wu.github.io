---
title: 输入法的奇妙冒险： python 潮流
tags:
  - develop
  - ime
---

互联网上大多数关于 rime 的文章都是面向用户而非开发者的，甚至 rime 官方文档对二次开发都[语焉不全](https://github.com/rime/home/discussions/1527)。
这为很多潜在开发者为将 rime 移植到新的平台上增加了不少的困难。作为其中之一，笔者也有兴趣在踩坑之后分享一些经验和感受。好了，让我们开始吧：

### 流程

根据笔者的理解， rime 的一个算法逻辑是这样：

1. 调用 `RimeInitialize()` 和 `RimeSetup()` 根据用户配置和系统配置初始化。仅执行一次。
2. 调用 `RimeCreateSession()` 来创建一个会话 ID 。此 ID 会被后续的 API 用到。
3. 调用 `RimeProcessKey()` 接受用户按键输入。输入包括键码和掩码。如果该函数返回
   False ，说明 Rime 不知道如何处理这种输入。如果这种输入是可打印字符，可以直接作为输入法结果返回。对于非可打印字符，通常就返回空。
4. 调用 `RimeGetContext()` 得到上下文，包括排布和菜单。排布提供了输入解码后的结果（还记得双拼的解码吧）和光标的位置范围。菜单提供了候选项的信息。如果候选项不为空，绘制输入法菜单的用户界面。
5. 如果为空，例如用户输入 `ni` 后输入 1 选中了第一个候选项，这时调用
   `RimeGetCommit()` 来获取上一轮第一个候选项的内容“你”。但有时候选项为空可能是确实没有对应的候选项，需要先 `RimeCommitComposition()` 返回一个 True 确认一下。

除此之外一些重要的 API ：

- `RimeClearComposition()` 手动清空所有之前的 `RimeProcessKey()` 的结果
- `RimeGetSchemaId()` 得到当前输入方案的 ID
- `RimeGetSchemaList()` 得到当前输入方案的 ID 和名字的对应关系。名字可以是中文，
  id 不行。此 API 的第一个参数不用是会话 ID 。
- `RimeDestroySession()` 销毁会话 ID 。

以上是比较传统的 API ，如果更偏爱 OOP 可以参考[官方示例](https://github.com/rime/librime/blob/master/tools/rime_api_console.cc)。

### 按键转换

`RimeProcessKey()` 输入的键码是每个按键转换而成的一个数字。与 ASCII 兼容。包括了更多的适用于非英语键盘的非英语符号和方向键等特殊按键。
掩码是控制键或的结果。比如 Control + Shift 就是 4 + 1 。键码和掩码从名字到数字的
转换关系没有任何公开的 API 暴露出来，需要自己从 `key_table.cc` 复制。顺带一提因
为 C 语言没有字典，所以这个代码用了一个奇怪的指针技巧，但其实看不懂不影响抄那个表格……

### 实践

![python](https://github.com/user-attachments/assets/ad3860ea-2ea5-436d-8b57-5d2ad1a605f5)

拿 Python 举例好了（毕竟会的人太多了）：

先用 C 语言写一个 python 模块把 librime 的 API 暴露出来。

```python
from pyrime import *
```

这方面网上的教程很多，笔者推荐从 [meson-python](https://meson-python.readthedocs.io/en/latest/tutorials/introduction.html) 开始。
熟悉 cmake 的朋友也可以试试 [scikit-build-core](https://scikit-build-core.readthedocs.io/) 。

如何绘制用户界面呢？目前 [python 的常见 REPL](https://github.com/wakatime/repl-python-wakatime) 通常使用 [python-prompt-toolkit](https://github.com/prompt-toolkit/python-prompt-toolkit/) ，例如 ipython, ptpython, ptipython 。翻阅手册得知 ptpython 的配置方法如下：

`~/.config/ptpython/config.py`:

```python
from prompt_toolkit.filters import EmacsInsertMode
from prompt_toolkit.key_binding.key_processor import KeyPressEvent
from ptpython.repl import PythonRepl

def configure(repl: PythonRepl) -> None:
    @repl.add_key_binding("c-^", filter=EmacsInsertMode)
    def _(event: KeyPressEvent) -> None:
        ...
```

我们创建一个快捷键可以打开一个浮动窗口：

```python
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.filters import Condition
from prompt_toolkit.key_binding.key_processor import KeyPressEvent
from prompt_toolkit.layout.containers import (
    Float,
    FloatContainer,
    Window,
)
from prompt_toolkit.layout.controls import BufferControl
from prompt_toolkit.layout.layout import Layout
from prompt_toolkit.widgets import Frame

def configure(repl: PythonRepl) -> None:
    @repl.add_key_binding("c-^", filter=EmacsInsertMode)
    def _(event: KeyPressEvent) -> None:
        window = Window(
            BufferControl(buffer=Buffer()),
            width=5,
            height=1,
        )
        window.content.buffer.text = "hello"
        repl.app.layout = Layout(
            FloatContainer(
                repl.app.layout.container,
                [
                    Float(
                        Frame(window),
                        left=8,
                        top=1,
                    )
                ],
            )
        )
```

我们按下 Ctrl + 6 ，在位置为 8, 1 的地方出现了一个宽度为 5 ，高度为 1 的窗口。

注：这个快捷键来源于 Vim 。

![hello](https://github.com/user-attachments/assets/78ad9600-6888-41aa-87fb-25a50cc0eeb1)

这是一个好的开始。我们可以做更多的事，比如：

- 自动计算光标的位置。示例代码是硬编码了窗口位置使其刚好出现在光标处。我们可以从 `repl.app.layout.current_buffer.text` 获取当前输入的文字和 `repl.app.layout.current_buffer.cursor_position` 获取光标所在的字符（一维坐标）。从而计算二维坐标的 left 和 top 。提示符的宽度也可以从 `repl.all_prompt_styles[repl.prompt_style].in_prompt()` 获得。
- 反转浮动窗口，我们每次覆盖 `repl.app.layout` 前保存当前的 `repl.app.layout` ，当再次按下同样的快捷键时，恢复原来的 `repl.app.layout` 。

以上都是非常容易实现的。但比较难的问题是：

如何捕获用户按键，并根据按键重新绘制 `window.content.buffer.text` 呢？

我们需要重定义所有按键以将按键传给 rime, 类似这样:

```python
for keys in keys_set:

    @repl.add_key_binding(*keys, filter=mode(keys))  # type: ignore
    def _(event: KeyPressEvent, keys: list[str] = keys) -> None:
        r""".

        :param event:
        :type event: KeyPressEvent
        :param keys:
        :type keys: list[str]
        :rtype: None
        """
        key_binding(event, keys)
```

`mode` 是我们定义个一个过滤器，只在 rime 模式被启用的时候返回 `True` 。这意味着他不会干扰未启用输入法的时候的快捷键。

`key_binding` 是一个函数，接受输入的按键名，将形如 `c-a` Control + A 这样的按键名转换为 0x61 的键码和 `2 ** 2` 的掩码。再传给 `RimeProcessKey()` 。
再根据前面提到的算法流程通过修改 `window.content.buffer.text` 绘制用户界面，通过修改 `event.cli.current_buffer.insert_text(text)` 插入输入法选中的文字。

一个小坑是文字的宽度绝不可以简单的使用 `len()` ，因为汉字和英文的宽度是不一样的。
需要使用 wcwidth 的 `wcswidth()` 。

代码可见 [pyrime](https://github.com/Freed-Wu/pyrime) 。

经过这一系列折腾我们就得到了一个 python 输入法！虽然在 python 中输入汉字的用户不多，可是它真的：

泰裤辣！
