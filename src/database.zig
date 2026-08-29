const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const Task = @import("task.zig");

const Self = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const GroupCount = struct {
    name: []const u8,
    count: usize,

    pub fn deinit(self: GroupCount, allocator: Allocator) void {
        allocator.free(self.name);
    }
};

const VTable = struct {
    createTable: *const fn (ctx: *anyopaque) anyerror!void,
    createTask: *const fn (ctx: *anyopaque, task: Task) anyerror!i64,
    updateTask: *const fn (ctx: *anyopaque, task: Task) anyerror!void,
    findTasks: *const fn (ctx: *anyopaque, flag: u3) anyerror![]Task,
    countActiveTasks: *const fn (ctx: *anyopaque) anyerror!usize,
    countAllStartedTasks: *const fn (ctx: *anyopaque) anyerror!usize,
    countFinishedTasks: *const fn (ctx: *anyopaque) anyerror!usize,
    getAvarageCompletionTimeMs: *const fn (ctx: *anyopaque) anyerror!?f64,
    getMaxCompletionTimeMs: *const fn (ctx: *anyopaque) anyerror!?i64,
    getMinCompletionTimeMs: *const fn (ctx: *anyopaque) anyerror!?i64,
    countTasksByOwner: *const fn (allocator: Allocator, ctx: *anyopaque) anyerror![]GroupCount,
    countTasksByRequester: *const fn (allocator: Allocator, ctx: *anyopaque) anyerror![]GroupCount,
    getAverageWaitTimeMs: *const fn(ctx: *anyopaque) anyerror!?f64,
    getAverageLeadTimeMs: *const fn(ctx: *anyopaque) anyerror!?f64,
};

pub fn createTable(self: Self) !void {
    return self.vtable.createTable(self.ptr);
}

pub fn createTask(self: Self, task: Task) !i64 {
    return self.vtable.createTask(self.ptr, task);
}

pub fn updateTask(self: Self, task: Task) !i64 {
    return self.vtable.createTask(self.ptr, task);
}

pub fn findTasks(self: Self, flag: u3) ![]Task {
    return self.vtable.findTasks(self.ptr, flag);
}

pub fn countActiveTasks(self: Self) !usize {
    return self.vtable.countActiveTasks(self.ptr);
}

pub fn countAllStartedTasks(self: Self) !usize {
    return self.vtable.countAllStartedTasks(self.ptr);
}

pub fn countFinishedTasks(self: Self) !usize {
    return self.vtable.countFinishedTasks(self.ptr);
}

pub fn getAverageCompletionTimeMs(self: Self) !?f64 {
    return self.vtable.getAvarageCompletionTimeMs(self.ptr);
}

pub fn getMaxCompletionTimeMs(self: Self) !?i64 {
    return self.vtable.getMaxCompletionTimeMs(self.ptr);
}

pub fn getMinCompletionTimeMs(self: Self) !?i64 {
    return self.vtable.getMinCompletionTimeMs(self.ptr);
}

pub fn countTasksByOwner(self: Self, allocator: Allocator) ![]GroupCount {
    return self.vtable.countTasksByOwner(allocator, self.ptr);
}

pub fn countTasksByRequester(self: Self, allocator: Allocator) ![]GroupCount {
    return self.vtable.countTasksByRequester(allocator, self.ptr);
}

pub fn getAverageWaitTimeMs (self: Self) anyerror!?f64 {
    return self.vtable.getAverageWaitTimeMs(self.ptr);
}
pub fn getAverageLeadTimeMs(self: Self) anyerror!?f64 {
    return self.vtable.getAverageLeadTimeMs(self.ptr);
}
