# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

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
            ](425, entries, Pointer(to=params._params))
        elif is_triple["aarch64-unknown-linux-gnu"]():
            result = inlined_assembly[
                "svc #0",
                c_long,
                c_long,
                UInt32,
                Pointer[mut=True, _Params, origin_of(params._params)],
                constraints="={x0},{x8},{x0},{x1},~{memory}",
            ](425, entries, Pointer(to=params._params))
        else:
            CompilationTarget.unsupported_target_error()

        if result < 0:
            raise ErrNo(Int32(-result))

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
