# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import AnyCoroutine, _coro_resume_fn
from std.sys.info import align_of

from ._coroutine import _coro_from_addr, _coro_to_addr, _suspend_async


comptime _CANCELED = 0x1
comptime _RESERVED = _CANCELED


@fieldwise_init
struct Canceled:
    pass


trait Cancelable:
    def cancel(mut self) raises Canceled:
        ...

    def _cancelable_suspend_async[
        Body: def(AnyCoroutine) -> None,
    ](mut self, body: Body) raises Canceled -> Bool:
        ...


@fieldwise_init
struct Context(Defaultable, Movable):
    pass


struct CancelableContext(Cancelable, Defaultable, Movable):
    var _state: UInt64

    def __init__(out self):
        self._state = 0

    def cancel(mut self) raises Canceled:
        if self.canceled():
            raise Canceled()

        self._state |= _CANCELED
        var address = self._state & ~_RESERVED
        if address:
            _coro_resume_fn(_coro_from_addr(Int(address)))

    def canceled(self) -> Bool:
        return Bool(self._state & _CANCELED)

    @always_inline
    def _cancelable_suspend_async[
        Body: def(AnyCoroutine) -> None,
    ](mut self, body: Body) raises Canceled -> Bool:
        if self.canceled():
            raise Canceled()
        debug_assert(not (self._state & ~_RESERVED), "re-suspended")

        def async_body(hdl: AnyCoroutine) {mut self, body}:
            comptime assert align_of[AnyCoroutine]() > _RESERVED
            var address = UInt64(_coro_to_addr(hdl))
            self._state = address | (self._state & _RESERVED)
            body(hdl)

        _suspend_async(async_body)

        self._state &= _RESERVED
        return not self.canceled()
