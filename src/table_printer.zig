const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Task = @import("task.zig");
const Database = @import("database.zig");

pub fn printTaskTable(tasks: []Task, current_page: usize, total_items: usize, page_size: usize) void {
    const total_pages = if (total_items == 0) 1 else (total_items + page_size - 1) / page_size;

    const id_hdr = "ID";
    const title_hdr = "TITULO";
    const owner_hdr = "OWNER";
    const requester_hdr = "REQUESTER";
    const status_hdr = "STATUS";

    var w_id = id_hdr.len;
    var w_title_hdr = title_hdr.len;
    var w_owner_hdr = owner_hdr.len;
    var w_requester_hdr = requester_hdr.len;
    var w_status_hdr = status_hdr.len;

    for (tasks) |t| {
        if (t.id) |id| w_id = @max(w_id, std.fmt.count("{d}", .{id}));
        if (t.task_name) |name| w_title_hdr = @max(w_title_hdr, name.len);
        if (t.owner) |o| w_owner_hdr = @max(w_owner_hdr, o.len);
        if (t.requester) |r| w_requester_hdr = @max(w_requester_hdr, r.len);
        if (t.status) |s| w_status_hdr = @max(w_status_hdr, s.len);
    }

    print("\n+", .{});
    printRepeated('-', w_id + 2); print("+", .{});
    printRepeated('-', w_title_hdr + 2); print("+", .{});
    printRepeated('-', w_owner_hdr + 2); print("+", .{});
    printRepeated('-', w_requester_hdr + 2); print("+", .{});
    printRepeated('-', w_status_hdr + 2); print("+\n", .{});

    print("  Página {d} de {d} | Total de registros: {d}\n\n", .{ current_page, total_pages, total_items });
}

fn printRepeated(char: u8, count: usize) void {
    var i: usize = 0;
    while (i < count) : (i += 1) print("{c}", .{char});
}

pub fn interactivePagination(io: std.Io, allocator: Allocator, db: *Database) !void {
    const page_size: usize = 5;
    var current_page: usize = 1;
    const total_items: usize = db.countTotalTasks();

    var stdin_buf: [256]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(io, &stdin_buf);
    const reader = &stdin.interface;

    while(true) {
        const offset = (current_page - 1) * page_size;
        const tasks = try db.listTasksPaginated(allocator, .{ .limit = page_size, .offset = offset });
        defer {
            for (tasks) |t| t.deinit(allocator);
            allocator.free(tasks);
        }

        print("\x1B[2J\x1B[H", .{});
        printTaskTable(tasks, current_page, total_items, page_size);

        print("[P] Próxima | [A] Anterior | [Q] Sair: ", .{});
        if (try reader.takeDelimiterInclusive('\n')) |input| {
            const cmd = std.mem.trim(u8, input, "\r\n ");
            if (std.mem.eql(u8, cmd, "p") or std.mem.eql(u8, cmd, "P")) {
                if (offset + page_size < total_items) current_page += 1;
            } else if (std.mem.eql(u8, cmd, "a") or std.mem.eql(u8, cmd, "A")) {
                if (current_page > 1) current_page -= 1;
            } else if (std.mem.eql(u8, cmd, "q") or std.mem.eql(u8, cmd, "Q")) {
                break;
            }
        }
    }
}
