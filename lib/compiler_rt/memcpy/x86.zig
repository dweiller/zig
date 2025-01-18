pub var detection_done = false;
pub var has_fsrm = false;
pub var has_ermsb = false;

pub fn detectFeatures() void {
    const extended_features = cpuid(7, 0);
    has_ermsb = bit(extended_features.ebx, 9);
    has_fsrm = bit(extended_features.edx, 4);

    detection_done = true;
}

inline fn bit(input: u32, offset: u5) bool {
    return (input >> offset) & 1 != 0;
}

const cpuid = @import("../../std/zig/system/x86.zig").cpuid;

pub inline fn rep_movsb(dest: [*]u8, src: [*]const u8, count: usize) void {
    var d = dest;
    var s = src;
    var c = count;

    asm volatile ("rep movsb"
        : [_] "+{di}" (d),
          [_] "+{si}" (s),
          [_] "+{cx}" (c),
        :
        : "memory"
    );
}

comptime {
    assert(builtin.cpu.arch.isX86());
}

const builtin = @import("builtin");
const std = @import("std");
const assert = std.debug.assert;
