pub fn ArrayListInline(comptime T: type) type {
    return ArrayListInlineGrowth(T, null, null);
}

pub fn ArrayListInlineUnmanaged(comptime T: type) type {
    return ArrayListInlineUnmanagedGrowth(T, null, null);
}

pub fn ArrayListInlineGrowth(
    comptime T: type,
    comptime inline_size: ?comptime_int,
    comptime growth: ?fn (usize, usize) usize,
) type {
    if (inline_size) |s| {
        if (s <= @sizeOf([]T) / @sizeOf(T)) {
            return ArrayListInlineGrowth(T, null, growth);
        }
    }

    return struct {
        const Self = @This();

        unmanaged: Unmanaged,
        allocator: Allocator,

        const Unmanaged = ArrayListInlineUnmanagedGrowth(T, inline_size, growth);

        pub fn init(allocator: Allocator) Self {
            return .{
                .unmanaged = .{},
                .allocator = allocator,
            };
        }

        pub fn initCapacity(allocator: Allocator, init_capacity: usize) Allocator.Error!Self {
            return .{
                .unmanaged = try Unmanaged.initCapacity(allocator, init_capacity),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.unmanaged.deinit(self.allocator);
        }

        pub fn toOwnedSlice(self: *Self) Allocator.Error![]T {
            return self.unmanaged.toOwnedSlice(self.allocator);
        }

        pub fn toOwnedSliceSentinel(self: *Self, comptime sentinel: T) Allocator.Error![:sentinel]T {
            return self.unmanaged.toOwnedSliceSentinel(self.allocator, sentinel);
        }

        pub fn inlineStorage(self: *Self) void {
            self.unmanaged.inlineStorage();
        }

        pub fn capacity(self: Self) usize {
            return self.unmanaged.capacity();
        }

        pub fn slice(self: Self) []T {
            return self.unmanaged.slice();
        }

        pub fn clone(self: Self) Allocator.Error!Self {
            return self.unmanaged.clone(self.allocator);
        }

        pub fn append(self: *Self, item: T) Allocator.Error!void {
            try self.unmanaged.append(self.allocator, item);
        }

        pub fn appendAssumeCapacity(self: *Self, item: T) void {
            self.unmanaged.appendAssumeCapacity(item);
        }

        pub fn swapRemove(self: *Self, i: usize) T {
            return self.unmanaged.swapRemove(i);
        }

        pub fn appendSlice(
            self: *Self,
            items: []const T,
        ) Allocator.Error!void {
            try self.unmanaged.appendSlice(self.allocator, items);
        }

        pub fn appendSliceAssumeCapacity(self: *Self, items: []const T) void {
            return self.unmanaged.appendSliceAssumeCapacity(items);
        }

        pub const WriterContext = struct {
            self: *Self,
        };

        pub const Writer = if (T != u8)
            @compileError("The Writer interface is only defined for SmallArrayListUnmanaged(u8) " ++
                "but the given type is SmallArrayListUnmanaged(" ++ @typeName(T) ++ ")")
        else
            std.io.Writer(WriterContext, Allocator.Error, appendWrite);

        pub fn writer(self: *Self) Writer {
            return .{ .context = .{ .self = self } };
        }

        fn appendWrite(context: WriterContext, m: []const u8) Allocator.Error!usize {
            try context.self.appendSlice(m);
            return m.len;
        }

        pub inline fn appendNTimes(
            self: *Self,
            value: T,
            n: usize,
        ) Allocator.Error!void {
            try self.unmanaged.appendNTimes(self.allocator, value, n);
        }

        pub inline fn appendNTimesAssumeCapacity(self: *Self, value: T, n: usize) void {
            self.unmanaged.appendNTimesAssumeCapacity(value, n);
        }

        pub fn resize(self: *Self, new_len: usize) Allocator.Error!void {
            try self.unmanaged.resize(self.allocator, new_len);
        }

        pub fn shrinkAndFree(self: *Self, new_len: usize) void {
            try self.unmanaged.shrinkAndFree(self.allocator, new_len);
        }

        pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void {
            self.unmanaged.shrinkRetainingCapacity(new_len);
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.unmanaged.clearRetainingCapacity();
        }

        pub fn clearAndFree(self: *Self) void {
            self.unmanaged.clearAndFree(self.allocator);
        }

        pub fn ensureTotalCapacity(
            self: *Self,
            new_capacity: usize,
        ) Allocator.Error!void {
            try self.unmanaged.ensureTotalCapacity(self.allocator, new_capacity);
        }

        pub fn ensureTotalCapacityPrecise(
            self: *Self,
            new_capacity: usize,
        ) Allocator.Error!void {
            try self.unmanaged.ensureTotalCapacityPrecise(self.allocator, new_capacity);
        }

        pub fn ensureUnusedCapacity(
            self: *Self,
            additional_count: usize,
        ) Allocator.Error!void {
            try self.unmanaged.ensureUnusedCapacity(self.allocator, additional_count);
        }

        pub fn expandToCapacity(self: *Self) void {
            self.unmanaged.expandToCapacity();
        }

        pub fn addOne(self: *Self) Allocator.Error!*T {
            return self.unmanaged.addOne(self.allocator);
        }

        pub fn addOneAssumeCapacity(self: *Self) Allocator.Error!*T {
            return self.unmanaged.addOneAssumeCapacity();
        }

        pub fn addManyAsArray(
            self: *Self,
            comptime n: usize,
        ) Allocator.Error!*[n]T {
            return self.unmanaged.addManyAsArray(self.allocator, n);
        }

        pub fn addManyAsArrayAssumeCapacity(self: *Self, comptime n: usize) *[n]T {
            return self.unmanaged.addManyAsArrayAssumeCapacity(n);
        }

        pub fn addManyAsSlice(self: *Self, n: usize) Allocator.Error![]T {
            return self.unmanaged.addManyAsSlice(self.allocator, n);
        }

        pub fn addManyAsSliceAssumeCapacity(self: *Self, n: usize) []T {
            return self.unmanaged.addManyAsSliceAssumeCapacity(n);
        }

        pub fn pop(self: *Self) T {
            return self.unmanaged.pop();
        }

        pub fn popOrNull(self: *Self) ?T {
            return self.unmanaged.popOrNull();
        }

        pub fn allocatedSlice(self: Self) []T {
            return self.unmanaged.allocatedSlice();
        }

        pub fn unusedCapacitySlice(self: Self) []T {
            return self.allocatedSlice()[self.info.len..];
        }

        pub fn getLast(self: Self) T {
            return self.unmanaged.getLast();
        }

        pub fn getLastOrNull(self: Self) ?T {
            return self.unmanaged.getLastOrNull();
        }
    };
}

pub fn ArrayListInlineUnmanagedGrowth(
    comptime T: type,
    comptime inline_size: ?comptime_int,
    comptime growth: ?fn (usize, usize) usize,
) type {
    if (inline_size) |s| {
        if (s <= @sizeOf([]T) / @sizeOf(T)) {
            return ArrayListInlineUnmanagedGrowth(T, null, growth);
        }
    }
    const small_size = inline_size orelse size: {
        const s = @sizeOf([]T) / @sizeOf(T);
        break :size if (s == 0) 8 else s;
    };

    return struct {
        const Self = @This();

        items: union {
            large: []T,
            small: [small_size]T,
        } = .{ .small = undefined },
        info: packed struct(usize) {
            is_small: bool = true,
            len: SizeInt = 0,
        } = .{},

        pub fn initCapacity(allocator: Allocator, init_capacity: usize) Allocator.Error!Self {
            assert(init_capacity <= std.math.maxInt(SizeInt));

            if (init_capacity <= small_size) return .{};

            return .{
                .items = .{ .large = try allocator.alloc(T, init_capacity) },
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            if (self.info.is_small) {
                return;
            }
            allocator.free(self.items.large.ptr[0..self.items.large.len]);
        }

        pub fn toOwnedSlice(self: *Self, allocator: Allocator) Allocator.Error![]T {
            const old_memory = self.allocatedSlice();
            if (allocator.resize(old_memory, self.info.len)) {
                const result = old_memory[0..self.info.len];
                self.* = .{};
                return result;
            }

            const new_memory = try allocator.alloc(T, self.info.len);
            @memcpy(new_memory, old_memory[0..self.info.len]);
            @memset(old_memory[0..self.info.len], undefined);
            self.clearAndFree(allocator);
            return new_memory;
        }

        pub fn toOwnedSliceSentinel(
            self: *Self,
            allocator: Allocator,
            comptime sentinel: T,
        ) Allocator.Error![:sentinel]T {
            try self.ensureTotalCapacityPrecise(allocator, try addOrOom(self.info.len, 1));
            self.appendAssumeCapacity(sentinel);
            const result = try self.toOwnedSlice(allocator);
            return result[0 .. result.len - 1 :sentinel];
        }

        pub fn inlineStorage(self: *Self) void {
            if (self.info.len <= small_size and !self.info.is_small) {
                @memcpy(self.items.small[0..self.info.len], self.items.large.ptr[0..self.info.len]);
            }
        }

        pub fn capacity(self: Self) usize {
            return if (self.info.is_small) small_size else self.items.large.len;
        }

        pub fn slice(self: Self) []T {
            return if (self.info.is_small)
                self.items.small[0..self.info.len]
            else
                self.items.large[0..self.info.len];
        }

        pub fn clone(self: Self, allocator: Allocator) Allocator.Error!Self {
            if (self.info.is_small) {
                return self;
            }
            const new_items = try allocator.alloc(T, self.items.large.len);
            @memcpy(new_items[0..self.info.len], self.items.large.ptr[0..self.info.len]);
            return .{
                .items = .{ .large = new_items },
                .info = self.info,
            };
        }

        pub fn append(self: *Self, allocator: Allocator, item: T) Allocator.Error!void {
            const ptr = try self.addOne(allocator);
            ptr.* = item;
        }

        pub fn appendAssumeCapacity(self: *Self, item: T) void {
            const ptr = self.addOneAssumeCapacity();
            ptr.* = item;
        }

        pub fn swapRemove(self: *Self, i: usize) T {
            assert(i < self.info.len);

            self.info.len -= 1;

            if (self.info.is_small) {
                const old_item = self.items.small[self.info.len];
                self.items.small[i] = old_item;
                return old_item;
            } else {
                const old_item = self.items.large.ptr[self.info.len];
                self.items.large.ptr[i] = old_item;
                return old_item;
            }
        }

        pub fn appendSlice(
            self: *Self,
            allocator: Allocator,
            items: []const T,
        ) Allocator.Error!void {
            try self.ensureUnusedCapacity(allocator, items.len);
            self.appendSliceAssumeCapacity(items);
        }

        pub fn appendSliceAssumeCapacity(self: *Self, items: []const T) void {
            const new_len = self.info.len + @as(SizeInt, @intCast(items.len));
            if (self.info.is_small) {
                assert(new_len <= small_size);
                @memcpy(self.items.small[self.info.len..][items.len], items);
            } else {
                assert(new_len <= self.items.large.len);
                @memcpy(self.items.large.ptr[self.info.len..][items.len], items);
            }
            self.info.len = new_len;
        }

        pub const WriterContext = struct {
            self: *Self,
            allocator: Allocator,
        };

        pub const Writer = if (T != u8)
            @compileError("The Writer interface is only defined for SmallArrayListUnmanaged(u8) " ++
                "but the given type is SmallArrayListUnmanaged(" ++ @typeName(T) ++ ")")
        else
            std.io.Writer(WriterContext, Allocator.Error, appendWrite);

        pub fn writer(self: *Self, allocator: Allocator) Writer {
            return .{ .context = .{ .self = self, .allocator = allocator } };
        }

        fn appendWrite(context: WriterContext, m: []const u8) Allocator.Error!usize {
            try context.self.appendSlice(context.allocator, m);
            return m.len;
        }

        pub inline fn appendNTimes(
            self: *Self,
            allocator: Allocator,
            value: T,
            n: usize,
        ) Allocator.Error!void {
            const old_len = self.info.len;
            try self.resize(allocator, try addOrOom(old_len, n));
            @memset(self.slice()[old_len..self.info.len], value);
        }

        pub inline fn appendNTimesAssumeCapacity(self: *Self, value: T, n: usize) void {
            const new_len = self.info.len + n;
            assert(new_len <= self.capacity());
            @memset(self.slice().ptr[self.info.len..new_len], value);
            self.info.len = @intCast(new_len);
        }

        pub fn resize(self: *Self, allocator: Allocator, new_len: usize) Allocator.Error!void {
            try self.ensureTotalCapacity(allocator, new_len);
            self.info.len = @intCast(new_len);
        }

        pub fn shrinkAndFree(self: *Self, allocator: Allocator, new_len: usize) void {
            assert(new_len <= self.info.len);

            self.info.len = @intCast(new_len);
            if (self.info.is_small) return;

            if (@sizeOf(T) == 0) {
                self.items.large.len = new_len;
                return;
            }

            if (new_len <= small_size) {
                @memcpy(self.items.small[0..new_len], self.items.large[0..new_len]);
                self.info.is_small = true;
                return;
            }

            if (allocator.resize(self.items.large, new_len)) {
                self.items.large.len = new_len;
                return;
            }

            const new_memory = allocator.alloc(T, new_len) catch |err| switch (err) {
                error.OutOfMemory => return,
            };

            @memcpy(new_memory, self.items.large[0..new_len]);
            allocator.free(self.items.large);
            self.items.large = new_memory;
        }

        pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void {
            assert(new_len <= self.info.len);
            self.info.len = @intCast(new_len);
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.info.len = 0;
        }

        pub fn clearAndFree(self: *Self, allocator: Allocator) void {
            if (self.info.is_small) {
                self.info.len = 0;
                return;
            }

            allocator.free(self.items.large);
            self.info.is_small = false;
            self.info.len = 0;
        }

        pub fn ensureTotalCapacity(
            self: *Self,
            allocator: Allocator,
            new_capacity: usize,
        ) Allocator.Error!void {
            assert(new_capacity <= std.math.maxInt(SizeInt));

            const c = self.capacity();
            if (c >= new_capacity) return;

            if (self.info.is_small) {
                if (new_capacity <= small_size) return;
            }

            const better_capacity = growCapacity(c, new_capacity);
            return self.ensureTotalCapacityPrecise(allocator, better_capacity);
        }

        pub fn ensureTotalCapacityPrecise(
            self: *Self,
            allocator: Allocator,
            new_capacity: usize,
        ) Allocator.Error!void {
            assert(new_capacity <= std.math.maxInt(SizeInt));

            if (self.info.is_small) {
                if (new_capacity <= small_size) return;

                if (@sizeOf(T) == 0) {
                    self.items.large.ptr = comptime std.mem.alignBackward(
                        usize,
                        std.math.maxInt(usize),
                        @alignOf(T),
                    );
                    self.items.large.len = new_capacity;
                    return;
                }

                const memory = try allocator.alloc(T, new_capacity);
                @memcpy(memory[0..self.info.len], self.items.small[0..self.info.len]);
                self.items.large = memory;
            }

            if (self.items.large.len >= new_capacity) return;

            if (@sizeOf(T) == 0) {
                self.items.large.len = new_capacity;
                return;
            }

            if (allocator.resize(self.items.large, new_capacity)) {
                self.items.large.len = new_capacity;
            } else {
                const new_memory = try allocator.alloc(T, new_capacity);
                @memcpy(new_memory[0..self.info.len], self.items.large[0..self.info.len]);
                allocator.free(self.items.large);
                self.items.large = new_memory;
            }
        }

        pub fn ensureUnusedCapacity(
            self: *Self,
            allocator: Allocator,
            additional_count: usize,
        ) Allocator.Error!void {
            assert(additional_count <= std.math.maxInt(SizeInt));
            const new_capacity = try addOrOom(self.info.len, @intCast(additional_count));
            return self.ensureTotalCapacity(allocator, new_capacity);
        }

        pub fn expandToCapacity(self: *Self) void {
            if (self.info.is_small) {
                self.info.len = small_size;
            } else {
                self.info.len = @intCast(self.items.large.len);
            }
        }

        pub fn addOne(self: *Self, allocator: Allocator) Allocator.Error!*T {
            // TODO: can we skip the error checking of `ensureUnusedCapacity()`?
            try self.ensureUnusedCapacity(allocator, 1);
            return self.addOneAssumeCapacity();
        }

        pub fn addOneAssumeCapacity(self: *Self) Allocator.Error!*T {
            defer self.info.len += 1;

            if (self.info.is_small) {
                return &self.items.small[self.info.len];
            }
            return &self.items.large[self.info.len];
        }

        pub fn addManyAsArray(
            self: *Self,
            allocator: Allocator,
            comptime n: usize,
        ) Allocator.Error!*[n]T {
            try self.ensureUnusedCapacity(allocator, n);
            self.addManyAsArrayAssumeCapacity(allocator, n);
        }

        pub fn addManyAsArrayAssumeCapacity(self: *Self, comptime n: usize) *[n]T {
            assert(self.info.len + n <= self.capacity());
            defer self.info.len += @intCast(n);

            if (self.info.is_small) {
                return self.items.small[self.info.len..][0..n];
            }
            return self.items.large[self.info.len..][0..n];
        }

        pub fn addManyAsSlice(self: *Self, allocator: Allocator, n: usize) Allocator.Error![]T {
            try self.ensureUnusedCapacity(allocator, n);
            return self.addManyAsSliceAssumeCapacity(self, n);
        }

        pub fn addManyAsSliceAssumeCapacity(self: *Self, n: usize) []T {
            assert(self.info.len + n <= self.capacity());
            defer self.info.len += @intCast(n);

            if (self.info.is_small) {
                return self.items.small[self.info.len..][0..n];
            }
            return self.items.large[self.info.len..][0..n];
        }

        pub fn pop(self: *Self) T {
            assert(self.info.len != 0);
            self.info.len -= 1;
            return self.slice()[self.info.len];
        }

        pub fn popOrNull(self: *Self) ?T {
            if (self.info.len == 0) return null;
            return self.pop();
        }

        pub fn allocatedSlice(self: *Self) []T {
            if (self.info.is_small) {
                return &self.items.small;
            }
            return self.items.large;
        }

        pub fn unusedCapacitySlice(self: Self) []T {
            return self.allocatedSlice()[self.info.len..];
        }

        pub fn getLast(self: Self) T {
            if (self.info.is_small) {
                return self.items.small[self.info.len - 1];
            }
            return self.items.large[self.info.len - 1];
        }

        pub fn getLastOrNull(self: Self) ?T {
            if (self.info.len == 0) return null;
            return self.getLast();
        }

        fn growCapacity(current_capacity: usize, new_capacity: usize) usize {
            const result = if (growth) |func|
                func(current_capacity, new_capacity)
            else result: {
                var res: usize = current_capacity;
                while (res < new_capacity) {
                    res += res / 2;
                }
                break :result res;
            };

            assert(result <= std.math.maxInt(SizeInt));
            return result;
        }
    };
}

pub const SizeInt = @Type(.{ .Int = .{
    .signedness = .unsigned,
    .bits = @bitSizeOf(usize) - 1,
} });

fn addOrOom(a: SizeInt, b: SizeInt) error{OutOfMemory}!SizeInt {
    const result, const overflow = @addWithOverflow(a, b);
    if (overflow != 0) return error.OutOfMemory;
    return result;
}

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
