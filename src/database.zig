const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const Task = @import("task.zig");

const Self = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const SortColumn = enum {
    id,
    title,
    owner,
    requester,
    status,
    createdAt,
    startedAt,
    finishedAt,

    pub fn toSqlColumn(self: @This()) []const u8 {
        return switch (self) {
            .id => "id",
            .title => "task_name",
            .owner => "owner",
            .requester => "requester",
            .status => "status",
            .createdAt => "created_at",
            .startedAt => "started_at",
            .finishedAt => "finished_at",
        };
    }
};

pub const SortOrder = enum {
    asc,
    desc,

    pub fn toSql(self: @This()) []const u8 {
        return switch (self) {
            .asc => "ASC",
            .desc => "DESC",
        };
    }
};

pub const TaskQueryOptions = struct {
    limit: usize = 10,
    offset: usize = 0,
    sort_by: SortColumn = .id,
    sort_order: SortOrder = .asc,
};

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
    getAverageWaitTimeMs: *const fn (ctx: *anyopaque) anyerror!?f64,
    getAverageLeadTimeMs: *const fn (ctx: *anyopaque) anyerror!?f64,
    countTotalTasks: *const fn (ctx: *anyopaque) anyerror!usize,
    listTasksPaginated: *const fn (ctx: *anyopaque, allocator: Allocator, options: TaskQueryOptions) anyerror![]GroupCount,
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

pub fn getAverageWaitTimeMs(self: Self) anyerror!?f64 {
    return self.vtable.getAverageWaitTimeMs(self.ptr);
}
pub fn getAverageLeadTimeMs(self: Self) anyerror!?f64 {
    return self.vtable.getAverageLeadTimeMs(self.ptr);
}

pub fn countTotalTasks(self: Self) !usize {
    return self.vtable.countTotalTasks(self.ptr);
}

pub fn listTasksPaginated(self: Self, allocator: Allocator, options: TaskQueryOptions) ![]GroupCount {
    return self.vtable.listTasksPaginated(self.ptr, allocator, options);
}
