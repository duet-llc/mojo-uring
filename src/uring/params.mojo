# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0


from std.collections import InlineArray


@align(8)
struct _SubmissionQueueRingOffsets:
    var _head: UInt32
    var _tail: UInt32
    var _ring_mask: UInt32
    var _ring_entries: UInt32
    var _flags: UInt32
    var _dropped: UInt32
    var _array: UInt32
    var _resv1: UInt32
    var _user_addr: UInt64

    def __init__(out self):
        self._head = 0
        self._tail = 0
        self._ring_mask = 0
        self._ring_entries = 0
        self._flags = 0
        self._dropped = 0
        self._array = 0
        self._resv1 = 0
        self._user_addr = 0


@align(8)
struct _CompletionQueueRingOffsets:
    var _head: UInt32
    var _tail: UInt32
    var _ring_mask: UInt32
    var _ring_entries: UInt32
    var _overflow: UInt32
    var _cqes: UInt32
    var _flags: UInt32
    var _resv1: UInt32
    var _user_addr: UInt64

    def __init__(out self):
        self._head = 0
        self._tail = 0
        self._ring_mask = 0
        self._ring_entries = 0
        self._overflow = 0
        self._cqes = 0
        self._flags = 0
        self._resv1 = 0
        self._user_addr = 0


@align(8)
struct Params:
    var _sq_entries: UInt32
    var _cq_entries: UInt32
    var _flags: UInt32
    var _sq_thread_cpu: UInt32
    var _sq_thread_idle: UInt32
    var _features: UInt32
    var _wq_fd: UInt32
    var _resv: InlineArray[UInt32, 3]
    var _sq_off: _SubmissionQueueRingOffsets
    var _cq_off: _CompletionQueueRingOffsets

    def __init__(out self):
        self._sq_entries = 0
        self._cq_entries = 0
        self._flags = 0
        self._sq_thread_cpu = 0
        self._sq_thread_idle = 0
        self._features = 0
        self._wq_fd = 0
        self._resv = InlineArray[UInt32, 3](fill=0)
        self._sq_off = _SubmissionQueueRingOffsets()
        self._cq_off = _CompletionQueueRingOffsets()
