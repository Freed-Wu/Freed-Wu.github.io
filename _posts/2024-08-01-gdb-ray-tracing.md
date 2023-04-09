---
title: 『新时代 C/C++ 面试题』 GDB 光追
tags:
  - develop
  - gdb
  - computer graphics
---

前情提要：

- [CMake 光追](https://zhuanlan.zhihu.com/p/123419161)
- [LaTeX3 Phong 渲染](https://zhuanlan.zhihu.com/p/671499177)

![output](https://github.com/Freed-Wu/gdb-ray-tracing/assets/32936898/bef29d5e-9883-4d90-b089-29c8656f9c23)

本文代码开源于 [gdb-ray-tracing](https://github.com/Freed-Wu/gdb-ray-tracing) 。

## 解释

gdb 内置了一门图灵完备的脚本语言，称为 GDB 或 gdb script 。此语言的初衷是让用户在用 gdb 调试代码时更加灵活，例如：

`test.c`:

```c
#if 0
bin="$(basename "$0")" && bin="${bin%%.*}" && cc -g "$0" -o"$bin" && exec cgdb ./"$bin" -- --args "$@"
#endif
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char *argv[]) {
  for (int i = 0; i < 5; i++)
    printf("i = %d\n", i);
  return EXIT_SUCCESS;
}
```

安装 [cgdb](https://github.com/cgdb/cgdb) 。然后：

```sh
chmod +x test.c
./test.c
```

进入调试界面，在 gdb REPL 中输入：

```gdb
define hook-stop
  set $str = "currently, i is %d\n"
  if i > 3
    printf $str, i
  end
end
start
```

接下来不停 `next` 单步运行，在 最后一次 `for` 循环中将会在输出 `i = 4\n` 之前先打印 `currently, i is 4\n` 。

## 解决方案

gdb script 提供了 `if`, `while` 等程序控制指令和 `printf`, `print` 等输出指令。相比较 cmake 光追，方便之处在于：

- gdb 支持所有 C 语言支持的简单数据类型，比如 float 和 double ，而 cmake 不支持小数，需要用整数模拟定点小数。
- gdb 有一个 REPL

不便之处在于：

- gdb 报错不显示回溯信息，只显示回溯堆栈最顶层的位置。调试起来异常困难
- gdb 不支持变量作用域，即所有变量都是全局而非局部的。
- gdb 函数没有专门的返回指令，靠修改全局变量来返回结果。

笔者的解决方案：

- 写单元测试，先确保每个函数正常工作，再一步步拼装成一个完整的代码。函数内部用日志打印输出，和 cmake 光追的代码对比确认是否正确。顺手发现 cmake 光追的 `Float_Print()` 函数有 bug 。
- 约定函数 `foo_bar()` 内所有的变量都以 `$foo_bar_` 开头。同时把递归的代码改为迭代防止全局变量覆盖。
- 约定函数的返回值叫 `$return`

复现 bug 方法如下：

```cmake
Vec3(test_vec f1 fN1 f1)
Vec3_Normalize(result_vec test_vec)
Vec3_Print(result_vec)
```

结果是 `0.577865, -1.577866, 0.577865`, 但正确答案是 `0.577865, -0.577865, 0.577865` 。

## 设置

- 采样： 1 spp
- 材质： 镜面

虽然 gdb 是 C 的调试器但 `$` 开头的寄存器变量并没有地址，所以用不了卡马克平方根倒数快速算法，只是普通的牛顿迭代法。

## 用法

封装了一个库 [`ray-tracing.gdb`](https://github.com/Freed-Wu/gdb-ray-tracing/blob/main/ray-tracing.gdb) 。在注释里写了入参和出参的类型和描述。参考 [main.gdb](https://github.com/Freed-Wu/gdb-ray-tracing/blob/main/main.gdb) ，使用时 `source` 这个库即可。

## 接口

### python

gdb 有一个可选的 python 接口：

```gdb
source test.py
```

`test.py`:

```python
import gdb

gdb.source(
    """define hook-stop
  set $str = "currently, i is %d\n"
  if i > 3
    printf $str, i
  end
end
start"""
)
```

所以亦可以在 python 中完成光追的运算再只让 gdb 输出。本文的解决方案并不依赖这个接口。

非常有名的 [gdb-dashboard](https://github.com/cyrus-and/gdb-dashboard) 利用了此接口，为 gdb 实现了一个漂亮的 UI 。

![gdb-dashboard](https://github.com/Freed-Wu/gdb-ray-tracing/assets/32936898/fa7c6aba-0279-4d15-8f9e-b5d0c5a07e3e)

### shell

gdb 有一个 shell 接口。用户可以运行 bash, zsh, windows command shell 指令。类似

## 总结

性能**极其极其**低下。本文仅仅是对邱奇——图灵论题的一次验证性实验，请勿在任何生产环境中使用它！

初稿撰写于机场候机大厅及万米高空之上。
