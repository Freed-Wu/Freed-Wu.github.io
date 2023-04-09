---
title: 'Re: 从零开始的语言服务器开发冒险：代码诊断 & 代码补全 & 文档悬停 again'
tags:
  - develop
  - lsp
---

在之前的文章中我们留下了一个伏笔：

> 接下来我们将引入新的技术

现在回收此伏笔。

友情提醒：本文给出的技术会给 ArchLinux 和 Windows Msys2 用户带来一点小小的震撼。

## 验证模式

JSON, YAML, TOML, DOS ini, XML 等都是流行的数据交换格式，或者叫数据描述语言。大多数软件使用这些通用的数据描述语言来描述信息，例如日志、配置等等。配置文件需要用编辑器修改，由语言服务器提供代码补全、代码诊断等功能。语言服务器不光提供通用的功能：检查某 JSON 格式的配置文件是否是合法的 JSON ，更要提供专用的功能：检查配置文件是否是符合该软件配置要求的合法的 JSON 。所以需要：

- 抽象出一种数据格式用来存储该软件的配置要求，即验证模式
- 再用一个软件根据验证模式验证配置文件是否符合某软件配置要求，即验证器

因为 JSON, YAML 等格式可以相互转换，所以验证模式其实是不限于某一种数据描述语言。但验证器必须和验证模式保持对应关系，不同验证器和不同验证模式不能混用。

常见的验证模式有：

