# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.testing import (
    TestSuite,
    assert_false,
    assert_raises,
    assert_true,
)

from uring import Context


def _cancel(ref ctx: Context) raises:
    try:
        ctx.cancel()
    except:
        raise Error("_Canceled")


def test_context_default() raises:
    var ctx = Context()
    assert_false(ctx.canceled())


def test_context_cancel() raises:
    var ctx = Context()
    _cancel(ctx)
    assert_true(ctx.canceled())


def test_context_cancel_twice() raises:
    var ctx = Context()
    _cancel(ctx)
    with assert_raises(contains="_Canceled"):
        _cancel(ctx)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)
