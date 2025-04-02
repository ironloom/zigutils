const std = @import("std");
const Allocator = @import("std").mem.Allocator;

/// # coerceTo
/// The quick way to change types for ints, floats, booleans, enums and pointers.
/// Currently:
/// - `int`, `comptime_int` can be cast to:
///     - other `int` types (e.g. `i32` -> `i64`)
///     - `float`
///     - `bool`
///     - `enum`
///     - `pointer` (this case the input integer is taken as the address)
/// - `float`, `comptime_float` can be cast to:
///     - `int`
///     - other `float` types
///     - `bool`
///     - `enum`
/// - `bool` can be cast to:
///     - `int`
///     - `float`
///     - `bool`
///     - `enum`
/// - `enum` can be cast to:
///     - `int`
///     - `float`
///     - `bool`
///     - other `enum` types
/// - `pointer` can be cast to:
///     - `int`, the address will become the int's value
///     - other `pointer` types (e.g. `*anyopaque` -> `*i32`)
pub inline fn coerceTo(comptime TypeTarget: type, value: anytype) ?TypeTarget {
    const value_info = @typeInfo(@TypeOf(value));
    return switch (@typeInfo(TypeTarget)) {
        .int, .comptime_int => switch (value_info) {
            .int, .comptime_int => @as(TypeTarget, @intCast(value)),
            .float, .comptime_float => @as(TypeTarget, @intFromFloat(@round(value))),
            .bool => @as(TypeTarget, @intFromBool(value)),
            .@"enum" => @as(TypeTarget, @intFromEnum(value)),
            .pointer => @intFromPtr(value),
            else => null,
        },
        .float, .comptime_float => switch (value_info) {
            .int, .comptime_int => @as(TypeTarget, @floatFromInt(value)),
            .float, .comptime_float => @as(TypeTarget, @floatCast(value)),
            .bool => @as(TypeTarget, @floatFromInt(@intFromBool(value))),
            .@"enum" => @as(TypeTarget, @floatFromInt(@intFromEnum(value))),
            .pointer => @as(TypeTarget, @floatFromInt(@as(usize, @intFromPtr(value)))),
            else => null,
        },
        .bool => switch (value_info) {
            .int, .comptime_int => value != 0,
            .float, .comptime_float => @as(isize, @intFromFloat(@round(value))) != 0,
            .bool => value,
            .@"enum" => @as(isize, @intFromEnum(value)) != 0,
            .pointer => @as(usize, @intFromPtr(value)) != 0,
            else => null,
        },
        .@"enum" => switch (value_info) {
            .int, .comptime_int => @enumFromInt(value),
            .float, .comptime_float => @enumFromInt(@as(isize, @intFromFloat(@round(value)))),
            .bool => @enumFromInt(@intFromBool(value)),
            .@"enum" => @enumFromInt(@as(isize, @intFromEnum(value))),
            .pointer => @enumFromInt(@as(usize, @intFromPtr(value))),
            else => null,
        },
        .pointer => switch (value_info) {
            .int, .comptime_int => @ptrCast(@alignCast(@as(*anyopaque, @ptrFromInt(value)))),
            .float, .comptime_float => @compileError("Cannot convert float to pointer address"),
            .bool => @compileError("Cannot convert bool to pointer address"),
            .@"enum" => @compileError("Cannot convert enum to pointer address"),
            .pointer => @ptrCast(@alignCast(value)),
            else => null,
        },
        else => Catch: {
            std.log.warn(
                "cannot change type of \"{any}\" to type \"{any}\" (fyr.changeType())",
                .{ value, TypeTarget },
            );
            break :Catch null;
        },
    };
}

pub inline fn tof32(value: anytype) f32 {
    return coerceTo(f32, value) orelse 0;
}

pub inline fn tof64(value: anytype) f64 {
    return coerceTo(f64, value) orelse 0;
}

pub inline fn toi32(value: anytype) i32 {
    return coerceTo(i32, value) orelse 0;
}

pub inline fn toisize(value: anytype) isize {
    return coerceTo(isize, value) orelse 0;
}

pub inline fn tousize(value: anytype) usize {
    return coerceTo(usize, value) orelse 0;
}

pub inline fn toc_int(value: anytype) c_int {
    return coerceTo(c_int, value) orelse 0;
}

pub inline fn toc_long(value: anytype) c_int {
    return coerceTo(c_long, value) orelse 0;
}

pub inline fn NULL(comptime BASE_POINTER_TYPE: type) BASE_POINTER_TYPE {
    return @ptrFromInt(@as(c_int, 0));
}

inline fn isNull(ptr: anytype) bool {
    return switch (@typeInfo(@TypeOf(ptr))) {
        .pointer => @intFromPtr(ptr) == 0,
        .null => true,
        else => false,
    };
}

inline fn PtrCast(comptime TARGET: type, ptr: anytype) TARGET {
    return coerceTo(TARGET, ptr) orelse NULL(TARGET);
}