- [json schema](https://json-schema.org/): 最初是为 JSON 设计
- [Document Type Definition](https://en.wikipedia.org/wiki/Document_type_definition): 为 XML 设计
- [XML Schema Definition](<https://en.wikipedia.org/wiki/XML_Schema_(W3C)>): 为 XML 设计，似乎不如 DTD 流行

本文接下来使用的方式是基于 json schema 的，如果想看基于 XML 的方案的话， [asm-lsp](https://github.com/bergercookie/asm-lsp) 会是个不错的选择。

## 包构建脚本

ArchLinux 和 Windows Msys2 用户应该对下面这个流程毫不陌生：

`PKGBUILD`:

```bash
pkgname=hello
pkgver=0.0.1
pkgrel=1
pkgdesc="hello"
arch=(any)
license=(GPL3)

build() {
    cat <<EOF > hello
#!/usr/bin/env sh
echo hello
EOF
}

package() {
    install -D hello -t $pkgdir/usr/bin
}
```

```sh
$ makepkg
==> Making package: hello 0.0.1-1 (Wed 20 Dec 2023 08:14:08 PM CST)
==> Checking runtime dependencies...
==> Checking buildtime dependencies...
==> Retrieving sources...
==> Extracting sources...
==> Starting build()...
==> Entering fakeroot environment...
==> Starting package()...
==> Tidying install...
-> Removing libtool files...
-> Purging unwanted files...
-> Removing static library files...
-> Stripping unneeded symbols from binaries and libraries...
-> Compressing man and info pages...
==> Checking for packaging issues...
==> Creating package "hello"...
-> Generating .PKGINFO file...
-> Generating .BUILDINFO file...
-> Generating .MTREE file...
-> Compressing package...
==> Leaving fakeroot environment.
==> Finished making: hello 0.0.1-1 (Wed 20 Dec 2023 08:14:09 PM CST)
$ tar vtaf hello-0.0.1-1-any.pkg.tar.zst
-rw-r--r-- root/root     98536 2023-12-20 20:14 .BUILDINFO
-rw-r--r-- root/root       357 2023-12-20 20:14 .MTREE
-rw-r--r-- root/root       233 2023-12-20 20:14 .PKGINFO
drwxr-xr-x root/root         0 2023-12-20 20:14 usr/
drwxr-xr-x root/root         0 2023-12-20 20:14 usr/bin/
-rwxr-xr-x root/root        29 2023-12-20 20:14 usr/bin/hello
$ sudo pacman -U hello-0.0.1-1-any.pkg.tar.zst
loading packages...
resolving dependencies...
looking for conflicting packages...

Packages (1) hello-0.0.1-1

Total Installed Size:  0.00 MiB

:: Proceed with installation? [Y/n]
(1/1) checking keys in keyring                                                                     [##########################################################] 100%
(1/1) checking package integrity                                                                   [##########################################################] 100%
(1/1) loading package files                                                                        [##########################################################] 100%
(1/1) checking for file conflicts                                                                  [##########################################################] 100%
(1/1) checking available disk space                                                                [##########################################################] 100%
:: Processing package changes...
(1/1) installing hello                                                                             [##########################################################] 100%
:: Running post-transaction hooks...
(1/1) Arming ConditionNeedsUpdate...
$ hello
hello
```

我们来实现一个语言服务器对 [PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD) 进行代码诊断、代码补全和文档悬停。

`PKGBUILD` 有很多地方是需要诊断和补全的，例如：

- `arch` 必须是包含 `any`, `i686`, `x86_64`, `arm` 等架构名的数组，不能有用户自己随便编的架构，需要补全合法的架构名
- `license` 必须是包含合法许可证名 (MIT, BSD, ...) 的数组，需要补全合法的许可证名
- `build`, `package` 必须是函数，不能是字符串和数组

## 实现

本文代码开源于 [termux-language-server](https://github.com/termux/termux-language-server) 。

### 抽象语法树

抽象语法树的解析器，我们将选用 [py-tree-sitter-languages](https://github.com/grantjenks/py-tree-sitter-languages) 封装好的现成的解析器：

```python
from lsprotocol.types import *
from pygls.server import LanguageServer
from tree_sitter_languages import get_parser


class BashLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.parser = get_parser("bash")
```

只有当文件发生变化时，我们才重新生成抽象语法树：

```python
class BashLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.trees = {}
        self.parser = get_parser("bash")

        @self.feature(TEXT_DOCUMENT_DID_OPEN)
        @self.feature(TEXT_DOCUMENT_DID_CHANGE)
        def did_change(params: DidChangeTextDocumentParams) -> None:
            document = self.workspace.get_document(params.text_document.uri)
            self.trees[document.uri] = self.parser.parse(
                document.source.encode()
            )
```

### JSON schema

我们需要将 `PKGBUILD` 转换为合法的可 JSON 序列化的字典。注意到 `bash` 中只有 4 种类型：

- 字符串
- 数组
- 关联数组，即字典
- 函数

所以我们人为把函数视为整数 0 ，上节的 `PKGBUILD` 即可序列化为：

```json
{
  "pkgname": "hello",
  "pkgver": "0.0.1",
  "pkgrel": "1",
  "pkgdesc": "hello",
  "arch": [
    "any"
  ],
  "license": [
    "GPL3"
  ],
  "build": 0,
  "package": 0
}
```

我们遵循 `PKGBUILD` 的 `man` 手册来编写 JSON schema 文件。例如如果手册上描述了：

- `pkgname` 是一个字符串，
- `arch` 是一个数组，元素仅可为 `arch`, `i686`, `x86_64`
- `build` 是一个函数

那么我们需要编写的 JSON schema 如下：

```json
{
  "$id": "PKGBUILD.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$comment": "Written by wzy",
  "type": "object",
  "properties": {
    "pkgname": {
      "description": "Either the name of the package or an array of names for split packages. Valid characters for members of this array are alphanumerics, and any of the following characters: \"@ . \\_ + -\". Additionally, names are not allowed to start with hyphens or dots.",
      "type": "string"
    },
    "arch": {
      "description": "Defines on which architectures the given package is available (e.g., arch=(i686 x86_64)). Packages that contain no architecture specific files should use arch=(any). Valid characters for members of this array are alphanumerics and \"\\_\".",
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "any",
          "i686",
          "x86_64"
        ]
      },
      "uniqueItems": true
    },
    "build": {
      "description": "The optional build() function is used to compile and/or adjust the source files in preparation to be installed by the package() function.",
      "const": 0
    }
  }
}
```

完整的 JSON schema 见[这里](https://github.com/termux/termux-language-server/tree/main/src/termux_language_server/assets/json)。

### 验证器

我们使用的 json schema 验证器是 [python-jsonschema](https://python-jsonschema.readthedocs.io/) 。因为该验证器是纯 python 实现，可以更好地被 python 编写的语言服务器调用。

### 序列化

我们需要实现序列化 `PKGBUILD` 的代码。方法还是从抽象语法树出发生成一个树。我们在该树中保留节点和范围的对应关系。当把序列化后的字典传递给验证器后，验证器会返回错误的消息和错误的节点路径，比如 `$.arch[0]` 就是 `arch` 数组的第一个元素。

```python
from dataclasses import dataclass

@dataclass
class Trie:
    range: Range
    parent: "Trie | None" = None
    # can be serialized to a json
    value: dict[str, "Trie"] | list["Trie"] | str | int | float | None = None

    def get_root(self) -> "Trie":
        node = self
        while node.parent is not None:
            node = node.parent
        return node

    def from_path(self, path: str) -> "Trie":
        r"""Get node from a json path like ``$.arch[0]``."""
        node = self
        if path.startswith("$"):
            path = path.lstrip("$")
            node = self.get_root()
        return node.from_relative_path(path)

    def from_relative_path(self, path: str) -> "Trie":
        r"""Get node from a json path like ``.arch[0]``."""
        if path == "":
            return self
        if path.startswith("."):
            if not isinstance(self.value, dict):
                raise TypeError
            path = path.lstrip(".")
            index, mid, path = path.partition(".")
            if mid == ".":
                path = mid + path
            index, mid, suffix = index.partition("[")
            if mid == "[":
                path = mid + suffix + path
            return self.value[index].from_relative_path(path)
        if path.startswith("["):
            if not isinstance(self.value, list):
                raise TypeError
            path = path.lstrip("[")
            index, _, path = path.partition("]")
            return self.value[int(index)].from_relative_path(path)
        raise TypeError

    def to_path(self) -> str:
        r"""Generate json path like ``$.arch[0]``."""
        if self.parent is None:
            return "$"
        path = self.parent.to_path()
        if isinstance(self.parent.value, dict):
            for k, v in self.parent.value.items():
                if v is self:
                    return f"{path}.{k}"
            raise TypeError
        if isinstance(self.parent.value, list):
            for k, v in enumerate(self.parent.value):
                if v is self:
                    return f"{path}[{k}]"
            raise TypeError
        return path

    def to_json(self) -> dict[str, Any] | list[Any] | str | int | float | None:
        r"""Generate json dict."""
        if isinstance(self.value, dict):
            return {k: v.to_json() for k, v in self.value.items()}
        if isinstance(self.value, list):
            return [v.to_json() for v in self.value]
        return self.value

    @classmethod
    def from_tree(cls, tree: Tree) -> "Trie":
        return cls.from_node(tree.root_node, None)

    @classmethod
    def from_node(cls, node: Node, parent: "Trie | None") -> "Trie":
        # ...
```

`from_node` 的一个伪代码如下：

1. 输入根节点
2. 遍历子节点
3. 若子节点是函数定义，增加一个对应属性，值为 0 ，范围为函数体的范围
4. 若子节点是值为字符串的变量，增加一个对应属性，值为该字符串，范围为该字符串的范围
5. 若子节点是值为数组或字典，增加一个对应属性，值为空数组或空字典，范围为数组或字典的范围，再返回第 1 步

一个更复杂的序列化参见 [zathura-language-server](https://github.com/Freed-Wu/zathura-language-server) ，这是系列文章二的实现，因为它远比本文提到的序列化算法更复杂所以没有拿它举例：

```conf
include desktop/zathurarc
map [fullscreen] <Esc> zoom in#with argument
map <F1> recolor          #without argument
set recolor true
set notification-error-bg       "#fbf1c7" # bg
unmap <F1>
```

```json
{
  "include": [
    "desktop/zathurarc"
  ],
  "map": {
    "fullscreen": [
      {
        "key": "<Esc>",
        "function": "zoom",
        "argument": "in"
      }
    ],
    "normal": [
      {
        "key": "<F1>",
        "function": "recolor"
      }
    ]
  },
  "set": {
    "recolor": true,
    "notification-error-bg": "#fbf1c7"
  },
  "unmap": {
    "normal": [
      "<F1>"
    ]
  }
}
```

### 搜索

和之前的文章一样，我们封装一个 `Finder` 。事实上，无论是

- 基于 tree-sitter-query 的搜索
- 基于我们在系列文章三中用 python 实现的深度优先搜索
- 还是 `python-jsonschema` 内部实现的搜索

我们都把它封装成一个 `Finder` ，提供用于代码诊断、代码格式化等 LSP feature 的接口。

```python
@dataclass(init=False)
class SchemaFinder(Finder):
    def __init__(self, schema: dict[str, Any], cls: type[Trie]) -> None:
        self.validator = self.schema2validator(schema)
        self.cls = cls

    @staticmethod
    def schema2validator(schema: dict[str, Any]) -> Validator:
        return validator_for(schema)(schema)

    def get_diagnostics(self, _: str, tree: Tree) -> list[Diagnostic]:
        trie = self.cls.from_tree(tree)
        return [
            Diagnostic(
                trie.from_path(error.json_path).range,
                error.message,
                DiagnosticSeverity.Error,
            )
            for error in self.validator.iter_errors(trie.to_json())
        ]
```

### 代码诊断

其中 `schema` 是 json schema 被读入到 python 后得到的 python 字典。

```python
class BashLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        @self.feature(TEXT_DOCUMENT_DID_OPEN)
        @self.feature(TEXT_DOCUMENT_DID_CHANGE)
        def did_change(params: DidChangeTextDocumentParams) -> None:
            document = self.workspace.get_document(params.text_document.uri)
            self.trees[document.uri] = self.parser.parse(
                document.source.encode()
            )
            diagnostics = SchemaFinder(schema, Trie).get_diagnostics(
                "", self.trees[document.uri]
            )
            self.publish_diagnostics(params.text_document.uri, diagnostics)
```

![diagnostic](https://github.com/termux/termux-language-server/assets/32936898/efcc4bfa-7dc5-4c0c-b90a-88dd0dbba1e3)

系列文章二结尾的解决方案亦是如此。

### 代码补全

补全来自 json schema 中的 `enum` 属性。

```python
class BashLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        @self.feature(TEXT_DOCUMENT_COMPLETION)
        def completions(params: CompletionParams) -> CompletionList:
            document = self.workspace.get_document(params.text_document.uri)
            uni = PositionFinder(params.position, right_equal=True).find(
                document.uri, self.trees[document.uri]
            )
            if uni is None:
                return CompletionList(False, [])
            parent = uni.node.parent
            if parent is None:
                return CompletionList(False, [])
            text = uni.get_text()
            if parent.type == "array" and parent.parent is not None:
                property = schema["properties"].get(
                    parent.parent.children[0].text.decode(), {}
                )
                return get_completion_list_by_enum(text, property)


def get_completion_list_by_enum(
    text: str, property: dict[str, Any]
) -> CompletionList:
    # if contains .items, it is an array
    property = property.get("items", property)
    enum = property.get(
        "enum",
        property.get(
            "oneOf", property.get("anyOf", property.get("allOf", [{}]))
        )[0].get("enum", []),
    )
    items = []
    for k in enum:
        if k is None:
            continue
        if not isinstance(k, str):
            k = str(k)
        if k.startswith(text):
            items += [
                CompletionItem(
                    k,
                    kind=CompletionItemKind.Constant,
                    insert_text=k,
                )
            ]
    return CompletionList(False, items)
```

![completion](https://github.com/termux/termux-language-server/assets/32936898/17224e8f-5cdc-4b82-98a9-3eb9fda34a4b)

### 文档悬停

文档来自 json schema 中的 `description` 属性。

```python
class BashLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        @self.feature(TEXT_DOCUMENT_HOVER)
        def hover(params: TextDocumentPositionParams) -> Hover | None:
            document = self.workspace.get_document(params.text_document.uri)
            uni = PositionFinder(params.position).find(
                document.uri, self.trees[document.uri]
            )
            if uni is None:
                return None
            text = uni.get_text()
            _range = uni.get_range()
            if description := (
                get_schema(filetype)
                .get("properties", {})
                .get(text, {})
                .get("description")
            ):
                return Hover(
                    MarkupContent(MarkupKind.Markdown, description),
                    _range,
                )
```

![hover](https://github.com/termux/termux-language-server/assets/32936898/dd00c8d2-d416-4f7d-ae2d-82d58e4c603d)

### 总结

可以看到在引入验证模式后我们成功用更简洁的方式实现了以下三大 LSP features:

- 代码诊断
- 代码补全
- 文档悬停

鉴于在笔者之前没有人尝试过在数据描述语言之外的 DSL 中引入验证模式，这绝对是一个创新 :smile:

还有一篇碎碎念，因为字数不少就单独放一篇文章了。
