# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

        var errno: ErrNo
                errno = ErrNo(
                    c_int(
                        -inlined_assembly[
                            "syscall",
                            c_long,
                            c_long,
                            c_int,
                            constraints="={rax},{rax},{rdi},~{rcx},~{r11},~{memory}",
                        ](3, self._value)
                    )
                )
                errno = ErrNo(
                    c_int(
                        -inlined_assembly[
                            "svc #0",
                            c_long,
                            c_long,
                            c_int,
                            constraints="={x0},{x8},{x0},~{memory}",
                        ](57, self._value)
                    )
                )

            if errno == ErrNo.EINTR:
                continue
            break

        debug_assert[assert_mode="safe"](errno == ErrNo.SUCCESS, errno)
                    "syscall",
                    c_long,
                    c_long,
                    c_int,
                    constraints="={rax},{rax},{rdi},~{rcx},~{r11},~{memory}",
                ](3, self._value)
            elif is_triple["aarch64-unknown-linux-gnu"]():
                result = inlined_assembly[
                    "svc #0",
                    c_long,
                    c_long,
                    c_int,
                    constraints="={x0},{x8},{x0},~{memory}",
                ](57, self._value)
            else:
                CompilationTarget.unsupported_target_error()

            errno = get_errno()
            if result != -1 or errno != ErrNo.EINTR:
                break

        debug_assert[assert_mode="safe"](result == 0, errno)
