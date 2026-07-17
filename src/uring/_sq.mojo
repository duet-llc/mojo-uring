# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.collections import InlineArray

from ._mmap import _Mmap
from ._params import _SubmissionQueueRingOffsets


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
