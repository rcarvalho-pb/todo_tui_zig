const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const sql_path = @import("build_options").sql_files;

const print = std.debug.print;

const sqlite = @import("sqlite3");

const Database = @import("database.zig");
const TaskQueryOptions = Database.TaskQueryOptions;
const GroupCount = Database.GroupCount;

const Task = @import("task.zig");

const Self = @This();

allocator: Allocator,
db: ?*sqlite.sqlite3,
interface: Database,

const Page = struct {
    limit: usize,
    offset: usize,
};

pub fn init(allocator: Allocator, path: [*:0]const u8) !*Self {
    var db: ?*sqlite.sqlite3 = null;

    var rc = sqlite.sqlite3_open(path, &db);
    if (rc != sqlite.SQLITE_OK) {
        print("cannot open database: {s}\n", .{sqlite.sqlite3_errmsg(db)});
        _ = sqlite.sqlite3_close(db);
        return error.ErrorOpenningDB;
    }

    const self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
        .db = db,
        .interface = undefined,
    };

    self.interface = self.createInterface();

    var stmt: ?*sqlite.sqlite3_stmt = null;
    const sql = @embedFile(sql_path ++ "/create_table.sql");

    rc = sqlite.sqlite3_prepare_v2(db, sql, @intCast(sql.len), &stmt, null);
    if (checkError(db, rc, "PREPARE: CREATE TABLE")) {
        return error.SqlitePrepareFailed;
    }
    defer _ = sqlite.sqlite3_finalize(stmt);

    rc = sqlite.sqlite3_step(stmt);
    if (checkError(db, rc, "STEP: CREATE TABLE")) {
        return error.SqliteStepFailed;
    }

    return self;
}

pub fn deinit(self: *Self) void {
    _ = sqlite.sqlite3_close(self.db);
    self.allocator.destroy(self);
}

fn createInterface(self: *Self) Database {
    const database: Database = .{
        .ptr = self,
        .vtable = &.{
            .createTable = createTable,
            .createTask = createTask,
            .updateTask = updateTask,
            .findTasks = findTasks,
            .countActiveTasks = countActiveTasks,
            .countAllStartedTasks = countAllStartedTasks,
            .countFinishedTasks = countFinishedTasks,
            .getAvarageCompletionTimeMs = getAvarageCompletionTimeMs,
            .getMaxCompletionTimeMs = getMaxCompletionTimeMs,
            .getMinCompletionTimeMs = getMinCompletionTimeMs,
            .countTasksByOwner = countTasksByOwner,
            .countTasksByRequester = countTasksByRequester,
            .getAverageWaitTimeMs = getAverageWaitTimeMs,
            .getAverageLeadTimeMs = getAverageLeadTimeMs,
            .countTotalTasks = countTotalTasks,
            .listTasksPaginated = listTasksPaginated,
        },
    };

    return database;
}

fn checkError(db: ?*sqlite.sqlite3, rc: c_int, errMsg: []const u8) bool {
    if (rc != sqlite.SQLITE_OK and rc != sqlite.SQLITE_DONE and rc != sqlite.SQLITE_ROW) {
        print("Error {s}: {s}\n", .{ errMsg, sqlite.sqlite3_errmsg(db) });
        return true;
    }
    return false;
}

fn createTable(ctx: *anyopaque) !void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    print("createTable self = {*}\n", .{self});
    print("createTable db   = {?}\n", .{self.db});

    if (self.db) |db| {
        print("createTable sqlite  = {*}\n", .{db});
    }

    const sql = @embedFile(sql_path ++ "/create_table.sql");

    var err_msg: [*c]u8 = null;

    print("db ptr: {?}\n", .{self.db});
    print("SQL:\n{s}\n", .{sql});

    const rc = sqlite.sqlite3_exec(
        self.db,
        sql,
        null,
        null,
        &err_msg,
    );

    if (rc != sqlite.SQLITE_OK) {
        if (err_msg != null) {
            print("SQLite error: {s}\n", .{err_msg});
            sqlite.sqlite3_free(err_msg);
        }

        print("SQLite errmsg: {s}\n", .{
            sqlite.sqlite3_errmsg(self.db),
        });

        return error.SqliteExecFailed;
    }
}

