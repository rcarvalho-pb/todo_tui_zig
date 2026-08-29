const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

const Command = struct {
    arena: Allocator,
};

pub const helper =
    \\--------------------------------------------------------------
    \\                           TODO CLI
    \\               Simple task manager written in Zig
    \\--------------------------------------------------------------
    \\
    \\USAGE
    \\
    \\    todo <command> [options]
    \\
    \\COMMANDS
    \\
    \\    new         Create a new task
    \\
    \\        todo new "Write documentation"
    \\
    \\    start       Start a task
    \\
    \\       todo start 4
    \\
    \\    finish      Finish a task
    \\
    \\       todo finish 4
    \\
    \\    rename      Rename a task
    \\
    \\       todo rename 4 "Implement CLI parser"
    \\
    \\    owner       Change task owner
    \\
    \\        todo owner 4 Ramon
    \\
    \\    requester   Change task requester
    \\
    \\        todo requester 4 Product
    \\
    \\    list        List all tasks
    \\
    \\        todo list
    \\
    \\    show        Show task information
    \\
    \\        todo show 4
    \\
    \\    delete      Delete a task
    \\
    \\        todo delete 4
    \\
    \\    help        Display this screen
    \\
    \\OPTIONS
    \\
    \\    -h, --help
    \\        Show this help message.
    \\
    \\    -v, --version
    \\        Show application version.
    \\
    \\    -d, --database <path>
    \\        Database file to use.
    \\        Default: ./db/db.db
    \\
    \\    -q, --quiet
    \\        Suppress informational output.
    \\
    \\EXIT STATUS
    \\
    \\    0   Success
    \\    1   Invalid command
    \\    2   Invalid arguments
    \\    3   Database error
;
