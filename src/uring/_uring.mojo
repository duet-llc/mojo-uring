# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.atomic import Ordering
from std.builtin.coroutine import AnyCoroutine, _suspend_async
from std.ffi import ErrNo, c_int, c_long, c_size_t
from std.memory import Pointer
from std.sys import inlined_assembly
from std.sys.info import CompilationTarget, is_triple, size_of

from ._cq import _CompletionQueue, _CompletionQueueEntry
from ._fd import _FileDescriptor
from ._mmap import _Mmap
from ._params import Params, _Params
from ._sq import _SubmissionQueue, _SubmissionQueueEntry


comptime IORING_OFF_SQ_RING = 0
comptime IORING_OFF_CQ_RING = 0x08000000
comptime IORING_OFF_SQES = 0x10000000


comptime _SYS_IO_URING_SETUP = 425
comptime _SYS_IO_URING_ENTER = 426
comptime _IORING_OP_NOP = 0


struct Uring(Movable):
    var _sq: _SubmissionQueue
    var _cq: _CompletionQueue
    var _fd: _FileDescriptor

    def __init__(out self, entries: UInt32, var params: Params) raises:
        var result: c_long

        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                UInt32,
                Pointer[mut=True, _Params, origin_of(params._params)],
                constraints="={rax},{rax},{rdi},{rsi},~{rcx},~{r11},~{memory}",
            ](_SYS_IO_URING_SETUP, entries, Pointer(to=params._params))
        elif is_triple["aarch64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                UInt32,
                Pointer[mut=True, _Params, origin_of(params._params)],
                constraints="={x0},{x8},{x0},{x1},~{memory}",
            ](_SYS_IO_URING_SETUP, entries, Pointer(to=params._params))
        else:
            CompilationTarget.unsupported_target_error()

        if result < 0:
            raise ErrNo(c_int(-result))

        self._fd = _FileDescriptor(c_int(result))
        var sq_ring_length = c_size_t(
            params._params._sq_off._array
            + params._params._sq_entries * UInt32(size_of[UInt32]())
        )
        var cq_ring_length = c_size_t(
            params._params._cq_off._cqes
            + params._params._cq_entries
            * UInt32(size_of[_CompletionQueueEntry]())
        )
        var sqes_length = c_size_t(
            params._params._sq_entries
            * UInt32(size_of[_SubmissionQueueEntry]())
        )

        var sq_mmap = _Mmap(
            sq_ring_length, self._fd, c_long(IORING_OFF_SQ_RING)
        )
        var cq_mmap = _Mmap(
            cq_ring_length, self._fd, c_long(IORING_OFF_CQ_RING)
        )
        var sqes_mmap = _Mmap(sqes_length, self._fd, c_long(IORING_OFF_SQES))

        self._sq = _SubmissionQueue(
            sq_mmap^, sqes_mmap^, params._params._sq_off
        )
        self._cq = _CompletionQueue(cq_mmap^, params._params._cq_off)

    def _enter(
        self, to_submit: UInt32, min_complete: UInt32, flags: UInt32
    ) raises ErrNo -> UInt32:
        var result: c_long

        comptime if is_triple["x86_64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "syscall",
                c_long,
                c_long,
                c_int,
                UInt32,
                UInt32,
                UInt32,
                UInt64,
                UInt64,
                constraints="={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11},~{memory}",
            ](
                _SYS_IO_URING_ENTER,
                self._fd._value,
                to_submit,
                min_complete,
                flags,
                0,
                0,
            )
        elif is_triple["aarch64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                c_int,
                UInt32,
                UInt32,
                UInt32,
                UInt64,
                UInt64,
                constraints="={x0},{x8},{x0},{x1},{x2},{x3},{x4},{x5},~{memory}",
            ](
                _SYS_IO_URING_ENTER,
                self._fd._value,
                to_submit,
                min_complete,
                flags,
                0,
                0,
            )
        else:
            CompilationTarget.unsupported_target_error()

        if result < 0:
            raise ErrNo(c_int(-result))
        return UInt32(result)

    @always_inline
    def _schedule[
        Result: Movable,
        submit: def(mut _SubmissionQueueEntry) capturing -> None,
        complete: def(_CompletionQueueEntry) capturing raises ErrNo -> Result,
    ](mut self) raises ErrNo -> Result:
        if self._sq._tail - self._sq._head > self._sq._mask:
            self._sq._head = UInt32(
                self._sq._khead[].load[ordering=Ordering.ACQUIRE]()
            )

        while self._sq._tail - self._sq._head > self._sq._mask:
            self._cq._khead[].store[ordering=Ordering.RELEASE](self._cq._head)
            self._sq._ktail[].store[ordering=Ordering.RELEASE](self._sq._tail)
            _ = self._enter(self._sq._tail - self._sq._head, 0, 0)
            self._sq._head = UInt32(
                self._sq._khead[].load[ordering=Ordering.ACQUIRE]()
            )

        @parameter
        def async_body(hdl: AnyCoroutine) capturing:
            ref sqe = self._sq._sqes[Int(self._sq._tail & self._sq._mask)]
            sqe = _SubmissionQueueEntry()
            submit(sqe)
            sqe._user_data = UInt64(
                Int(rebind[OpaquePointer[ImmUntrackedOrigin]](hdl))
            )
            self._sq._tail += 1

        _suspend_async[async_body]()

        ref cqe = self._cq._cqes[Int(self._cq._head & self._cq._mask)]
        try:
            return complete(cqe)
        finally:
            self._cq._head += 1

    async def nop(mut self) raises:
        @parameter
        def submit(mut sqe: _SubmissionQueueEntry) capturing:
            sqe._opcode = _IORING_OP_NOP

        @parameter
        def complete(cqe: _CompletionQueueEntry) capturing raises ErrNo:
            if cqe._res < 0:
                raise ErrNo(c_int(-cqe._res))

        self._schedule[NoneType, submit, complete]()
