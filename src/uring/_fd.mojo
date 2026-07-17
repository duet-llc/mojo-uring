# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.ffi import c_int, external_call


@fieldwise_init
struct _FileDescriptor(Movable):
    var _value: c_int

    def __del__(deinit self):
        _ = external_call["close", c_int, c_int](self._value)