fn createTask(ctx: *anyopaque, task: Task) !i64 {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const sql = @embedFile(sql_path ++ "/create_task.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;

    const rc = sqlite.sqlite3_prepare_v2(
        self.db,
        sql,
        -1,
        &stmt,
        null,
    );

    if (rc != sqlite.SQLITE_OK) {
        print("SQLite error: {s}\n", .{
            sqlite.sqlite3_errmsg(self.db),
        });

        return error.SQLTPrepareFail;
    }

    defer _ = sqlite.sqlite3_finalize(stmt);

    if (task.title) |title| {
        _ = sqlite.sqlite3_bind_text(stmt, 1, title.ptr, @intCast(title.len), sqlite.SQLITE_STATIC);
    } else {
        return error.TaskNameRequired;
    }

    if (task.description) |desc| {
        _ = sqlite.sqlite3_bind_text(stmt, 2, desc.ptr, @intCast(desc.len), sqlite.SQLITE_STATIC);
    } else {
        _ = sqlite.sqlite3_bind_null(stmt, 2);
    }

    if (task.owner) |owner| {
        _ = sqlite.sqlite3_bind_text(stmt, 3, owner.ptr, @intCast(owner.len), sqlite.SQLITE_STATIC);
    } else {
        _ = sqlite.sqlite3_bind_null(stmt, 3);
    }

    if (task.requester) |req| {
        _ = sqlite.sqlite3_bind_text(stmt, 4, req.ptr, @intCast(req.len), sqlite.SQLITE_STATIC);
    } else {
        _ = sqlite.sqlite3_bind_null(stmt, 4);
    }

    if (task.created_at) |req| {
        _ = sqlite.sqlite3_bind_int64(stmt, 5, @intCast(req));
    } else {
        return error.InvalidTaskNullCreationTimestamp;
    }

    if (task.updated_at) |req| {
        _ = sqlite.sqlite3_bind_int64(stmt, 6, @intCast(req));
    } else {
        return error.InvalidTaskNullUpdateTimestamp;
    }

    const step_rc = sqlite.sqlite3_step(stmt);
    if (step_rc != sqlite.SQLITE_DONE) {
        print("SQLite step error: {s}\n", .{sqlite.sqlite3_errmsg(self.db)});
        return error.InsertFailed;
    }

    // 5. Retorna o ID gerado pelo AUTOINCREMENT
    return sqlite.sqlite3_last_insert_rowid(self.db);
}

fn updateTask(ctx: *anyopaque, task: Task) !void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    var stmt: ?*sqlite.sqlite3_stmt = null;

    const sql = @embedFile(sql_path ++ "/update_task.sql");

    if (sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null) != sqlite.SQLITE_OK) {
        return error.SqlitePrepareFail;
    }
    // Correção: O defer precisa ficar DEPOIS do prepare para evitar ponteiro nulo
    defer _ = sqlite.sqlite3_finalize(stmt);

    _ = if (task.id) |id| sqlite.sqlite3_bind_int64(stmt, 9, @intCast(id)) else return error.IdCannotBeNull;

    _ = if (task.title) |n| sqlite.sqlite3_bind_text(stmt, 1, n.ptr, @intCast(n.len), sqlite.SQLITE_STATIC) else sqlite.sqlite3_bind_null(stmt, 1);
    _ = if (task.description) |d| sqlite.sqlite3_bind_text(stmt, 2, d.ptr, @intCast(d.len), sqlite.SQLITE_STATIC) else sqlite.sqlite3_bind_null(stmt, 2);
    _ = if (task.owner) |o| sqlite.sqlite3_bind_text(stmt, 3, o.ptr, @intCast(o.len), sqlite.SQLITE_STATIC) else sqlite.sqlite3_bind_null(stmt, 3);
    _ = if (task.requester) |r| sqlite.sqlite3_bind_text(stmt, 4, r.ptr, @intCast(r.len), sqlite.SQLITE_STATIC) else sqlite.sqlite3_bind_null(stmt, 4);

    // Correção: Ajustada a ordem dos parâmetros (stmt, índice, valor) para bind_int64 e bind_int
    _ = if (task.updated_at) |s| sqlite.sqlite3_bind_int64(stmt, 5, s) else sqlite.sqlite3_bind_null(stmt, 5);
    _ = if (task.finished_at) |f| sqlite.sqlite3_bind_int64(stmt, 6, f) else sqlite.sqlite3_bind_null(stmt, 6);
    _ = if (task.canceled_at) |s| sqlite.sqlite3_bind_int64(stmt, 7, s) else sqlite.sqlite3_bind_null(stmt, 7);
    _ = if (task.status) |s| sqlite.sqlite3_bind_int(stmt, 8, @intFromEnum(s)) else sqlite.sqlite3_bind_null(stmt, 8);

    if (sqlite.sqlite3_step(stmt) != sqlite.SQLITE_DONE) {
        return error.SqliteStepFailed;
    }
}

