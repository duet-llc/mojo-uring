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
    # Userspace publishes the CQ head; the mmap-derived origin is untracked but
    # kept alive by _cq_mmap.
    var _khead: Pointer[Atomic[UInt32], MutUntrackedOrigin]
    # The kernel publishes the CQ tail, so userspace only needs immutable
    # access. Its untracked mmap origin is likewise owned by _cq_mmap.
    var _ktail: Pointer[Atomic[UInt32], ImmUntrackedOrigin]
    # CQEs are kernel-written and userspace-read; the owning mmap outlives this
    # immutable, untracked view.
    var _cqes: Pointer[_CompletionQueueEntry, ImmUntrackedOrigin]
    var _mask: UInt32
    var _cq_mmap: _Mmap
    var _head: UInt32

    def __init__(
        out self, var cq_mmap: _Mmap, offsets: _CompletionQueueRingOffsets
    ):
        self._khead = Pointer[Atomic[UInt32], MutUntrackedOrigin](
            unsafe_from_address=Int(
                cq_mmap._address.unsafe_offset(offsets._head)
            )
        )
        self._ktail = Pointer[Atomic[UInt32], ImmUntrackedOrigin](
            unsafe_from_address=Int(
                cq_mmap._address.unsafe_offset(offsets._tail)
            )
        )
        self._cqes = (
            cq_mmap._address.unsafe_offset(offsets._cqes)
            .as_imm()
            .unsafe_bitcast[_CompletionQueueEntry]()
        )
        # The ring mask is kernel-initialized and read-only after setup. The
        # mmap owner stored below makes its untracked origin valid.
        var ring_mask = Pointer[UInt32, ImmUntrackedOrigin](
            unsafe_from_address=Int(
                cq_mmap._address.unsafe_offset(offsets._ring_mask)
            )
        )
        self._mask = ring_mask[]
        self._cq_mmap = cq_mmap^
        self._head = 0
