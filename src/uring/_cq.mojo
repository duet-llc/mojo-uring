# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.atomic import Atomic
from std.builtin.coroutine import AnyCoroutine, _coro_resume_fn

from ._mmap import _Mmap
from ._params import _CompletionQueueRingOffsets


@align(8)
struct _CompletionQueueEntry(ImplicitlyCopyable):
    var _user_data: UInt64
    var _res: Int32
    var _flags: UInt32


struct _CompletionQueue(Movable):
    var _khead: UnsafePointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _ktail: UnsafePointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _cqes: UnsafePointer[_CompletionQueueEntry, MutUntrackedOrigin]
    var _mask: UInt32
    var _cq_mmap: _Mmap
    var _head: UInt32

    def __init__(
        out self, var cq_mmap: _Mmap, offsets: _CompletionQueueRingOffsets
    ):
        self._khead = (cq_mmap._address + Int(offsets._head)).bitcast[
            Atomic[DType.uint32]
        ]()
        self._ktail = (cq_mmap._address + Int(offsets._tail)).bitcast[
            Atomic[DType.uint32]
        ]()
        self._cqes = (cq_mmap._address + Int(offsets._cqes)).bitcast[
            _CompletionQueueEntry
        ]()
        var ring_mask = (cq_mmap._address + Int(offsets._ring_mask)).bitcast[
            UInt32
        ]()
        self._mask = ring_mask[]
        self._cq_mmap = cq_mmap^
        self._head = UInt32(self._khead[].load())

    def _reap_ready(mut self):
        var tail = UInt32(self._ktail[].load())
        while self._head != tail:
            var cqe = (self._cqes + Int(self._head & self._mask))[]
            var user_data = cqe._user_data
            self._head += 1
            self._khead[].store(self._head)
            if user_data != 0:
                var coroutine = rebind[AnyCoroutine](
                    UnsafePointer[NoneType, MutUntrackedOrigin](
                        unsafe_from_address=Int(user_data)
                    )
                )
                _coro_resume_fn(coroutine)