fn findTasks(ctx: *anyopaque, flag: u3) ![]Task {
    const self: *Self = @ptrCast(@alignCast(ctx));

    var stmt: ?*sqlite.sqlite3_stmt = null;
    defer _ = sqlite.sqlite3_finalize(stmt);

    switch (flag) {
        0, 1, 2, 3 => {
            const sql = @embedFile(sql_path ++ "/find_task_by_flag.sql");

            if (sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null) != sqlite.SQLITE_OK) {
                return error.FailPrepareStatment;
            }

            const flag_value = switch (flag) {
                0 => @intFromEnum(Task.Status.TODO),
                1 => @intFromEnum(Task.Status.DOING),
                2 => @intFromEnum(Task.Status.DONE),
                3 => @intFromEnum(Task.Status.CANCELED),
                else => return error.InvalidFlag,
            };
            _ = sqlite.sqlite3_bind_int(stmt, 1, flag_value);
        },
        4 => {
            const sql = @embedFile(sql_path ++ "/find_task_not_done.sql");
            if (sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null) != sqlite.SQLITE_OK) {
                return error.FailPrepareStatment;
            }

            // Correção: Ajustada a ordem dos parâmetros no bind_int (stmt, índice, valor)
            _ = sqlite.sqlite3_bind_int(stmt, 1, @intFromEnum(Task.Status.DONE));
            _ = sqlite.sqlite3_bind_int(stmt, 2, @intFromEnum(Task.Status.CANCELED));
        },
        5 => {
            const sql = @embedFile(sql_path ++ "/find_all_tasks.sql");

            if (sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null) != sqlite.SQLITE_OK) {
                return error.FailPrepareStatment;
            }
        },
        else => return error.InvalidFlag,
    }

    var tasks = try std.ArrayList(Task).initCapacity(self.allocator, 0);

    while (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        // Correção: Leitura de colunas do SQLite é baseada em índice ZERO (0 a 8 em vez de 1 a 9)
        const id = sqlite.sqlite3_column_int64(stmt, 0);

        const title_ptr = sqlite.sqlite3_column_text(stmt, 1);
        const title_len = sqlite.sqlite3_column_bytes(stmt, 1);
        const title: ?[]const u8 = try self.allocator.dupe(u8, title_ptr[0..@intCast(title_len)]);

        var description: ?[]const u8 = null;
        if (sqlite.sqlite3_column_type(stmt, 2) != sqlite.SQLITE_NULL) {
            const description_ptr = sqlite.sqlite3_column_text(stmt, 2);
            const description_len = sqlite.sqlite3_column_bytes(stmt, 2);
            description = try self.allocator.dupe(u8, description_ptr[0..@intCast(description_len)]);
        }

        var owner: ?[]const u8 = null;
        if (sqlite.sqlite3_column_type(stmt, 3) != sqlite.SQLITE_NULL) {
            const owner_ptr = sqlite.sqlite3_column_text(stmt, 3);
            const owner_len = sqlite.sqlite3_column_bytes(stmt, 3);
            owner = try self.allocator.dupe(u8, owner_ptr[0..@intCast(owner_len)]);
        }

        var requester: ?[]const u8 = null;
        if (sqlite.sqlite3_column_type(stmt, 4) != sqlite.SQLITE_NULL) {
            const requester_ptr = sqlite.sqlite3_column_text(stmt, 4);
            const requester_len = sqlite.sqlite3_column_bytes(stmt, 4);
            requester = try self.allocator.dupe(u8, requester_ptr[0..@intCast(requester_len)]);
        }

        const created_at = sqlite.sqlite3_column_int64(stmt, 5);

        const updated_at = sqlite.sqlite3_column_int64(stmt, 6);

        var started_at: ?i64 = null;
        if (sqlite.sqlite3_column_type(stmt, 7) != sqlite.SQLITE_NULL) {
            started_at = sqlite.sqlite3_column_int64(stmt, 7);
        }

        var finished_at: ?i64 = null;
        if (sqlite.sqlite3_column_type(stmt, 8) != sqlite.SQLITE_NULL) {
            finished_at = sqlite.sqlite3_column_int64(stmt, 8);
        }

        const status: Task.Status = @enumFromInt(sqlite.sqlite3_column_int(stmt, 9));

        try tasks.append(self.allocator, .{
            .id = id,
            .title = title,
            .description = description,
            .owner = owner,
            .requester = requester,
            .created_at = created_at,
            .updated_at = updated_at,
            .started_at = started_at,
            .finished_at = finished_at,
            .status = status,
        });
    }

    return tasks.toOwnedSlice(self.allocator);
}

