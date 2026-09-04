const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const print = std.debug.print;

const Task = @import("task.zig");
const Database = @import("database.zig");
const Command = @import("command.zig").Command;
const helper = @import("command.zig").helper;
const summary_report = @import("summary_report.zig").printSummaryReport;
const printTaskTable = @import("table_printer.zig").printTaskTable;

io: Io,
allocator: Allocator,
db: *Database,

const Self = @This();

pub fn newApp(io: Io, allocator: Allocator, db: *Database) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .io = io,
        .allocator = allocator,
        .db = db,
    };

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn run(self: *Self, args: []const []const u8) !void {
    if (args.len < 1) {
        helper();
        return;
    }

    const command = std.meta.stringToEnum(Command, args[0]) orelse return helper();

    try switch (command) {
        .stat => summary_report(self.allocator, self.db),
        .list => list(self.db, self.allocator, args[1..]),
        .show => {},
        .new => newTask(self.io, self.db, args[1..]),
        .start => {},
        .finish => {},
        .cancel => {},
        .description => {},
        .owner => {},
        .requester => {},
        .rename => {},
        .help => {},
    };
}

fn list(db: *Database, allocator: Allocator, args: []const []const u8) !void {
    if (args.len != 1) return helper();
    const opt = args[0];

    const tasks = switch (opt[1]) {
       'a' => try db.findTasks(5),
       's' => try db.findTasks(1),
       'f' => try db.findTasks(2),
       'd' => try db.findTasks(3),
       'c' => try db.findTasks(4),
       't' => try db.findTasks(0),
       else => return helper(),
    };

    defer {
        for (tasks) |*t| {
            t.deinit(allocator);
        }
        allocator.free(tasks);
    }

    printTaskTable(tasks);
}

fn newTask(io: Io, db: *Database, args: []const []const u8) !void {
    if (args.len < 1) return helper();
    var title: ?[]const u8 = null;
    var description: ?[]const u8 = null;
    var requester: ?[]const u8 = null;
    for (args) |a| {
        var iter = std.mem.splitScalar(u8, a, '=');
        const param = iter.first();
        if (iter.next()) |i| {
            if (std.mem.eql(u8, "title", param)) {
                title = i;
                continue;
            }

            if (std.mem.eql(u8, "description", param)) {
                description = i;
                continue;
            }

            if (std.mem.eql(u8, "requester", param)) {
               requester = i;
               continue;
            }
        }
    }
    if (title) |t| {
        const task = Task.newTask(io, t,description, requester);
        print("{f}\n", .{task});
        const id = try db.createTask(task);
        print("Task {d} created!\n", .{ id });
    } else {
        return error.InvalidNullTitle;
    }
}
