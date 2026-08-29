const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const print = std.debug.print;

const Self = @This();

pub const Status = enum {
    TODO,
    DOING,
    DONE,
};

id: ?i64 = null,
task_name: ?[]const u8,
owner: ?[]const u8 = null,
requester: ?[]const u8 = null,
created_at: i64,
updated_at: i64,
started_at: ?i64 = null,
finished_at: ?i64 = null,
status: ?Status = .TODO,

pub fn deinit(self: *Self, allocator: Allocator) void {
    if (self.task_name) |n| {
        allocator.free(n);
    }

    if (self.owner) |o| {
        allocator.free(o);
    }

    if (self.requester) |r| {
        allocator.free(r);
    }
}

fn getTimeNow(io: Io) i64 {
    return std.Io.Timestamp.now(io, .real).toMilliseconds();
}

pub fn format(
    self: Self,
    writer: *Io.Writer,
) !void {
    try writer.print(
        "Task( name={s} | createdAt={d} | status={t} )",
        .{
            self.task_name.?,
            self.created_at,
            self.status.?,
        },
    );
}

pub fn newTask(io: Io, task_name: []const u8, owner: ?[]const u8, requester: ?[]const u8) Self {
    const now = getTimeNow(io);
    return Self{
        .task_name = task_name,
        .owner = owner,
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

test "Create new Task" {
    const testing = std.testing;
    const io = testing.io;

    const task_name = "First task";
    const ownner = "Ramon";
    const requester = "Alam";

    const task = newTask(io, task_name, ownner, requester);

    try testing.expectEqualStrings(task_name, task.task_name);
    try testing.expectEqualStrings(ownner, task.owner.?);
    try testing.expectEqualStrings(requester, task.requester.?);
}

test "Starting and finishing a task" {
    const testing = std.testing;
    const io = testing.io;

    var task = newTask(io, "First task", "Ramon", "Alam");

    try testing.expectEqual(Status.TODO, task.status);

    task.startTask(io);

    try testing.expectEqual(Status.DOING, task.status);

    task.finishTask(io);

    try testing.expectEqual(Status.DONE, task.status);
}

test "Changing ownner and requester from task" {
    const testing = std.testing;
    const io = testing.io;

    var task = newTask(io, "First task", null, null);

    try testing.expect(task.owner == null);
    try testing.expect(task.requester == null);

    task.updateTaskOwnner(io, "Ramon");
    task.updateTaskRequester(io, "Alam");

    try testing.expect(task.owner != null);
    try testing.expectEqualStrings("Alam", task.requester.?);
}