fn countActiveTasks(ctx: *anyopaque) !usize {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const sql = @embedFile(sql_path ++ "/count_active_tasks.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;

    var rc: c_int = undefined;

    rc = sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null);
    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }

    defer _ = sqlite.sqlite3_finalize(stmt);

    const done_value = @intFromEnum(Task.Status.DONE);
    _ = sqlite.sqlite3_bind_int(stmt, 1, done_value);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        const count = sqlite.sqlite3_column_int64(stmt, @intCast(0));
        return @intCast(count);
    }

    return error.SqliteStepFailed;
}

fn countAllStartedTasks(ctx: *anyopaque) !usize {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const sql = @embedFile(sql_path ++ "/count_all_started_tasks.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;

    var rc: c_int = undefined;

    rc = sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null);
    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }

    defer _ = sqlite.sqlite3_finalize(stmt);

    const doing_value = @intFromEnum(Task.Status.DOING);
    _ = sqlite.sqlite3_bind_int(stmt, 1, doing_value);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        const count = sqlite.sqlite3_column_int64(stmt, @intCast(0));
        return @intCast(count);
    }

    return error.SqliteStepFailed;
}

fn countFinishedTasks(ctx: *anyopaque) !usize {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const sql = @embedFile(sql_path ++ "/count_finished_tasks.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;

    var rc: c_int = undefined;

    rc = sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null);
    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }

    defer _ = sqlite.sqlite3_finalize(stmt);

    const done_value = @intFromEnum(Task.Status.DONE);
    _ = sqlite.sqlite3_bind_int(stmt, 1, done_value);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        const count = sqlite.sqlite3_column_int64(stmt, @intCast(0));
        return @intCast(count);
    }

    return error.SqliteStepFailed;
}

fn getAvarageCompletionTimeMs(ctx: *anyopaque) !?f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = @embedFile(sql_path ++ "/get_avarage_completion_time_ms.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;
    var rc = sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null);

    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }

    defer _ = sqlite.sqlite3_finalize(stmt);

    rc = sqlite.sqlite3_step(stmt);
    if (checkError(self.db, rc, "Step")) {
        return error.SqliteStepFail;
    }

    if (sqlite.sqlite3_column_type(stmt, 0) == sqlite.SQLITE_NULL) return null;
    return @floatCast(sqlite.sqlite3_column_double(stmt, 0));
}

