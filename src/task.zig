const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const print = std.debug.print;
const formatDate = @import("format_time.zig").formatDate;

const default_owner = @import("build_options").default_owner;

const Self = @This();

pub const Status = enum {
    TODO,
    DOING,
    DONE,
    CANCELED,
};

id: ?i64 = null,
title: ?[]const u8,
description: ?[]const u8,
owner: ?[]const u8 = default_owner,
requester: ?[]const u8 = null,
created_at: ?i64,
updated_at: ?i64,
started_at: ?i64 = null,
finished_at: ?i64 = null,
canceled_at: ?i64 = null,
status: ?Status = .TODO,

pub fn deinit(self: *Self, allocator: Allocator) void {
    if (self.title) |n| {
        allocator.free(n);
    }

    if (self.owner) |o| {
        allocator.free(o);
    }

    if (self.requester) |r| {
        allocator.free(r);
    }

    if (self.description) |d| {
        allocator.free(d);
    }
}

fn getTimeNow(io: Io) i64 {
    return std.Io.Timestamp.now(io, .real).toMilliseconds();
}

pub fn format(
    self: Self,
    writer: *Io.Writer,
) !void {
    var buf: [64]u8 = undefined;
    const time = formatDate(&buf, self.created_at.?) catch |err| {
        print("err: {any}\n", .{err});
        return;
    };
    try writer.print(
        "Task( title={s} | createdAt={s} | status={t} )",
        .{
            self.title.?,
            time,
            self.status.?,
        },
    );
}

pub fn newTask(io: Io, title: []const u8, description: ?[]const u8, requester: ?[]const u8) Self {
    const now = getTimeNow(io);
    return Self{
        .title = title,
        .description = description,
        .requester = requester,
        .created_at = now,
        .updated_at = now,
    };
}

pub fn startTask(self: *Self, io: Io) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.started_at = now;
    self.status = .DOING;
}

pub fn finishTask(self: *Self, io: Io) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.finished_at = now;
    self.status = .DONE;
}

pub fn cancelTask(self: *Self, io: Io) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.finished_at = now;
    self.status = .CANCELED;
}

pub fn updateTaskName(self: *Self, io: Io, task_name: []const u8) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.task_name = task_name;
}

pub fn updateTaskOwnner(self: *Self, io: Io, owner: []const u8) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.owner = owner;
}

pub fn updateTaskRequester(self: *Self, io: Io, requester: []const u8) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.requester = requester;
}

pub fn updateDescription(self: *Self, io: Io, description: []const u8) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.description = description;
}

pub fn updateTitle(self: *Self, io: Io, title: []const u8) void {
    const now = getTimeNow(io);
    self.updated_at = now;
    self.title = title;
}

test "Create new Task" {
    const testing = std.testing;
    const io = testing.io;

    const title = "First task";
    const description = "Description";
    const ownner = "Ramon";
    const requester = "Alam";

    const task = newTask(io, title, description, ownner, requester);

    try testing.expectEqualStrings(title, task.title.?);
    try testing.expectEqualStrings(description, task.description.?);
    try testing.expectEqualStrings(ownner, task.owner.?);
    try testing.expectEqualStrings(requester, task.requester.?);
}

test "Starting and finishing a task" {
    const testing = std.testing;
    const io = testing.io;

    var task = newTask(io, "First task", "Description", "Ramon", "Alam");

    try testing.expectEqual(Status.TODO, task.status.?);

    task.startTask(io);

    try testing.expectEqual(Status.DOING, task.status.?);

    task.finishTask(io);

    try testing.expectEqual(Status.DONE, task.status.?);

    task.status = .DOING;

    try task.cancelTask(io);

    try testing.expectEqual(Status.CANCELED, task.status.?);
}

test "Changing ownner and requester from task" {
    const testing = std.testing;
    const io = testing.io;

    var task = newTask(io, "First task", "Description", null, null);

    try testing.expect(task.owner == null);
    try testing.expect(task.requester == null);

    task.updateTaskOwnner(io, "Ramon");
    task.updateTaskRequester(io, "Alam");

    try testing.expect(task.owner != null);
    try testing.expectEqualStrings("Alam", task.requester.?);
}
