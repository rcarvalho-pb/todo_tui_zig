const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Task = @import("task.zig");
const Database = @import("database.zig");

fn printRepeated(char: u8, count: usize) void {
    for (0..count) |_| {
        print("{c}", .{char});
    }
}

pub fn printTaskTable(tasks: []const Task) void {
    const id_hdr = "ID";
    const title_hdr = "TITULO";
    const description_hdr = "DESCRICAO";
    const owner_hdr = "OWNER";
    const requester_hdr = "REQUESTER";
    const status_hdr = "STATUS";

    var w_id = id_hdr.len;
    var w_title = title_hdr.len;
    var w_desc = description_hdr.len;
    var w_owner = owner_hdr.len;
    var w_req = requester_hdr.len;
    var w_status = status_hdr.len;

    // 1. Calcula as larguras máximas
    for (tasks) |t| {
        if (t.id) |id| w_id = @max(w_id, std.fmt.count("{d}", .{id}));
        if (t.title) |title| w_title = @max(w_title, title.len);
        if (t.description) |desc| w_desc = @max(w_desc, desc.len);
        if (t.owner) |o| w_owner = @max(w_owner, o.len);
        if (t.requester) |r| w_req = @max(w_req, r.len);
        if (t.status) |s| w_status = @max(w_status, @tagName(s).len);
    }

    // Função interna para desenhar a linha divisória
    const printSeparator = struct {
        fn draw(w1: usize, w2: usize, w3: usize, w4: usize, w5: usize, w6: usize) void {
            print("+", .{});
            printRepeated('-', w1 + 2); print("+", .{});
            printRepeated('-', w2 + 2); print("+", .{});
            printRepeated('-', w3 + 2); print("+", .{});
            printRepeated('-', w4 + 2); print("+", .{});
            printRepeated('-', w5 + 2); print("+", .{});
            printRepeated('-', w6 + 2); print("+\n", .{});
        }
    }.draw;

    // 2. Linha superior
    printSeparator(w_id, w_title, w_desc, w_owner, w_req, w_status);

    // 3. Cabeçalho (Usa fmtSliceLeft para alinhar dinamicamente à esquerda)
}