fn getMaxCompletionTimeMs(ctx: *anyopaque) !?i64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = @embedFile(sql_path ++ "/get_max_completion_time_ms.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;
    var rc = sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null);

    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }
    defer _ = sqlite.sqlite3_finalize(stmt);

    rc = sqlite.sqlite3_step(stmt);
    if (checkError(self.db, rc, "Step")) {
        return error.SqliteStepFail;
    }

    if (sqlite.sqlite3_column_type(stmt, 0) == sqlite.SQLITE_NULL) return null;
    return @intCast(sqlite.sqlite3_column_int(stmt, 0));
}

fn getMinCompletionTimeMs(ctx: *anyopaque) !?i64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = @embedFile(sql_path ++ "/get_min_completion_time_ms.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;
    var rc = sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null);

    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }
    defer _ = sqlite.sqlite3_finalize(stmt);

    rc = sqlite.sqlite3_step(stmt);
    if (checkError(self.db, rc, "Step")) {
        return error.SqliteStepFail;
    }

    if (sqlite.sqlite3_column_type(stmt, 0) == sqlite.SQLITE_NULL) return null;
    return @intCast(sqlite.sqlite3_column_int(stmt, 0));
}

fn countTasksByColumn(self: *Self, allocator: Allocator, column_name: []const u8) ![]GroupCount {
    var sql_buf: [128]u8 = undefined;
    const sql = try std.fmt.bufPrintZ(&sql_buf, "SELECT IFNULL({s}, 'Desconhecido'), COUNT(*) FROM tasks GROUP BY {s};", .{ column_name, column_name });

    var stmt: ?*sqlite.sqlite3_stmt = null;
    const rc = sqlite.sqlite3_prepare_v2(self.db, sql.ptr, @intCast(sql.len), &stmt, null);
    if (checkError(self.db, rc, "STMT Prepare")) {
        return error.SqlitePrepareFail;
    }
    defer _ = sqlite.sqlite3_finalize(stmt);

   var list: std.ArrayList(GroupCount) = try .initCapacity(allocator, 0);
   errdefer {
       for (list.items) |item| item.deinit(allocator);
       list.deinit(allocator);
   }

   while(sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
       const name_ptr = sqlite.sqlite3_column_text(stmt, 0);
       const name_len = sqlite.sqlite3_column_bytes(stmt, 0);
       const name = try allocator.dupe(u8, name_ptr[0..@intCast(name_len)]);
       const count = sqlite.sqlite3_column_int64(stmt, 1);

       try list.append(allocator, .{ .name = name, .count = @intCast(count) });
   }

   return list.toOwnedSlice(allocator);
}

fn countTasksByOwner(allocator: Allocator, ctx: *anyopaque) ![]Database.GroupCount {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return countTasksByColumn(self, allocator, "owner");
}

fn countTasksByRequester(allocator: Allocator, ctx: *anyopaque) ![]Database.GroupCount {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return countTasksByColumn(self, allocator, "requester");
}

fn getAverageWaitTimeMs(ctx: *anyopaque) !?f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = @embedFile(sql_path ++ "/get_avarage_wait_time_ms.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;
    if (sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null) != sqlite.SQLITE_OK) return error.SqlitePrepareFail;
    defer _ = sqlite.sqlite3_finalize(stmt);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        if (sqlite.sqlite3_column_type(stmt, 0) == sqlite.SQLITE_NULL) return null;
        return sqlite.sqlite3_column_double(stmt, 0);
    }
    return error.SqliteStepFailed;
}

fn getAverageLeadTimeMs(ctx: *anyopaque) !?f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = @embedFile(sql_path ++ "/get_avarage_lead_time_ms.sql");

    var stmt: ?*sqlite.sqlite3_stmt = null;
    if (sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null) != sqlite.SQLITE_OK) return error.SqlitePrepareFail;
    defer _ = sqlite.sqlite3_finalize(stmt);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        if (sqlite.sqlite3_column_type(stmt, 0) == sqlite.SQLITE_NULL) return null;
        return sqlite.sqlite3_column_double(stmt, 0);
    }
    return error.SqliteStepFailed;
}

