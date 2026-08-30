const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const print = std.debug.print;

const db_path = @import("build_options").db_path;

const Sqlite = @import("sqlite3Impl.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const arena = init.arena.allocator();

    const sql_path = try arena.dupeZ(u8, db_path);
    var sqlite = try Sqlite.init(gpa, sql_path);
    defer sqlite.deinit();
    const db = &sqlite.interface;

    const active_tasks = try db.countActiveTasks();
    print("Active tasks: {d}\n", .{active_tasks});
}
