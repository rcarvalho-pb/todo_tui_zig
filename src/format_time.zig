const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn formatDurationMs(allocator: Allocator, ms: i64) ![]u8 {
    if (ms < 0) return try allocator.dupe(u8, "00:00:00");

    const total_seconds: u64 = @intCast(@divTrunc(ms, 1000));

    const seconds = total_seconds % 60;
    const total_minutes = total_seconds / 60;
    const minutes = total_minutes % 60;
    const total_hours = total_minutes / 60;

    if (total_hours < 24) {
        return try std.fmt.allocPrint(allocator, "{d:0>2}:{d:0>2}:{d:0>2}", .{ total_hours, minutes, seconds });
    }

    const days = total_hours / 24;
    const hours = total_hours % 24;

    return try std.fmt.allocPrint(allocator, "{d}d {d:0>2}:{d:0>2}:{d:0>2}", .{ days, hours, minutes, seconds });
}
