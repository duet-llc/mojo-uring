# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.atomic import Atomic, Ordering

from ._mmap import _Mmap
from ._params import _CompletionQueueRingOffsets


@align(8)
struct _CompletionQueueEntry:
    var _user_data: UInt64
    var _res: Int32
    var _flags: UInt32


struct _CompletionQueueIterator(Iterator, Movable):
    comptime Element = UnsafePointer[_CompletionQueueEntry, ImmUntrackedOrigin]

    var _khead: UnsafePointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _ktail: UnsafePointer[Atomic[DType.uint32], ImmUntrackedOrigin]
    var _cqes: UnsafePointer[_CompletionQueueEntry, ImmUntrackedOrigin]
    var _mask: UInt32
    var _head: UInt32
    var _tail: UInt32

    def __init__(
        out self,
        khead: UnsafePointer[Atomic[DType.uint32], MutUntrackedOrigin],
        ktail: UnsafePointer[Atomic[DType.uint32], ImmUntrackedOrigin],
        cqes: UnsafePointer[_CompletionQueueEntry, ImmUntrackedOrigin],
        mask: UInt32,
    ):
        self._khead = khead
        self._ktail = ktail
        self._cqes = cqes
        self._mask = mask
        self._head = UInt32(khead[].value)
        self._tail = UInt32(ktail[].load[ordering=Ordering.ACQUIRE]())

    def __next__(mut self) raises StopIteration -> Self.Element:
        if self._head == self._tail:
            self._tail = UInt32(self._ktail[].load[ordering=Ordering.ACQUIRE]())
            if self._head == self._tail:
                raise StopIteration()
            return self.__next__()

        var cqe = self._cqes + Int(self._head & self._mask)
        self._head += 1
        return cqe

    def __del__(deinit self):
        self._khead[].store[ordering=Ordering.RELEASE](self._head)


struct _CompletionQueue(Iterable, Movable):
    comptime IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[mut=iterable_mut]
    ]: Iterator = _CompletionQueueIterator

    var _khead: UnsafePointer[Atomic[DType.uint32], MutUntrackedOrigin]
    var _ktail: UnsafePointer[Atomic[DType.uint32], ImmUntrackedOrigin]
    var _cqes: UnsafePointer[_CompletionQueueEntry, ImmUntrackedOrigin]
    var _mask: UInt32
    var _cq_mmap: _Mmap

    def __init__(
        out self, var cq_mmap: _Mmap, offsets: _CompletionQueueRingOffsets
    ):
        self._khead = (cq_mmap._address + Int(offsets._head)).bitcast[
            Atomic[DType.uint32]
        ]()
        self._ktail = (
            (cq_mmap._address + Int(offsets._tail))
            .unsafe_mut_cast[False]()
            .bitcast[Atomic[DType.uint32]]()
        )
        self._cqes = (
            (cq_mmap._address + Int(offsets._cqes))
            .unsafe_mut_cast[False]()
            .bitcast[_CompletionQueueEntry]()
        )
        var ring_mask = (cq_mmap._address + Int(offsets._ring_mask)).bitcast[
            UInt32
        ]()
        self._mask = ring_mask[]
        self._cq_mmap = cq_mmap^

    def __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        return _CompletionQueueIterator(
            self._khead, self._ktail, self._cqes, self._mask
        )
