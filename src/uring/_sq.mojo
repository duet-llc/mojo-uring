# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.atomic import Atomic

from ._mmap import _Mmap
from ._params import _SubmissionQueueRingOffsets


@align(8)
struct _SubmissionQueueEntry:
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
    var _pad2: Array[UInt64, 2]

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
        self._pad2 = Array[UInt64, 2](fill=0)


struct _SubmissionQueue(Movable):
    var _ktail: Pointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _sqes: UnsafePointer[_SubmissionQueueEntry, MutUntrackedOrigin]
    var _mask: UInt32
    var _sq_mmap: _Mmap
    var _sqes_mmap: _Mmap
    var _head: UInt32
    var _tail: UInt32

    def __init__(
        out self,
        var sq_mmap: _Mmap,
        var sqes_mmap: _Mmap,
        offsets: _SubmissionQueueRingOffsets,
    ):
        self._ktail = Pointer[Atomic[DType.uint32], MutUntrackedOrigin](
            unsafe_from_address=Int(sq_mmap._address + offsets._tail)
        )
        var array = (sq_mmap._address + offsets._array).bitcast[UInt32]()
        self._sqes = sqes_mmap._address.bitcast[_SubmissionQueueEntry]()
        var ring_mask = Pointer[UInt32, ImmUntrackedOrigin](
            unsafe_from_address=Int(sq_mmap._address + offsets._ring_mask)
        )
        self._mask = ring_mask[]
        for index in range(self._mask + 1):
            array[index] = index
        self._sq_mmap = sq_mmap^
        self._sqes_mmap = sqes_mmap^
        self._head = 0
        self._tail = 0
