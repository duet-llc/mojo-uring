# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import AnyCoroutine, _coro_resume_fn, _suspend_async
from std.sys.info import align_of


comptime _CANCELED = 0x1
comptime _RESERVED = _CANCELED


@fieldwise_init
struct _Canceled:
    pass


struct Context(Defaultable, Movable):
    var _state: UInt64

    def __init__(out self):
        self._state = 0

    def cancel(mut self) raises _Canceled:
        if self.canceled():
            raise _Canceled()

        self._state |= _CANCELED
        var address = self._state & ~_RESERVED
        if address:
            self._state &= _RESERVED
            _coro_resume_fn(
                rebind[AnyCoroutine](
                    OpaquePointer[MutUntrackedOrigin](
                        unsafe_from_address=Int(address)
                    )
                )
            )

    def canceled(self) -> Bool:
        return Bool(self._state & _RESERVED)

    @always_inline
    def _suspend[
        body: def(AnyCoroutine) capturing -> None,
    ](mut self) raises _Canceled:
        if self.canceled():
            raise _Canceled()

        @parameter
        def async_body(hdl: AnyCoroutine) capturing:
            comptime assert align_of[AnyCoroutine]() > _RESERVED
            var address = UInt64(rebind[OpaquePointer[MutUntrackedOrigin]](hdl))
            self._state = address | (self._state & _RESERVED)
            body(hdl)

        _suspend_async[async_body]()

        self._state &= _RESERVED