pub fn listTasksPaginated(ctx: *anyopaque, allocator: Allocator, opts: TaskQueryOptions) ![]GroupCount {
    const self: *Self = @ptrCast(@alignCast(ctx));

    // Buffer para armazenar a consulta SQL com as colunas interpoladas de forma segura
    var sql_buf: [256]u8 = undefined;
    const sql = try std.fmt.bufPrintZ(
        &sql_buf,
        \\SELECT id, title, owner, requester, status, created_at, started_at, finished_at
        \\FROM tasks
        \\ORDER BY {s} {s}
        \\LIMIT ? OFFSET ?;
    ,
        .{ opts.sort_by.toSqlColumn(), opts.sort_order.toSql() },
    );

    var stmt: ?*sqlite.sqlite3_stmt = null;
    if (sqlite.sqlite3_prepare_v2(self.db, sql.ptr, -1, &stmt, null) != sqlite.SQLITE_OK) {
        return error.SqlitePrepareFail;
    }
    defer _ = sqlite.sqlite3_finalize(stmt);

    // Bind seguro apenas para os valores numéricos de paginação
    _ = sqlite.sqlite3_bind_int64(stmt, 1, @intCast(opts.limit));
    _ = sqlite.sqlite3_bind_int64(stmt, 2, @intCast(opts.offset));

    var list = try std.ArrayList(GroupCount).initCapacity(allocator, 0);
    errdefer {
        for (list.items) |*t| t.deinit(allocator);
        list.deinit(allocator);
    }

    while (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
       const name_ptr = sqlite.sqlite3_column_text(stmt, 0);
       const name_len = sqlite.sqlite3_column_bytes(stmt, 0);
       const name = try allocator.dupe(u8, name_ptr[0..@intCast(name_len)]);
       const count = sqlite.sqlite3_column_int64(stmt, 1);
       try list.append(allocator, .{ .name = name, .count = @intCast(count) });
    }

    return list.toOwnedSlice(allocator);
}

// pub fn listTasksPaginated(ctx: *anyopaque, allocator: Allocator, page: Page) ![]Task {
//     const self: *Self = @ptrCast(@alignCast(ctx));
//
//     const sql = @embedFile(sql_path ++ "/list_tasks_paginated.sql");
//
//     var stmt: ?*sqlite.sqlite3_stmt = null;
//     const rc = sqlite.sqlite3_prepare_v2(self.db, sql, @intCast(sql.len), &stmt, null);
//     if (checkError(self.db, rc, "STMT Prepare")) {
//         return error.SqlitePrepareFailed;
//     }
//     defer _ = sqlite.sqlite3_finalize(stmt);
//
//     _ = sqlite.sqlite3_bind_int64(stmt, 1, @intCast(page.limit));
//     _ = sqlite.sqlite3_bind_int64(stmt, 2, @intCast(page.offset));
//
//     var list: std.ArrayList(Task) = .initCapacity(self.allocator, 0);
//     errdefer list.deinit(self.allocator);
//
//     while(sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
//        const name_ptr = sqlite.sqlite3_column_text(stmt, 0);
//        const name_len = sqlite.sqlite3_column_bytes(stmt, 0);
//        const name = try allocator.dupe(u8, name_ptr[0..@intCast(name_len)]);
//        const count = sqlite.sqlite3_column_int64(stmt, 1);
//
//        try list.append(allocator, .{ .name = name, .count = @intCast(count) });
//     }
//
//     return list.toOwnedSlice(self.allocator);
// }

pub fn countTotalTasks(ctx: *anyopaque) !usize {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const sql = "SELECT COUNT(*) FROM tasks;";

    var stmt: ?*sqlite.sqlite3_stmt = null;
    if (sqlite.sqlite3_prepare_v2(self.db, sql, -1, &stmt, null) != sqlite.SQLITE_OK) return error.SqlitePrepareFail;
    defer _ = sqlite.sqlite3_finalize(stmt);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        return @intCast(sqlite.sqlite3_column_int64(stmt, 0));
    }
    return 0;
}
