pub inline fn rep_movsb(dest: [*]u8, src: [*]const u8, count: usize) void {
    asm volatile ("rep movsb"
        :
        : [_] "{di}" (dest),
          [_] "{si}" (src),
          [_] "{cx}" (count),
        : .{ .memory = true });
}

pub inline fn rep_stosb(dest: [*]u8, value: u8, count: usize) void {
    asm volatile ("rep stosb"
        :
        : [_] "{di}" (dest),
          [_] "{ax}" (value),
          [_] "{cx}" (count),
        : .{ .memory = true });
}

comptime {
    assert(builtin.cpu.arch.isX86());
}

const builtin = @import("builtin");
const std = @import("std");
const assert = std.debug.assert;
