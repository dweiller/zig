const std = @import("std");
const assert = std.debug.assert;
const common = @import("./common.zig");
const builtin = @import("builtin");

comptime {
    if (builtin.object_format != .c) {
        @export(&memset, .{ .name = "memset", .linkage = common.linkage, .visibility = common.visibility });
        @export(&__memset, .{ .name = "__memset", .linkage = common.linkage, .visibility = common.visibility });
    }
}

const Element = common.PreferredLoadStoreElement;

comptime {
    assert(std.math.isPowerOfTwo(@sizeOf(Element)));
}

const memset = if (builtin.mode == .ReleaseSmall)
    memsetSmall
else
    memsetFast;

fn memsetSmall(dest: ?[*]u8, c: u8, len: usize) callconv(.c) ?[*]u8 {
    @setRuntimeSafety(builtin.is_test);
    @disableIntrinsics();

    for (dest.?[0..len]) |*d| {
        d.* = c;
    }

    return dest;
}

fn memsetFast(dest: ?[*]u8, c: u8, len: usize) callconv(.c) ?[*]u8 {
    @setRuntimeSafety(builtin.is_test);
    @disableIntrinsics();

    const small_limit = 2 * @sizeOf(Element);

    if (setSmallLength(small_limit, dest.?, c, len)) return dest;

    dest.?[0..@sizeOf(Element)].* = @splat(c);
    const alignment_offset = @alignOf(Element) - @intFromPtr(dest.?) % @alignOf(Element);
    const adjusted_len = len - alignment_offset;
    const aligned_dest: [*]Element = @ptrCast(@alignCast(dest.? + alignment_offset));

    const loop_count = adjusted_len / @sizeOf(Element);

    const value: Element = if (Element == usize)
        @bitCast(@as([@sizeOf(usize)]u8, @splat(c)))
    else
        @splat(c);
    for (aligned_dest[0..loop_count]) |*d| {
        d.* = value;
    }

    dest.?[len - @sizeOf(Element) ..][0..@sizeOf(Element)].* = @splat(c);

    return dest;
}

fn __memset(dest: ?[*]u8, c: u8, n: usize, dest_n: usize) callconv(.c) ?[*]u8 {
    if (dest_n < n)
        @panic("buffer overflow");
    return memset(dest, c, n);
}

inline fn setSmallLength(comptime small_limit: comptime_int, dest: [*]u8, c: u8, len: usize) bool {
    @setRuntimeSafety(builtin.is_test);
    @disableIntrinsics();

    if (len < 16) {
        if (len < 4) {
            if (len == 0) return true;
            dest[0] = c;
            dest[len / 2] = c;
            dest[len - 1] = c;
            return true;
        }
        setRange4(4, dest, c, len);
        return true;
    }

    inline for (3..(std.math.log2(small_limit) + 1) / 2 + 1) |p| {
        const limit = 1 << (2 * p);
        if (len < limit) {
            setRange4(limit / 4, dest, c, len);
            return true;
        }
    }
    return false;
}

/// set `len` bytes of `dest` to `c`; `len` must be in the range [min_len, 4 * min_len)`.
inline fn setRange4(
    comptime min_len: comptime_int,
    dest: [*]u8,
    c: u8,
    len: usize,
) void {
    @setRuntimeSafety(builtin.is_test);
    @disableIntrinsics();
    comptime assert(std.math.isPowerOfTwo(min_len));
    if (builtin.is_test) {
        assert(len >= min_len);
        assert(len < 4 * min_len);
    }

    const a = len & (min_len * 2);
    const b = a / 2;

    const last = len - min_len;
    const pen = last - b;

    dest[0..min_len].* = @splat(c);
    dest[b..][0..min_len].* = @splat(c);
    dest[pen..][0..min_len].* = @splat(c);
    dest[last..][0..min_len].* = @splat(c);
}

test memsetFast {
    const max_len = 1024;
    var dest: [max_len + @alignOf(Element) - 1]u8 align(@alignOf(Element)) = undefined;
    const expected: [max_len]u8 = @splat(0);

    for (0..max_len) |len| {
        for (0..@alignOf(Element)) |offset| {
            @disableIntrinsics();
            for (&dest) |*b| {
                b.* = 0xff;
            }
            const d = dest[offset..][0..len];
            _ = memsetFast(@ptrCast(d.ptr), 0, d.len);
            try std.testing.expectEqualSlices(u8, expected[0..len], d);
        }
    }
}
