# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import (
    _CoroutineContext,
    _coro_resume_fn,
    _coro_resume_noop_callback,
)
from std.testing import TestSuite, assert_raises

from uring import Context, Params, Uring


def test_uring_success() raises:
    _ = Uring(128, Params())


def test_uring_invalid_entries() raises:
    with assert_raises(contains="Invalid argument"):
        _ = Uring(65536, Params())


def test_uring_nop_completion() raises:
    var io = Uring(8, Params())
    var ctx = Context()
    var co = io.nop(ctx)
    # RaisingCoroutine does not expose Coroutine._set_noop_callback.
    co._get_ctx[_CoroutineContext]()[]._resume_fn = _coro_resume_noop_callback
    _coro_resume_fn(co._handle)
    io._submit()
    io._complete()
    co^._unsafe_force_deinit()


def test_uring_nop_with_cancelation_compiles() raises:
    var io = Uring(8, Params())
    var ctx = Context[cancelable=True]()
    var co = io.nop(ctx)
    co^._unsafe_force_deinit()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)
