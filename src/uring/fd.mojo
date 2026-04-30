# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import c_int, c_long
from std.sys import inlined_assembly
from std.sys.info import CompilationTarget, is_triple


@fieldwise_init
struct _FileDescriptor:
    var _value: c_int

    def __del__(deinit self):
        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            _ = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                c_int,
                constraints="={rax},{rax},{rdi},~{rcx},~{r11},~{memory}",
            ](3, self._value)
        elif is_triple["aarch64-unknown-linux-gnu"]():
            _ = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                c_int,
                constraints="={x0},{x8},{x0},~{memory}",
            ](57, self._value)
        else:
            CompilationTarget.unsupported_target_error()
