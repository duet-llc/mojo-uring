# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from ._mmap import _Mmap
from ._params import _CompletionQueueRingOffsets


@align(8)
struct _CompletionQueueEntry(ImplicitlyCopyable):
    var _user_data: UInt64
    var _res: Int32
    var _flags: UInt32


struct _CompletionQueue(Movable):
    var _kernel_head: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _kernel_tail: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _ring_mask: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _ring_entries: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _overflow: UnsafePointer[UInt32, MutUntrackedOrigin]
    var _cqes: UnsafePointer[_CompletionQueueEntry, MutUntrackedOrigin]
    var _mask: UInt32
    var _entries: UInt32
    var _cq_mmap: _Mmap

    def __init__(
        out self, var cq_mmap: _Mmap, offsets: _CompletionQueueRingOffsets
    ):
        self._kernel_head = (cq_mmap._address + Int(offsets._head)).bitcast[
            UInt32
        ]()
        self._kernel_tail = (cq_mmap._address + Int(offsets._tail)).bitcast[
            UInt32
        ]()
        self._ring_mask = (cq_mmap._address + Int(offsets._ring_mask)).bitcast[
            UInt32
        ]()
        self._ring_entries = (
            cq_mmap._address + Int(offsets._ring_entries)
        ).bitcast[UInt32]()
        self._overflow = (cq_mmap._address + Int(offsets._overflow)).bitcast[
            UInt32
        ]()
        self._cqes = (cq_mmap._address + Int(offsets._cqes)).bitcast[
            _CompletionQueueEntry
        ]()
        self._mask = self._ring_mask[]
        self._entries = self._ring_entries[]
        self._cq_mmap = cq_mmap^
