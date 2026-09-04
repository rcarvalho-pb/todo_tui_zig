const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Database = @import("database.zig");

const formatDurationMs = @import("format_time.zig").formatDurationMs;

pub fn printSummaryReport(allocator: Allocator, db: *Database) !void {
    print("\n=====================================================\n", .{});
    print("           RELATORIO DE PRODUTIVIDADE                \n", .{});
    print("=====================================================\n\n", .{});

    // 1. Visão Geral de Quantidades
    const active_tasks = try db.countActiveTasks();
    print("[ TASKS EM ABERTO / EM ANDAMENTO ]\n", .{});
    print("  - Total Ativas: {d}\n\n", .{active_tasks});

    // 2. Métricas de Tempo
    print("[ TEMPOS MEDIOS DE FLUXO ]\n", .{});

    if (try db.getAverageWaitTimeMs()) |wait_ms| {
        var buf: [64]u8 = undefined;
        const str = try formatDurationMs(&buf, @intFromFloat(wait_ms));
        defer allocator.free(str);
        print("  - Tempo Medio de Espera (Wait Time): {s}\n", .{str});
    } else {
        print("  - Tempo Medio de Espera: N/A\n", .{});
    }

    if (try db.getAverageCompletionTimeMs()) |cycle_ms| {
        var buf: [64]u8 = undefined;
        const str = try formatDurationMs(&buf, @intFromFloat(cycle_ms));
        defer allocator.free(str);
        print("  - Tempo Medio de Execução (Cycle Time): {s}\n", .{str});
    } else {
        print("  - Tempo Medio de Execucao: N/A\n", .{});
    }

    if (try db.getAverageLeadTimeMs()) |lead_ms| {
        var buf: [64]u8 = undefined;
        const str = try formatDurationMs(&buf, @intFromFloat(lead_ms));
        defer allocator.free(str);
        print("  - Tempo Medio Total (Lead Time):     {s}\n", .{str});
    } else {
        print("  - Tempo Medio Total: N/A\n", .{});
    }

    print("\n[ EXTREMOS DE EXECUCAO ]\n", .{});
    if (try db.getMinCompletionTimeMs()) |min_ms| {
        var buf: [64]u8 = undefined;
        const str = try formatDurationMs(&buf, min_ms);
        defer allocator.free(str);
        print("  - Mais Rapida: {s}\n", .{str});
    }

    if (try db.getMaxCompletionTimeMs()) |max_ms| {
        var buf: [64]u8 = undefined;
        const str = try formatDurationMs(&buf, max_ms);
        defer allocator.free(str);
        print("  - Mais Lenta:  {s}\n", .{str});
    }

    // 3. Agrupamentos por Responsável (Owner)
    print("\n[ DISTRIBUICAO POR OWNER ]\n", .{});
    const owners = try db.countTasksByOwner(allocator);
    defer {
        for (owners) |item| item.deinit(allocator);
        allocator.free(owners);
    }

    for (owners) |item| {
        print("  - {s:<20} {d:>4} tasks\n", .{ item.name, item.count });
    }

    // 4. Agrupamentos por Solicitante (Requester)
    print("\n[ DISTRIBUICAO POR REQUESTER ]\n", .{});
    const requesters = try db.countTasksByRequester(allocator);
    defer {
        for (requesters) |item| item.deinit(allocator);
        allocator.free(requesters);
    }

    for (requesters) |item| {
        print("  - {s:<20} {d:>4} tasks\n", .{ item.name, item.count });
    }

    print("\n=====================================================\n\n", .{});
}
