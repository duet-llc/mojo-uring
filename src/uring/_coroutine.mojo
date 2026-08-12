# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import AnyCoroutine
from std.sys import inlined_assembly
from std.sys.info import size_of


@always_inline
def _suspend_async[Body: def(AnyCoroutine) -> None](body: Body):
    __mlir_region await_body(hdl: __mlir_type.`!co.routine`):
        body(hdl)
        __mlir_op.`co.suspend.end`()

    __mlir_op.`co.suspend`[_region="await_body".value]()


@always_inline
def _coro_to_addr(hdl: AnyCoroutine) -> Int:
    comptime assert size_of[AnyCoroutine]() == size_of[Int]()
    return inlined_assembly["", Int, AnyCoroutine, constraints="=r,0"](hdl)


@always_inline
def _coro_from_addr(address: Int) -> AnyCoroutine:
    comptime assert size_of[AnyCoroutine]() == size_of[Int]()
    return inlined_assembly["", AnyCoroutine, Int, constraints="=r,0"](address)
