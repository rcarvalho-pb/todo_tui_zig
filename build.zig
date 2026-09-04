const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const exe = b.addExecutable(.{
    //     .name = "todo_app",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/main.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{},
    //         .link_libc = true,
    //     }),
    // });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{},
        .link_libc = true,
    });

    const sqlite3_dep = b.dependency("sqlite3", .{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = sqlite3_dep.path("sqlite3.h"),
        .optimize = optimize,
        .target = target,
    });

    const c_mod = translate_c.createModule();

    c_mod.addCSourceFiles(.{
        .root = sqlite3_dep.path(""),
        .files = &.{"sqlite3.c"},
        .flags = &.{
            "-DSQLITE_THREADSAFE=1",
            "-DSQLITE_ENABLE_FTS5",
        },
    });

    exe_mod.addImport("sqlite3", c_mod);

    // exe.root_module.addImport("sqlite3", c_mod);

    const vaxis = b.dependency("vaxis", .{
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("vaxis", vaxis.module("vaxis"));

    const exe = b.addExecutable(.{
        .name = "todo_app",
        .root_module = exe_mod,
    });

    // exe.root_module.addImport("vaxis", vaxis.module("vaxis"));

    // const exe_mod = b.addExecutable(.{
    //         .name = "project_foo",
    //         .root_module = exe.root_module,
    //     });

    const options = b.addOptions();

    options.addOption([]const u8, "db_path", "db/db.db");
    options.addOption([]const u8, "sql_files", "sql");
    options.addOption([]const u8, "default_owner", "Ramon");

    exe.root_module.addOptions("build_options", options);

    b.installArtifact(exe);
    // b.installArtifact(exe_mod);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
