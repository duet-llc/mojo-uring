# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import c_int, c_long, c_size_t, external_call, get_errno

from ._fd import _FileDescriptor


comptime _PROT_READ_WRITE = 0x3
comptime _MAP_SHARED_POPULATE = 0x8001


struct _Mmap(Movable):
    var _address: UnsafePointer[UInt8, MutUntrackedOrigin]
    var _length: c_size_t

    def __init__(
        out self, length: c_size_t, fd: _FileDescriptor, offset: c_long
    ) raises:
        var address = external_call[
            "mmap",
            UnsafePointer[UInt8, MutUntrackedOrigin],
            Optional[UnsafePointer[UInt8, MutUntrackedOrigin]],
            c_size_t,
            c_int,
            c_int,
            c_int,
            c_long,
        ](
            None,
            length,
            _PROT_READ_WRITE,
            _MAP_SHARED_POPULATE,
            fd._value,
            offset,
        )
        if Int(address) == -1:
            raise get_errno()
        self._address = address
        self._length = length

    def __del__(deinit self):
        _ = external_call[
            "munmap", c_int, UnsafePointer[UInt8, MutUntrackedOrigin], c_size_t
        ](self._address, self._length)
