# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import ErrNo, c_long
from std.memory import UnsafePointer
from std.sys import inlined_assembly
from std.sys.info import CompilationTarget, is_triple

from .params import Params, _Params


struct Uring:
    var _params: Params
    var _fd: c_long

    def __init__(out self, var entries: UInt32, var params: Params) raises:
        self._params = params

        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            self._fd = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                UInt32,
                UnsafePointer[_Params, origin_of(self._params._params)],
                constraints="={rax},{rax},{rdi},{rsi},~{rcx},~{r11},~{memory}",
            ](425, entries, UnsafePointer(to=self._params._params))
        elif is_triple["aarch64-unknown-linux-gnu"]():
            self._fd = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                UInt32,
                UnsafePointer[_Params, origin_of(self._params._params)],
                constraints="={x0},{x8},{x0},{x1},~{memory}",
            ](425, entries, UnsafePointer(to=self._params._params))
        else:
            CompilationTarget.unsupported_target_error()

        if self._fd < 0:
            raise ErrNo(Int32(-self._fd))

    def __del__(deinit self):
        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            _ = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                c_long,
                constraints="={rax},{rax},{rdi},~{rcx},~{r11},~{memory}",
            ](3, self._fd)
        elif is_triple["aarch64-unknown-linux-gnu"]():
            _ = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                c_long,
                constraints="={x0},{x8},{x0},~{memory}",
            ](57, self._fd)
        else:
            CompilationTarget.unsupported_target_error()
