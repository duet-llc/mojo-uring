# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.atomic import Atomic

from ._mmap import _Mmap
from ._params import _CompletionQueueRingOffsets


@align(8)
struct _CompletionQueueEntry:
    var _user_data: UInt64
    var _res: Int32
    var _flags: UInt32


struct _CompletionQueue(Movable):
    var _khead: Pointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _ktail: Pointer[Atomic[DType.uint32], ImmUntrackedOrigin]
    var _cqes: UnsafePointer[_CompletionQueueEntry, ImmUntrackedOrigin]
    var _mask: UInt32
    var _cq_mmap: _Mmap
    var _head: UInt32

    def __init__(
        out self, var cq_mmap: _Mmap, offsets: _CompletionQueueRingOffsets
    ):
        self._khead = Pointer[Atomic[DType.uint32], MutUntrackedOrigin](
            unsafe_from_address=Int(cq_mmap._address + offsets._head)
        )
        self._ktail = Pointer[Atomic[DType.uint32], ImmUntrackedOrigin](
            unsafe_from_address=Int(cq_mmap._address + offsets._tail)
        )
        self._cqes = (
            (cq_mmap._address + offsets._cqes)
            .as_imm()
            .bitcast[_CompletionQueueEntry]()
        )
        var ring_mask = Pointer[UInt32, ImmUntrackedOrigin](
            unsafe_from_address=Int(cq_mmap._address + offsets._ring_mask)
        )
        self._mask = ring_mask[]
        self._cq_mmap = cq_mmap^
        self._head = 0
