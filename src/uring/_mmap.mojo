# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import ErrNo, c_int, c_long, c_size_t, external_call, get_errno

from ._fd import _FileDescriptor


comptime _PROT_READ_WRITE = 0x3
comptime _MAP_SHARED_POPULATE = 0x8001


struct _Mmap(Movable):
    # Ring mappings are written by both userspace and the kernel, so the view is
    # mutable. The origin is untracked because this RAII type owns the mapping.
    var _address: Pointer[UInt8, MutUntrackedOrigin]
    var _length: c_size_t

    def __init__(
        out self, length: c_size_t, fd: _FileDescriptor, offset: c_long
    ) raises ErrNo:
        # mmap creates owned mutable storage with no Mojo-tracked origin; this
        # object establishes its validity until __deinit__ calls munmap.
        var address = external_call[
            "mmap",
            Pointer[UInt8, MutUntrackedOrigin],
            Optional[Pointer[UInt8, MutUntrackedOrigin]],
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

    def __deinit__(deinit self):
        # munmap only consumes the address value; retaining the mutable pointer
        # type matches the mapping returned by mmap and does not extend its use.
        _ = external_call[
            "munmap", c_int, Pointer[UInt8, MutUntrackedOrigin], c_size_t
        ](self._address, self._length)
