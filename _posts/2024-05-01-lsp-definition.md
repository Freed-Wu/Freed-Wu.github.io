---
title: 'Re: 从零开始的语言服务器开发冒险：定义跳转 & 引用跳转'
tags:
  - develop
  - lsp
---

> Hello, I'm trying to use this in emacs, but I'm getting an error saying that the server does not support the method textDocument/definition. I feel like this is the main feature needed by a language server for XXX, to avoid constantly needing to use ag/grep to find package definitions.
>
> -- [使用我写的语言服务器的某网友](https://github.com/Freed-Wu/bitbake-language-server/issues/3)

系列文章第三篇。今天展示如何实现一个语言服务器在 `Makefile` 中实现定义跳转和引用跳转的功能。本文代码开源于 [autotools-language-server](https://github.com/Freed-Wu/autotools-language-server) 。

## 术语

**跳转**指根据光标下的 token 信息移动光标到另一个位置。 LSP 定义了以下 5 类可跳转的 feature ：

- 定义
- 声明
- 类型声明
- 实现
- 引用

但 LSP 的标准文档根本就没定义什么是定义，声明什么是声明。 `:(`
而且如果我们将定义、声明等划分得太细，比如将以下设定为两种不同的跳转：

```c
typedef int number_t
```

```c
#define number_t int
```

指望用户在按快捷键之前预判 `number_t` 需要哪一种跳转再决定按哪个快捷键好像也不太符合正常逻辑，是也不是？

所以笔者观察到的经验法则是：大多数语言服务器都只实现了定义跳转, 引用跳转可看成其逆操作，即如果先定义跳转，再引用跳转就会回到原先定义所在的位置。

某些情况下声明跳转也会被实现。例如：

`main.py`:

```python
def foo(x):
    return x
```

`main.pyi`: （`...` 不是省略，就是正确的语法）

```python
def foo(x: int) -> int:
    ...
```

[pyright](https://github.com/microsoft/pyright) 定义跳转会跳转到 `main.py` 的 `def foo(x)` ，声明跳转会跳转到 `main.pyi` 的 `def foo(x: int)` 。
但 python 3.6+ 已经支持在 `main.py` 中：

```python
def foo(x: int) -> int:
    return x
```

所以也只有少部分应用极其广泛到必须兼容低版本 python 的开源项目才会额外有*声明*。正常浏览代码大可不必弄清各种跳转。

如果读者翻过 LSP 的标准文档，就会发现所有的跳转用的都是复数。为什么是复数？就算某些语言支持重复定义函数，也只有最后一次定义不会被覆盖，即真正的定义，是有意义的，为何不直接设定为跳转到最后一次定义（单数）呢？

考虑以下特例：

```python
import random

if random.randrange(2) == 1:

    def foo(x: int) -> int:
        return x

else:

    def foo(x: int) -> int:
        return 1


foo(1)
```

又有哪个拉普拉斯的魔女能预测出真正的定义是哪一个呢？所以当可能的跳转结果不止一个时，语言客户端会弹出一个选择框允许用户预览和选择最终的跳转位置。

![list](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/50cafbd5-3a2c-4f93-a07c-eb84088ae9ca)

## 实现

我们需要在抽象语法树中实现一个搜索算法，搜索到定义、引用所在的节点。

### 抽象语法树

抽象语法树的解析器，我们将选用 [py-tree-sitter-languages](https://github.com/grantjenks/py-tree-sitter-languages) 封装好的现成的解析器：

```python
from lsprotocol.types import *
from pygls.server import LanguageServer
from tree_sitter_languages import get_parser


class MakeLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.parser = get_parser("make")
```

只有当文件发生变化时，我们才重新生成抽象语法树：

```python
class MakeLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.trees = {}
        self.parser = get_parser("make")

        @self.feature(TEXT_DOCUMENT_DID_OPEN)
        @self.feature(TEXT_DOCUMENT_DID_CHANGE)
        def did_change(params: DidChangeTextDocumentParams) -> None:
            document = self.workspace.get_document(params.text_document.uri)
            self.trees[document.uri] = self.parser.parse(document.source.encode())
```

### 搜索

在节点搜索方面， [tree-sitter](https://github.com/tree-sitter/tree-sitter) 提供了一种内置的 DSL [tree-sitter-query](https://tree-sitter.github.io/tree-sitter/using-parsers#query-syntax) ，在上一篇文章中我们已经展示过如何使用 tree-sitter-query 来搜索所有错误的节点了。虽然内置的 DSL 好处多多，但我们注意到：

1. tree-sitter-query 只能搜索当前抽象语法树的所有节点。但当我们明确知道搜索结果至多只有一个时，一旦搜到就可以立即返回节省时间。
2. tree-sitter-query 没有办法递归搜索其他文件的抽象语法树。在本例中，如果 `Makefile` 中有 `include XXX.mk` ，我们需要解析 `XXX.mk` 中是否有我们的搜索目标。

所以我们需要自己实现一个更加灵活的搜索函数。它的搜索返回结果不仅仅是 tree-sitter-query 返回的节点，而是一个文件 URI 和该文件解析后的抽象语法树上的某个节点，我们不妨称其为 UNI （统一节点定位符）叭。

```python
from dataclasses import dataclass

from tree_sitter import Node


@dataclass
class UNI:
    uri: str
    node: Node
```

注意到 `Makefile` 的函数调用是在规则内的，所以函数定义的位置和调用函数的规则的位置可以颠倒先后顺序，例如：

`Makefile`:

<!-- markdownlint-disable MD010 -->

```make
.PHONY: all
all:
	$(call f,hello)

define f
	@echo $(1)
endef
```

<!-- markdownlint-enable MD010 -->

```sh
$ make all
hello
```

关于什么深度优先、广度优先就不必浪费大家时间去介绍了。这里贴出一个示范的伪代码：

01. 初始化一个列表存储搜索到的 UNI 。
02. 输入一个 `Makefile` 的 URI: `file:///the/path/of/Makefile`
03. 解析该文件得到抽象语法树，将根节点设置为起始节点
04. 如果当前节点是 `include XXX.mk` 且搜索层数没有超过最大搜索层数，则搜索层数加 1，确定新的 URI： `file:///the/path/of/XXX.mk` ，回到第 2 步
05. 如果当前节点符合**搜索条件**，则将其 UNI 加入到第 1 步的列表中。
06. 如果明确得知搜索结果至多只有一个，返回第 1 步的列表
07. 如果当前节点有子节点，移动到当前节点的第一个子节点。回到第 4 步
08. 否则如果当前节点有下一个兄弟节点，移动到当前节点的下一个兄弟节点。回到第 4 步
09. 如果当前节点没有父节点，返回第 1 步的列表，搜索层数减 1
10. 移动到父节点，回到第 8 步

我们把所有搜索函数都封装成一个 `Finder` 类以复用一部分代码。

```python
# maximum of recursive search
LEVEL = 5


@dataclass
class Finder:
    def __call__(self, uni: UNI) -> bool:
        r"""Search condition."""
        return True

    def is_include_node(self, node: Node) -> bool:
        return False

    def reset(self) -> None:
        self.level = 0
        self.unis = []

    def find(
        self, uri: str, tree: Tree | None = None, reset: bool = True
    ) -> UNI | None:
        # ...

    def find_all(
        self, uri: str, tree: Tree | None = None, reset: bool = True
    ) -> list[UNI]:
        # ...
```

本部分代码开源于 [tree-sitter-lsp](https://github.com/Freed-Wu/tree-sitter-lsp) 。

### 定义跳转

想要实现定义跳转，我们需要 2 次搜索：

1. `PositionFinder`: 搜索光标下的位置对应的节点
2. `DefinitionFinder`: 如果该节点是函数名，则搜索该函数的定义

`PositionFinder` 的**搜索条件**是光标的位置和位于节点的起始位置和终止位置之间：

```python
@dataclass(init=False)
class PositionFinder(Finder):
    def __init__(
        self,
        position: Position,
        left_equal: bool = True,
        right_equal: bool = False,
    ) -> None:
        super().__init__()
        self.position = position
        self.left_equal = left_equal
        self.right_equal = right_equal

    @staticmethod
    def belong(
        position: Position,
        node: Node,
        left_equal: bool = True,
        right_equal: bool = False,
    ) -> bool:
        if left_equal:
            left_flag = Position(*node.start_point) <= position
        else:
            left_flag = Position(*node.start_point) < position
        if right_equal:
            right_flag = position <= Position(*node.end_point)
        else:
            right_flag = position < Position(*node.end_point)
        return left_flag and right_flag

    def __call__(self, uni: UNI) -> bool:
        node = uni.node
        return node.child_count == 0 and self.belong(
            self.position, node, self.left_equal, self.right_equal
        )
```

检查抽象语法树我们发现函数定义的节点类型是 `define_directive` 。`$(call f,hello)` 中的函数名所在的节点是 `f,hello` ，不是 更小的 `f` 。这是上游的 [bug](https://github.com/alemuller/tree-sitter-make/issues/8#issuecomment-1770869682) 。笔者在这里简单用 `.split(",")[0]` 来获取函数名 `f` 。

```python
@dataclass(init=False)
class DefinitionFinder(Finder):
    def __init__(self, node: Node) -> None:
        super().__init__()
        parent = node.parent
        if parent is None:
            return
        if parent.type == "arguments":
            # https://github.com/alemuller/tree-sitter-make/issues/8
            self.name = node.text.decode().split(",")[0]

    def is_include_node(self, node: Node) -> bool:
        r"""``include a.mk b.mk``"""
        if parent := node.parent:
            if pp := parent.parent:
                return (
                    node.type == "word"
                    and parent.type == "list"
                    and pp.children[0].text == b"include"
                )
        return False

    def __call__(self, uni: UNI) -> bool:
        node = uni.node
        if parent := node.parent:
            return (
                parent.type == "define_directive"
                and uni.get_text() == self.name
                and node == parent.children[1]
            )
        return False
```

因为 `Finder().find_all()` 返回的结果是 `list[UNI]` ，而定义跳转返回的结果类型是 `list[Location]` ，所以我们在 `UNI` 封装一个 `get_location()`:

```python
@dataclass
class UNI:
    # ...
    def get_location(self) -> Location:
        return Location(self.uri, self.get_range())

    def get_range(self) -> Range:
        return self.node2range(self.node)

    @staticmethod
    def node2range(node: Node) -> Range:
        return Range(Position(*node.start_point), Position(*node.end_point))
```

最终我们得到了：

```python
from tree_sitter_lsp.finders import PositionFinder


class MakeLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...
        @self.feature(TEXT_DOCUMENT_DEFINITION)
        def definition(params: TextDocumentPositionParams) -> list[Location]:
            document = self.workspace.get_document(params.text_document.uri)
            if uni := PositionFinder(params.position).find(
                document.uri, self.trees[document.uri]
            ):
                return [
                    uni.get_location()
                    for uni in DefinitionFinder(uni.node).find_all(
                        document.uri, self.trees[document.uri]
                    )
                ]
            return []
```

现在当我们按下定义跳转的快捷键时，会从 `$(call f,hello)` 的 `f` 跳转到 `define f` 的 `f` 了。

除了函数的定义跳转，我们还需要：

- 变量的跳转，例如 `KERNEL_SRC`:

```make
KERNEL_SRC := /usr/src/linux
KERNEL_MAKE := $(MAKE) -C$(KERNEL_SRC) M=$(SRC)
```

- 规则的跳转，例如 `all`:

<!-- markdownlint-disable MD010 -->

```make
.PHONY: all
all:
	$(call f,hello)
```

<!-- markdownlint-enable MD010 -->

另外我们可以把定义的内容和系列文章二提及的文档悬停结合起来：

![hover](https://github.com/Freed-Wu/autotools-language-server/assets/32936898/f19d240e-7ad3-4ed9-b7fa-03cee410300d)

这些实现留待读者思考。

### 引用跳转

定义跳转的逆操作就是引用跳转。实现不能说一模一样，只能说丝毫不差：

```python
class MakeLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...
        @self.feature(TEXT_DOCUMENT_REFERENCES)
        def references(params: TextDocumentPositionParams) -> list[Location]:
            document = self.workspace.get_document(params.text_document.uri)
            if uni = PositionFinder(params.position).find(
                document.uri, self.trees[document.uri]
            ):
                return [
                    uni.get_location()
                    for uni in ReferenceFinder(uni.node).find_all(
                        document.uri, self.trees[document.uri]
                    )
                ]
            return []
```

`ReferenceFinder` 的实现留给读者自己思考。

还有最后一更。先前所有埋下的伏笔和陷阱都会被揭晓。
