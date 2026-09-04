const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const print = std.debug.print;

const db_path = @import("build_options").db_path;

const Sqlite = @import("sqlite3Impl.zig");
const App = @import("app.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const arena = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(arena);

    const sql_path = try arena.dupeZ(u8, db_path);
    var sqlite = try Sqlite.init(gpa, sql_path);
    defer sqlite.deinit();
    const db = &sqlite.interface;

    const app = try App.newApp(io, gpa, db);
    defer app.deinit();
    try app.run(args[1..]);
}
