# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import ErrNo, c_int, c_long, c_size_t, external_call
from std.memory import Pointer
from std.sys.info import size_of

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


def _io_uring_setup(entries: UInt32, mut params: _Params) raises -> c_int:
    var result = external_call[
        "syscall",
        c_long,
        c_long,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
    ](
        _SYS_IO_URING_SETUP,
        UInt64(entries),
        UInt64(Int(Pointer(to=params))),
        0,
        0,
        0,
        0,
    )
    if result < 0:
        raise ErrNo(Int32(-result))
    return c_int(result)


def _io_uring_enter(
    fd: _FileDescriptor, to_submit: UInt32, min_complete: UInt32, flags: UInt32
) raises -> UInt32:
    var result = external_call[
        "syscall",
        c_long,
        c_long,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
        UInt64,
    ](
        _SYS_IO_URING_ENTER,
        UInt64(fd._value),
        UInt64(to_submit),
        UInt64(min_complete),
        UInt64(flags),
        0,
        0,
    )
    if result < 0:
        raise ErrNo(Int32(-result))
    return UInt32(result)


struct Uring(Movable):
    var _sq: _SubmissionQueue
    var _cq: _CompletionQueue
    var _fd: _FileDescriptor

    def __init__(out self, entries: UInt32, var params: Params) raises:
        var result = _io_uring_setup(entries, params._params)

        self._fd = _FileDescriptor(result)
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

    def _drive_once(mut self) raises:
        if self._sq._has_pending():
            self._sq._publish()
            _ = _io_uring_enter(self._fd, 1, 0, 0)
        elif not self._cq._has_ready():
            _ = _io_uring_enter(self._fd, 0, 0, 0)
        self._cq._reap_ready()

    def _nop_sync(mut self) raises:
        var maybe_sqe = self._sq._reserve()
        if not maybe_sqe:
            self._sq._publish()
            _ = _io_uring_enter(self._fd, 1, 0, 0)
            maybe_sqe = self._sq._reserve()
        if not maybe_sqe:
            raise Error("submission queue is full after kernel progress")
        var sqe = maybe_sqe.value()
        sqe[]._prep_nop()
        sqe[]._user_data = 0
        self._sq._publish()
        _ = _io_uring_enter(self._fd, 1, 1, 0)
        self._cq._reap_ready()

    async def nop(mut self) raises:
        # TODO: switch this synchronous fallback to suspend/resume once Mojo's
        # public coroutine suspension hook for AnyCoroutine is available.
        self._nop_sync()
