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


@fieldwise_init
struct _Cell(Movable):
    var _value: UInt64

    # SAFETY: This provides interior mutability for Context's private state.
    # Context permits one pending operation and requires serialized access; no
    # mutable pointer escapes this module, so two mutations cannot overlap.
    def _mut(self) -> UnsafePointer[UInt64, MutUntrackedOrigin]:
        var address = Int(
            rebind[OpaquePointer[ImmUntrackedOrigin]](Pointer(to=self._value))
        )
        return UnsafePointer[UInt64, MutUntrackedOrigin](
            unsafe_from_address=address
        )


struct Context(Defaultable, Movable):
    var _state: _Cell

    def __init__(out self):
        self._state = _Cell(0)

    def cancel(self) raises _Canceled:
        if self.canceled():
            raise _Canceled()

        var state = self._state._mut()
        state[] |= _CANCELED
        var address = state[] & ~_RESERVED
        if address:
            _coro_resume_fn(
                rebind[AnyCoroutine](
                    OpaquePointer[MutUntrackedOrigin](
                        unsafe_from_address=Int(address)
                    )
                )
            )

    def canceled(self) -> Bool:
        return Bool(self._state._value & _RESERVED)

    @always_inline
    def _suspend[
        body: def(AnyCoroutine) capturing -> None,
    ](self) raises _Canceled:
        if self.canceled():
            raise _Canceled()

        @parameter
        def async_body(hdl: AnyCoroutine) capturing:
            comptime assert align_of[AnyCoroutine]() > _RESERVED
            var address = UInt64(rebind[OpaquePointer[MutUntrackedOrigin]](hdl))
            var state = self._state._mut()
            state[] = address | (state[] & _RESERVED)
            body(hdl)

        _suspend_async[async_body]()

        self._state._mut()[] &= _RESERVED
