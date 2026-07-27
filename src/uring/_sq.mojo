# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.collections import InlineArray

from ._mmap import _Mmap
from ._params import _SubmissionQueueRingOffsets


comptime _IORING_OP_NOP = 0


@align(8)
struct _SubmissionQueueEntry(ImplicitlyCopyable):
    var _opcode: UInt8
    var _flags: UInt8
    var _ioprio: UInt16
    var _fd: Int32
    var _off: UInt64
    var _addr: UInt64
    var _len: UInt32
    var _rw_flags: UInt32
    var _user_data: UInt64
    var _buf_index: UInt16
    var _personality: UInt16
    var _splice_fd_in: Int32
    var _pad2: InlineArray[UInt64, 2]

    def __init__(out self):
        self._opcode = 0
        self._flags = 0
        self._ioprio = 0
        self._fd = 0
        self._off = 0
        self._addr = 0
        self._len = 0
        self._rw_flags = 0
        self._user_data = 0
        self._buf_index = 0
        self._personality = 0
        self._splice_fd_in = 0
        self._pad2 = InlineArray[UInt64, 2](fill=0)

    def _reset(mut self):
        self = _SubmissionQueueEntry()

    def _prep_nop(mut self):
        self._reset()
        self._opcode = _IORING_OP_NOP


struct _SubmissionQueue(Movable):
    var _kernel_head: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _kernel_tail: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _ring_mask: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _ring_entries: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _flags: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _dropped: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _array: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _sqes: UnsafePointer[_SubmissionQueueEntry, MutUntrackedOrigin]
    var _mask: UInt32
    var _entries: UInt32
    var _sq_mmap: _Mmap
    var _sqes_mmap: _Mmap
    var _head: UInt32
    var _tail: UInt32
    var _pending: UInt32

    def __init__(
        out self,
        var sq_mmap: _Mmap,
        var sqes_mmap: _Mmap,
        offsets: _SubmissionQueueRingOffsets,
    ):
        self._kernel_head = (sq_mmap._address + Int(offsets._head)).bitcast[
            UInt32
        ]()
        self._kernel_tail = (sq_mmap._address + Int(offsets._tail)).bitcast[
            UInt32
        ]()
        self._ring_mask = (sq_mmap._address + Int(offsets._ring_mask)).bitcast[
            UInt32
        ]()
        self._ring_entries = (
            sq_mmap._address + Int(offsets._ring_entries)
        ).bitcast[UInt32]()
        self._flags = (sq_mmap._address + Int(offsets._flags)).bitcast[UInt32]()
        self._dropped = (sq_mmap._address + Int(offsets._dropped)).bitcast[
            UInt32
        ]()
        self._array = (sq_mmap._address + Int(offsets._array)).bitcast[UInt32]()
        self._sqes = sqes_mmap._address.bitcast[_SubmissionQueueEntry]()
        self._mask = self._ring_mask[]
        self._entries = self._ring_entries[]
        self._sq_mmap = sq_mmap^
        self._sqes_mmap = sqes_mmap^
        self._head = self._kernel_head[]
        self._tail = self._kernel_tail[]
        self._pending = 0

    def _has_pending(self) -> Bool:
        return self._pending != 0

    def _refresh_head(mut self):
        self._head = self._kernel_head[]

    def _is_full(self) -> Bool:
        return self._tail - self._head >= self._entries

    def _reserve(
        mut self,
    ) -> Optional[UnsafePointer[_SubmissionQueueEntry, MutUntrackedOrigin]]:
        if self._is_full():
            self._refresh_head()
            if self._is_full():
                return None

        var index = self._tail & self._mask
        self._tail += 1
        self._pending += 1
        return self._sqes + Int(index)

    def _publish(mut self):
        if self._pending == 0:
            return

        var start = self._tail - self._pending
        var cursor = start
        while cursor != self._tail:
            self._array[Int(cursor & self._mask)] = cursor & self._mask
            cursor += 1

        # The kernel observes SQEs after the tail update. Mojo does not expose a
        # stable userspace release-store primitive here yet, so this default-ring
        # implementation relies on ordinary stores until a std atomic API is
        # available for mmap-backed scalars.
        self._kernel_tail[] = self._tail
        self._pending = 0
