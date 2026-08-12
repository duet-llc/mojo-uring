# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import AnyCoroutine, _coro_resume_fn
from std.os import abort
from std.sys.info import align_of

from ._coroutine import _coro_from_addr, _coro_to_addr, _suspend_async


comptime _CANCELED = 0x1
comptime _RESERVED = _CANCELED


@fieldwise_init
struct _Canceled:
    pass


struct Context(Defaultable, Movable):
    var _state: UInt64

    def __init__(out self):
        self._state = 0

    def _cancel(mut self) raises _Canceled:
        if self._canceled():
            raise _Canceled()

        self._state |= _CANCELED
        var address = self._state & ~_RESERVED
        if address:
            _coro_resume_fn(_coro_from_addr(Int(address)))

    def _canceled(self) -> Bool:
        return Bool(self._state & _RESERVED)

    @always_inline
    def _suspend[
        Body: def(AnyCoroutine) -> None,
    ](mut self, body: Body) raises _Canceled -> Bool:
        if self._canceled():
            raise _Canceled()
        if self._state & ~_RESERVED:
            abort("re-suspended")

        def async_body(hdl: AnyCoroutine) {mut self, body}:
            comptime assert align_of[AnyCoroutine]() > _RESERVED
            var address = UInt64(_coro_to_addr(hdl))
            self._state = address | (self._state & _RESERVED)
            body(hdl)

        _suspend_async(async_body)

        self._state &= _RESERVED
        return not self._canceled()
