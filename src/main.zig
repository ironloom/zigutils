const std = @import("std");
const Allocator = @import("std").mem.Allocator;

pub fn main() !void {
    std.log.debug("Hello World!", .{});
}
