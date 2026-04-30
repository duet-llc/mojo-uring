# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import ErrNo, c_int, c_long
from std.memory import Pointer
from std.sys import inlined_assembly
from std.sys.info import CompilationTarget, is_triple

from .fd import _FileDescriptor
from .params import Params, _Params


struct Uring:
    var _params: Params
    var _fd: _FileDescriptor

    def __init__(out self, var entries: UInt32, var params: Params) raises:
        self._params = params

        var result: c_long

        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                UInt32,
                Pointer[mut=True, _Params, origin_of(self._params._params)],
                constraints="={rax},{rax},{rdi},{rsi},~{rcx},~{r11},~{memory}",
            ](425, entries, Pointer(to=self._params._params))
        elif is_triple["aarch64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                UInt32,
                Pointer[mut=True, _Params, origin_of(self._params._params)],
                constraints="={x0},{x8},{x0},{x1},~{memory}",
            ](425, entries, Pointer(to=self._params._params))
        else:
            CompilationTarget.unsupported_target_error()

        if result < 0:
            raise ErrNo(Int32(-result))

        self._fd = _FileDescriptor(c_int(result))
