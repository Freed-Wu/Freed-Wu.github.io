---
title: 'Re: 从零开始的语言服务器开发冒险：代码诊断'
tags:
  - develop
  - lsp
---

> 倘若我们当中哪一位偶尔想与人交交心或谈谈自己的感受，对方无论怎样回应，十有八九都会使他不快，因为他发现与他对话的人在顾左右而言他。他自己表达的，确实是他在日复一日的思虑和苦痛中凝结起来的东西，他想传达给对方的，也是长期经受等待和苦恋煎熬的景象。对方却相反，认为他那些感情都是俗套，他的痛苦俯仰皆是，他的惆怅人皆有之。
>
> -- 加缪 《鼠疫》

书接上文。继续分享一些“在日复一日的思虑和苦痛中凝结起来的东西”。

## 抽象语法树

树是计算机科学中一个相当知名的数据结构。抽象语法树上的每一个节点都代表源代码的某个结构：函数体、变量名等等。

### 解析器

解析器将源代码转变为抽象语法树。

一般语言服务器要用到的解析器有如下 3 个来源：

- 该语言的编译器/解释器一定包含一个解析器，好处是解析结果一定和编译器/解释器完全一致
  - [clangd](https://github.com/clangd/clangd): 其解析器来源于 [clang](https://github.com/llvm/llvm-project), C/C++ 编译器
  - [nixd](https://github.com/nix-community/nixd): 其解析器来源于 [nix](https://github.com/nixos/nix), nix lang 解释器
  - [jq-lsp](https://github.com/wader/jq-lsp): 其解析器来源于 [gojq](https://github.com/itchyny/gojq), jq 解释器
  - [jedi](https://github.com/davidhalter/jedi): 提供 python REPL 的代码补全，被 [jedi-languag-server](https://github.com/pappasam/jedi-language-server) 封装为语言服务器，其解析器就是 python 内置的 `import ast`
- 如果该语言是图灵完备的，可以用该语言实现一个解析器，好处是不用引入外部语言的依赖
  - [vim-vimlparser](https://github.com/vim-jp/vim-vimlparser): vim script
- tree-sitter: 好处是通用
  - 微软的 [pyright](https://github.com/microsoft/pyright)

### 语法高亮

抽象语法树可以被用来实现语法高亮。常见的语法高亮方案是：

- 基于正则表达式
  - [pygments](https://github.com/pygments/pygments):
    - 格式： python
    - 最初用于 python 程序
    - 也可用于 LaTeX 的 minted 宏包
  - [rouge](https://github.com/rouge-ruby/rouge):
    - 格式： ruby
    - 最初用于 ruby 程序
  - [listings](https://ctan.org/pkg/listings):
    - 格式： LaTeX
    - 最初用于 LaTeX
  - [tmLanguage](https://macromates.com/manual/en/language_grammars):
    - 格式： XML
    - 最初用于 TextMate
    - 现也用于 VS Code
  - [sublime syntax](https://www.sublimetext.com/docs/syntax.html):
    - 格式： yaml
    - 最初用于 Sublime
    - 现也用于 [bat](github.com/sharkdp/bat)
    - 语法实质是 tmLanguage 的超集， Sublime 可以直接将 tmLanguage 转换为 sublime syntax
  - VimSyn:
    - 格式： vim script
    - 用于 Vim, NeoVim
    - [名称来源](https://github.com/vim/vim/issues/9087)
- 基于抽象语法树
  - [tree-sitter](https://github.com/tree-sitter/tree-sitter):
    - 原始格式是 javascript ，生成 C 代码，最后编译为二进制文件。
    - 最初用于 Atom
    - 也可用于 NeoVim, VS Code 的[某些插件](https://github.com/EvgeniyPeshkov/syntax-highlighter) , helix, kakoune, [syncat](https://github.com/foxfriends/syncat)

[性能对比](https://github.com/sharkdp/bat/blob/master/doc/alternatives.md)。

- VimSyn 和 tree-sitter 的[结果对比](https://github.com/nvim-treesitter/nvim-treesitter/wiki/Gallery)：

![example-cpp](https://user-images.githubusercontent.com/2361214/202753610-e923bf4e-e88f-494b-bb1e-d22a7688446f.png)

- 在 VS Code 中使能 tree-sitter 前后的结果对比：

![vs code](https://github.com/EvgeniyPeshkov/syntax-highlighter/raw/master/images/demo.gif)

### 语义高亮

语言服务器协议中有语义 token 这一 feature ，语法和语义的区别见下：

语法：

![py_](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/22db5546-3d44-4798-ad9a-72740fc09c25)

![c_](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/5e18a588-caa0-44f3-a78d-a54ee030af0a)

语义：

![py](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/1e6d862b-f748-4fdf-9237-2623bd4e8812)

![c](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/656d4ca2-fb2c-45a6-bc54-4a33000aa331)

## 实践

### tree sitter

接下来参考 [tree-sitter](https://tree-sitter.github.io/tree-sitter/creating-parsers) 文档，我们来选一门比较简单的 DSL 实现一个解析器~

介绍一下 zathurarc ，这是 vim 开发 LaTeX 的插件 [vimtex](https://github.com/lervag/vimtex) 首推的 pdf 浏览器 [zathura](https://github.com/pwmt/zathura) 的配置语言。 zathurarc 文档并未给出 EBNF 范式。所以根据描述来理解它的语法。

先支持一下注释。我们编写一个 `grammar.js` 。我们降低了空格的优先级以确保在任何时候空格都会最后被分隔。

```javascript
module.exports = grammar({
    name: "zathurarc",
    rules: {
        file: ($) => repeat(seq(optional($._code), $._end)),
        _code: (_) => /[^#]*/,

        comment: (_) => /#[^\n]*/,
        _eol: (_) => /\r?\n/,
        _space: (_) => prec(-1, repeat1(/[ \t]/)),
        _end: ($) => seq(optional($._space), optional($.comment), $._eol),
    },
});
```

```sh
$ tree-sitter generate
$ tree-sitter parse tests/zathurarc
(file [0, 0] - [7, 0]
    (comment [0, 0] - [0, 6])
    (comment [2, 26] - [2, 40])
(comment [3, 26] - [3, 43]))
```

注释可以被成功识别。代码因为以 `_` 开头被隐藏了。

```vim
# test
include desktop/zathurarc
map [normal] <Esc> zoom in#with argument
map <F1> recolor          #without argument
set recolor false
unmap <F1>
unmap [normal] <Esc>
```

除开注释只有 4 种语法：

- `set option value`: 设置选项， `value` 可以是布尔、整数、浮点数、字符串
- `map [mode] <binding> <shortcut function> <argument>`: 映射快捷键
- `unmap [mode] <binding>`: 取消映射快捷键
- `include <config_path>`: 文件包含

先支持一下 4 种类型。

```javascript
    int: (_) => /\d+/,
        float: ($) => choice(seq(optional($.int), ".", $.int), seq($.int, optional("."))),
        string: ($) => choice($._quoted_string, $._word),
        bool: (_) => choice("true", "false"),

        _word: (_) => repeat1(/(\S|\\ )/),
        _quoted_string: (_) =>
        choice(
            seq('"', field("content", repeat1(/[^"]|\\"/)), '"'),
            seq("'", field("content", repeat1(/[^']|\\'/)), "'")
        ),
```

于是 `set` 就很简单了。因为其他 3 种指令还没实现，所以先注释了：

```javascript
    _code: ($) =>
        choice(
            $.set_directive,
            // $.include_directive,
            // $.map_directive,
            // $.unmap_directive
        ),

        set_directive: ($) =>
        seq(
            alias("set", $.command),
            alias(repeat1(/[a-z-]/), $.option),
            choice($.int, $.float, $.string, $.bool)
        ),
```

```sh
$ tree-sitter generate
Unresolved conflict for symbol sequence:

'set'  set_directive_repeat1  int  •  comment  …

Possible interpretations:

1:  'set'  set_directive_repeat1  (float  int)  •  comment  …
2:  (set_directive  'set'  set_directive_repeat1  int)  •  comment  …

Possible resolutions:

1:  Specify a higher precedence in `float` than in the other rules.
2:  Specify a higher precedence in `set_directive` than in the other rules.
3:  Add a conflict for these rules: `set_directive`, `float`
```

好好好，浮点数 `a.b` 有被识别为整数 `a` 的可能。我们提高浮点数的优先级。

```javascript
    int: (_) => /\d+/,
        float: ($) =>
        prec(
            2,
            choice(seq(optional($.int), ".", $.int), seq($.int, optional(".")))
        ),
        string: ($) => choice($._quoted_string, $._word),
        bool: (_) => choice("true", "false"),

        _word: (_) => repeat1(/(\S|\\ )/),
        _quoted_string: (_) =>
        choice(
            seq('"', field("content", repeat1(/[^"]|\\"/)), '"'),
            seq("'", field("content", repeat1(/[^']|\\'/)), "'")
        ),
```

```sh
$ tree-sitter generate
$ tree-sitter parse tests/zathurarc
(file [0, 0] - [7, 0]
    (comment [0, 0] - [0, 6])
    (ERROR [1, 0] - [2, 26])
    (comment [2, 26] - [2, 40])
    (ERROR [3, 0] - [3, 16]
    (int [3, 6] - [3, 7]))
    (comment [3, 26] - [3, 43])
    (set_directive [4, 0] - [4, 17]
        (command [4, 0] - [4, 3])
        (option [4, 4] - [4, 11])
    (bool [4, 12] - [4, 17]))
    (ERROR [5, 0] - [6, 20]
(int [5, 8] - [5, 9])))
tests/zathurarc 0 ms    (ERROR [1, 0] - [2, 26])
```

我们注意到无法被解析的节点的类型是 `ERROR` 。事实上后面我们就是用这种方法来实现语言服务器的代码诊断的。
再补上剩下 3 种指令：

```javascript
    _code: ($) =>
        choice(
            $.set_directive,
            $.include_directive,
            $.map_directive,
            $.unmap_directive
        ),

        // ...

        include_directive: ($) =>
        seq(alias("include", $.command), alias($._word, $.path)),

        unmap_directive: ($) =>
        seq(alias("unmap", $.command), optional($.mode), $.key),

        map_directive: ($) =>
        seq(
            alias("map", $.command),
            optional($.mode),
            $.key,
            alias(/[a-z_]+/, $.function),
            optional(seq($._space, alias(/[a-z_]+/, $.argument)))
        ),
```

`tree-sitter generate` 提示存在冲突，并给出了提高优先级或声明 `conlicts` 的解决方法：

```sh
$ tree-sitter generate
Unresolved conflict for symbol sequence:

'map'  key  'map_directive_token1'  •  '_space_token1'  …

Possible interpretations:

1:  (map_directive  'map'  key  'map_directive_token1'  •  _space  'map_directive_token1')
2:  (map_directive  'map'  key  'map_directive_token1')  •  '_space_token1'  …

Possible resolutions:

1:  Specify a left or right associativity in `map_directive`
2:  Add a conflict for these rules: `map_directive`
```

采纳一个：

```javascript
module.exports = grammar({
    name: "zathurarc",

    conflicts: ($) => [
        [$.map_directive]
    ],

    // ...
})
```

```sh
$ tree-sitter generate
$ tree-sitter parse tests/zathurarc
(file [0, 0] - [7, 0]
    (comment [0, 0] - [0, 6])
    (include_directive [1, 0] - [1, 25]
        (command [1, 0] - [1, 7])
    (path [1, 8] - [1, 25]))
    (map_directive [2, 0] - [2, 26]
        (command [2, 0] - [2, 3])
        (mode [2, 4] - [2, 12]
        (mode_name [2, 5] - [2, 11]))
        (key [2, 13] - [2, 18]
        (key_name [2, 14] - [2, 17]))
        (function [2, 19] - [2, 23])
    (argument [2, 24] - [2, 26]))
    (comment [2, 26] - [2, 40])
    (map_directive [3, 0] - [3, 16]
        (command [3, 0] - [3, 3])
        (key [3, 4] - [3, 8]
        (key_name [3, 5] - [3, 7]))
    (function [3, 9] - [3, 16]))
    (comment [3, 26] - [3, 43])
    (set_directive [4, 0] - [4, 17]
        (command [4, 0] - [4, 3])
        (option [4, 4] - [4, 11])
    (bool [4, 12] - [4, 17]))
    (unmap_directive [5, 0] - [5, 10]
        (command [5, 0] - [5, 5])
        (key [5, 6] - [5, 10]
    (key_name [5, 7] - [5, 9])))
    (unmap_directive [6, 0] - [6, 20]
        (command [6, 0] - [6, 5])
        (mode [6, 6] - [6, 14]
        (mode_name [6, 7] - [6, 13]))
        (key [6, 15] - [6, 20]
(key_name [6, 16] - [6, 19]))))
```

还有一堆问题，比如：

- 转义 `\#` 。
- 按 `zathurarc` 的语法， `"true"` 也算布尔型（这太坑了）。

但对大多数情况这个解析器已经足矣。

编写[单元测试](https://tree-sitter.github.io/tree-sitter/creating-parsers#command-test)，另外我们需要提供对各种语言的绑定。

- `tree-sitter generate` 目前会生成对 rust 和 javascript 的绑定。
- 除此之外对 C, Go, Python, Swift 和 Zig 的绑定也已经在 PR 阶段。
- 一些常用的解析器的 python 绑定已经被第三方库 [tree-sitter-languages](https://github.com/grantjenks/py-tree-sitter-languages) 实现。可以不用造轮子。

在 PR 合并之前，我们可以简单的编写一个 python 的绑定。考虑到 [#2438](https://github.com/tree-sitter/tree-sitter/pull/2438/) 会被合并以及本文的重点只和语言服务器有关，不做太详细的介绍：

[py-tree-sitter](https://github.com/tree-sitter/py-tree-sitter) 提供了用于 python 的绑定的应用编程接口。我们只需要额外在 python 项目提供一个 C 语言的二进制构建后端。这样的[后端很多](https://scikit-build-core.readthedocs.io/en/latest/index.html#other-projects-for-building)，笔者选择了使用 [`scikit-build-core`](https://scikit-build-core.readthedocs.io/) 通过编写 `CMakeLists.txt` 完成。

本部分代码开源于 [tree-sitter-zathurarc](https://github.com/Freed-Wu/tree-sitter-zathurarc) 。

### 代码诊断

我们可以实现代码诊断了。 tree-sitter 提供了一门内置叫做 [tree-sitter-query](https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries) 的 Lisp 方言。我们可以用它来获取所有的 `ERROR` 节点：

```scheme
(ERROR) @error
```

先创建一个语言服务器，添加代码诊断功能。它只会在文件打开和改动后向第一行添加一个 `hello, error!` 的报错：

```python
from typing import Any
from lsprotocol.types import *
from pygls.server import LanguageServer


class ZathuraLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)

        @self.feature(TEXT_DOCUMENT_DID_OPEN)
        @self.feature(TEXT_DOCUMENT_DID_CHANGE)
        def did_change(params: DidChangeTextDocumentParams) -> None:
            diagnostics = [
                Diagnostic(
                    Range(Position(0, 0), Position(1, 0)),
                    "hello, error!",
                    DiagnosticSeverity.Error,
                )
            ]
            self.publish_diagnostics(params.text_document.uri, diagnostics)
```

![hello](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/146def59-1191-4994-8a3b-9febc9408c8a)

这样的报错毫无意义。让我们从 python 的绑定中获取解析器和用于解析 tree-sitter-query 的 `language` 。

```python
from tree_sitter_zathurarc import parser, language


class ZathuraLanguageServer(LanguageServer):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.trees = {}

        @self.feature(TEXT_DOCUMENT_DID_OPEN)
        @self.feature(TEXT_DOCUMENT_DID_CHANGE)
        def did_change(params: DidChangeTextDocumentParams) -> None:
            document = self.workspace.get_document(params.text_document.uri)
            self.trees[document.uri] = parser.parse(document.source.encode())
            query = language.query("(ERROR) @error")
            captures = query.captures(self.trees[document.uri].root_node)
            error_nodes = [capture[0] for capture in captures]
            diagnostics = [
                Diagnostic(
                    Range(Position(*node.start_point), Position(*node.end_point)),
                    "parse error",
                    DiagnosticSeverity.Error,
                )
                for node in error_nodes
            ]
            self.publish_diagnostics(params.text_document.uri, diagnostics)
```

![parse](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/3e3c1e97-7f4d-45f1-b290-80ac74fac03f)

我们很快得到了我们想要的 `:)` 。

本部分代码开源于 [zathura-language-server](https://github.com/Freed-Wu/zathura-language-server) 。

### 反思

仅仅是检测错误的语法恐怕还不够。比如：

```vim
set font 42
```

这符合我们刚刚提到的 `set option value` 的语法，但：

```sh
$ zathura /the/path/of/your.pdf
error: Unable to load CSS: <data>:5:15Expected a string.
```

因为字体不可能是一个整数。

这样的设定并不少见。比如 vim, tmux, mutt 等软件均有 `set option value` 的语法，我们必须对选项值的合法性做代码诊断。

把选项值的合法性的代码诊断放到 `grammar.js` 中可以吗？

```javascript
    set_directive: ($) =>
        seq(
            alias("set", $.command),
            choice(
                seq(alias(choice("font", /*...*/ ), $.option), $.string),
                seq(alias(choice( /*...*/ ), $.option), $.int),
                seq(alias(choice( /*...*/ ), $.option), $.float),
                seq(alias(choice( /*...*/ ), $.option), $.bool),
            ),
        ),
```

可以是可以。但：

- 所有的报错都是 `parse error` 。用户如何知道怎么修改错误？
- 合法性的数据被硬编码到了 `grammar.js` 中。这不符合编程中代码、数据相分离的原则。
- 代码难以复用。不同软件的 `set option value` 完全可以把合法性诊断的代码剥离出来抽象为一个新的库。

接下来我们将引入新的技术，来告诉用户 `42 is not of type 'string'` 。

![42](https://github.com/Freed-Wu/Freed-Wu.github.io/assets/32936898/1973f4de-4569-4022-bde3-abbe7055dfd5)
