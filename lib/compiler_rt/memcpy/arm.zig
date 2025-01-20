pub inline fn cpyfp_cpyfm_cpyfe(dest: [*]u8, src: [*]const u8, count: usize) void {
    var d = dest;
    var s = src;
    var c = count;

    asm volatile (
        \\cpyfp [%[Xd]], [%[Xs]], %[Xn]
        \\cpyfm [%[Xd]], [%[Xs]], %[Xn]
        \\cpyfe [%[Xd]], [%[Xs]], %[Xn]
        : [Xd] "+r" (d),
          [Xs] "+r" (s),
          [Xn] "+r" (c),
        :
        : "memory"
    );
}
