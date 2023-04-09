---
title: 'Re: 从零开始的语言服务器开发冒险：代码补全 & 文档悬停'
tags:
  - develop
  - lsp
---

有感于大部分用编辑器写代码的用户都是伸手党（无贬义，毕竟大家各有所长，在某个不擅长的领域想伸也没手可伸不是），希望分享相关知识鼓励更多人参与编辑器相关软件、插件开发。

本文：

1. 只需要 python 基础。
2. 只涉及语言服务器，不涉及语言客户端（编辑器或者让编辑器支持 LSP 的插件）。即所有编辑器都适用。

让我们选择一种语言来演示如何实现代码补全和文档悬停的功能。它要：

1. 足够简单，简单到几乎没有语法
2. 如果该语言有很多与 python 相关的库会更有利于开发，毕竟我们假定读者只有 python 基础
3. 最好与 python 相关，这样大多数 python 用户都可能会这门语言

先暂停一下看点别的，之后再看看你想到的结果会是哪一种语言？

## 标准

### 基本协议

![OSI](https://i.stack.imgur.com/ysG0q.jpg)

![OSI usage](https://i.stack.imgur.com/WG5r8.jpg)

[语言服务器协议](https://microsoft.github.io/language-server-protocol/specifications/specification-current)与其姊妹版的[构建服务器协议](https://build-server-protocol.github.io/)和作为它们交集的
[基本协议](https://microsoft.github.io/language-server-protocol/specifications/base/0.9/specification/)
位于 OSI 模型的应用层。基于会话层的 [JSON-RPC](https://www.jsonrpc.org/) 协议。
再往下可以是 TCP 或 UDP 甚至标准输入输出（这已经不是网络通信了，服务器进程和客户端进程必须在同一台设备上了）进行通信。

基本协议定义了服务器和客户端如何通信。包括：

- 三次握手
- 报文的格式
- 将服务器能支持的功能 feature 集合成能力 capability 。

语言服务器协议解耦了只负责语言功能的语言服务器和只负责文本编辑的编辑器或文本预览的浏览器，使得不同代码编辑器在支持不同语言的编辑上可以高度复用语言服务器的代码。不用重新适配编辑器插件。
同样读者也可以猜到构建服务器协议的作用。

注意， LSP 只规定了语言服务器和语言客户端如何通信，并不规定语言服务器的具体实现。以代码补全这个 feature 为例，以下 3 种实现都是可以的。

- 正则表达式：把关键词存储在一个数组，根据用户光标下的输入匹配对应的关键词。适合没有解析器也没有复杂语法的简单语言，例如各种软件的配置语言，通常是领域特定语言 DSL
- 抽象语法树：用解析器生成抽象语法树，补全解析到的变量名、函数名。适合大多数通用编程语言 GPL
- NLP：根据前文内容用类似 [CodeGen](https://arxiv.org/abs/2203.13474) 之类的模型直接预测用户的输出。极其适合类似 markdown 之类的接近自然语言的轻量级标记语言。（笔者在 github issue 上回帖用 [firenvim](https://github.com/glacambre/firenvim) 做编辑器时，这种语言服务器能猜得很准）

### 调试适配器协议

经常被一并提及的[调试适配器协议](https://microsoft.github.io/debug-adapter-protocol/specification)（DAP）并不基于 JSON-RPC 协议。笔者没有深入使用过，感觉像是使用编辑器充当了调试器的界面，好处可能有用户不用重新记忆不同调试器的快捷键，但 cgdb 或 pudb 这种不支持 DAP 但内置了一门脚本语言（gdb script 或 python）的调试器比较似乎功能仍然不够强大。

### 语言服务器索引格式

另一个与之相关的协议是[语言服务器索引格式](https://microsoft.github.io/language-server-protocol/specifications/base/0.9/specification/) （LSIF）。之前提到语言客户端除了有文本编辑的编辑器外，还有负责文本预览的浏览器。例如，用户可以在 github 上浏览开源仓库的代码。与编辑器最大的区别是后者是只读的，也就是说可以把每次用户执行操作的结果保存下来作为索引。以节省用户重复进行操作的时间。比如用户查看了某个函数定义和引用，下次再执行同样的操作时相应速度就会更快——感觉微软就是在为 github 制定这个标准的呀（LSP 以及与 LSP 相关的协议现在是微软（VSCode ）、 IBM Redhat （Eclipse）几家在合作制定标准。尽管如此，我们仍可轻率地暴论微软一个人说了算）！

![github](https://github.com/Freed-Wu/Freed-Wu/assets/32936898/e8d9d832-703b-4ee8-9672-3d1491aec0e7)

顺带一提， LSIF 定义的相当有趣，格式是 json ，但“查询定义”这种动词放在了 `edge` 属性上，“查询结果”、“被查询的函数名”这些名词被放在了 `vertex` 属性上。真不知道微软的灵感来源是哪……

## 实操

我们选择 [`requirements.txt`](https://pip.pypa.io/en/stable/reference/requirements-file-format/#requirements-file-format) 。

这种语言最初被 pip 用来描述 python 的包依赖关系。后经过 [PEP 508](https://peps.python.org/pep-0508) 提案被标准化。不过 pip 支持的 `requirements.txt` 是 PEP 508 的超集。额外支持 pip 的部分命令行选项。我们来实现关于 PEP 508 的 `requirements.txt` 的一些 LSP feature （当然，看完这篇文章实现补全 pip 的命令行选项也不是什么难题）：

- 代码补全：补全 PYPI 的包名。如果该包在本地已经安装，额外显示该包的相关信息。
- 文档悬停：显示光标下包的相关信息，如果该包在本地已经安装。

如果不加上本地已经安装的限制的话：

- 包的数量就会大量增加，拖慢速度
- 而且非本地安装的包得访问互联网
- 用户编写 `requirements.txt` 时其中的大量包应该在本地已经安装，所以加上限制不是什么大问题。 `:)`

将使用以下库：

- [lsprotocol](https://github.com/microsoft/lsprotocol): 由微软提供 ，定义了符合 LSP 的各种类型。
- [pygls](https://github.com/openlawlibrary/pygls): 由[开放法律平台](https://openlawlib.org/) （没看明白这是一家什么组织） 提供，用于实现他们自己的语言服务器的一个封装。你不需要自己应付异步通信、 JSON-RPC 协议、套接字之类的东西。

首先实现一个用标准输入输出通信的语言服务器。出于演示的目的，某些代码并不规范，例如：

- 正常这个代码应该拆分为若干个不同的文件
- 尽可能避免 `from XXX import *` 。
- 缺少文档字符串和必要的注释

```python
from typing import Any

from lsprotocol.types import *
from pygls.server import LanguageServer


class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)


if __name__ == "__main__":
    RequirementsLanguageServer(NAME, __version__).start_io()
```

### 代码补全

尝试补全 `torch` 和 `torchvision` 。关于如何配置编辑器使用语言服务器参见 [语言客户端](https://freed-wu.github.io/2023/07/01/language-server.html#%E8%AF%AD%E8%A8%80%E5%AE%A2%E6%88%B7%E7%AB%AF)

```python
class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...

        @self.feature(TEXT_DOCUMENT_COMPLETION)
        def completions(params: CompletionParams) -> CompletionList:
            return CompletionList(
                False,
                [
                    CompletionItem(
                        k,
                        kind=CompletionItemKind.Module,
                        insert_text=k,
                        documentation=MarkupContent(
                            MarkupKind.Markdown, "An example"
                        ),
                    for k in ["torch", "torchvision"]
                ],
            )
```

这种无论用户输入什么都补全 `torch` 和 `torchvision` 的补全毫无意义。我们尝试获得当前光标下的单词：

```python
import re


class RequirementsLanguageServer(LanguageServer):
    # ...
    def _cursor_line(self, uri: str, position: Position) -> str:
        document = self.workspace.get_document(uri)
        return document.source.splitlines()[position.line]

    def _cursor_word(
        self,
        uri: str,
        position: Position,
        include_all: bool = True,
        regex: str = r"\w+",
    ) -> tuple[str, Range]:
        line = self._cursor_line(uri, position)
        for m in re.finditer(regex, line):
            if m.start() <= position.character <= m.end():
                end = m.end() if include_all else position.character
                return (
                    line[m.start() : end],
                    Range(
                        Position(position.line, m.start()),
                        Position(position.line, end),
                    ),
                )
        return (
            "",
            Range(Position(position.line, 0), Position(position.line, 0)),
        )
```

接下来可以只在用户输入 `t`, `to`, `tor`, ... 时补全 `torch`, `torchvision` ：

```python
class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...

        @self.feature(TEXT_DOCUMENT_COMPLETION)
        def completions(params: CompletionParams) -> CompletionList:
            word, _ = self._cursor_word(
                params.text_document.uri, params.position, False
            )
            return CompletionList(
                False,
                [
                    CompletionItem(
                        k,
                        kind=CompletionItemKind.Module,
                        insert_text=k,
                        documentation=MarkupContent(
                            MarkupKind.Markdown, "An example"
                        ),
                    for k in ["torch", "torchvision"]
                    if x.startswith(word)
                ],
            )
```

![hello world](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/2c90e2bc-b7fa-45e6-a45f-3d2051b4c0cb)

考虑如何根据 `word` 获得所有以 `word` 开头的包名。由于一开始要求的第 2 条，我们可以额外获得一些库：

- [pip-cache](https://github.com/brunobeltran/pip-cache): 缓存 PYPI 的包名。虽然自己实现也不难，但既然搜到了这个包就省点事叭
- [pip](https://github.com/pypa/pip): 检索本地的包信息

用 `pip-cache update` 等个 10 秒缓存一下包名先。然后我们就可以获得包名了：

```python
from pip_cache import get_package_names

class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...

        @self.feature(TEXT_DOCUMENT_COMPLETION)
        def completions(params: CompletionParams) -> CompletionList:
            word, _ = self._cursor_word(
                params.text_document.uri, params.position, False
            )
            return CompletionList(
                False,
                [
                    CompletionItem(
                        k,
                        kind=CompletionItemKind.Module,
                        insert_text=k,
                        documentation=MarkupContent(
                            MarkupKind.Markdown, "An example"
                        ),
                    for k in get_package_names(word)
                ],
            )
```

![no document](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/1c3df1ca-ba2c-43e3-9a68-e57090a69f2f)

嗯， `import` 是真的爽。

接着，如何获得包的信息？用 `pudb` 调试一下 `pip show` 和 `pip list`:

```sh
pudb -m pip show
pudb -m pip list
```

很快发现 2 个内部应用编程接口：

```python
from pip._internal.commands.show import _PackageInfo, search_packages_info
from pip._internal.metadata import get_environment
```

前者很慢，但返回的 `_PackageInfo` 能比后者多返回一些把包上传到 PYPI 上需要的元信息中所没有的信息，比如你的电脑里有多少包是某个包的反向依赖。

```python
ENV = get_environment(None)

def search_package_names(name: str, search: bool = True) -> dict[str, str]:
    package_names = {
        pkgname: "Not found installed package!" for pkgname in (get_package_names(name) if search else [name])
    }
    count = len(package_names)
    for pkg in ENV.iter_installed_distributions():
        if count == 0:
            break
        if name not in package_names:
            continue
        package_names[pkg.canonical_name] = render_document(
            pkg.metadata_dict
        )
        count -= 1
    return package_names

def render_document(metadata: dict[str, Any]) -> str:
    # ...
    return f"""
{metadata["summary"]}

...
"""

class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...

        @self.feature(TEXT_DOCUMENT_COMPLETION)
        def completions(params: CompletionParams) -> CompletionList:
            word, _ = self._cursor_word(
                params.text_document.uri, params.position, False
            )
            return CompletionList(
                False,
                [
                    CompletionItem(
                        k,
                        kind=CompletionItemKind.Module,
                        insert_text=k,
                        documentation=MarkupContent(
                            MarkupKind.Markdown, doc
                        ),
                    for k, doc in search_package_names(word)
                ],
            )
```

![completion](https://github.com/Freed-Wu/requirements-language-server/assets/32936898/0f1f9e31-3933-4f56-9cf9-5db6e044caca)

### 文档悬停

文档悬停因为也很简单一并实现了叭：

```python
class RequirementsLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        # ...

        @self.feature(TEXT_DOCUMENT_HOVER)
        def hover(params: TextDocumentPositionParams) -> Hover | None:
            word, _range = self._cursor_word(
                params.text_document.uri, params.position, True
            )
            return Hover(
                MarkupContent(
                    MarkupKind.Markdown,
                    search_package_names(word, False)[word],
                ),
                _range(),
            )
```

![hover](https://github.com/Freed-Wu/requirements-language-server/assets/32936898/03237cb6-72ce-4d2f-a879-db18d595fa39)

本文代码开源于 [requirements-language-server](https://github.com/Freed-Wu/requirements-language-server/) 。

### 反思

观察本文实现的代码，我们注意到以下致命的问题：

- 补全结果只与光标下的单词有关，完全不区分光标位置。即哪怕是在注释中也照样补全

![comment](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/d0ae5096-0e40-4250-a0fe-f63a914b912b)

为了解决这个问题，我们需要引入抽象语法树。而这些内容，请待下回分解。

![to be continued](https://toppng.com/uploads/preview/to-be-continued-arrow-transparent-jojos-bizarre-adventure-number-11562852505wgeuacdi2p.png)
