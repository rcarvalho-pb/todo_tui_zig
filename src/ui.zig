const std = @import("std");
const Allocator = std.mem.Allocator;

const vaxis = @import("vaxis");
const Database = @import("database.zig");
const Task = @import("task.zig");

const Context = struct {
    db: *Database,
    allocator: Allocator,
    should_quit: bool = false,
    selected_tab: usize = 0,
    tasks: []Task = &.{},
    cursor: usize = 0,
};

const Message = union(enum) {
    event: vaxis.Event,
    redraw,
};

pub fn runTui(allocator: Allocator, db: *Database) !void {
    var vx = try vaxis.init(allocator, .{});
    defer vx.deinit(allocator);

    var loop: vaxis.Loop(Message) = .{ .vaxis = vx };
    try loop.init();
}
