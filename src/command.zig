const std = @import("std");
const Allocator = std.mem.Allocator;

const print = std.debug.print;

pub const Command = enum {
    stat, new, start, finish, cancel, rename, description, owner, requester, list, show, help
};

pub fn helper() void {
    print("{s}", .{helper_msg});
}

const helper_msg =
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
    \\    statistics
    \\        stat
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
    \\    list
    \\        -t: created and no started
    \\        -a: all
    \\        -c: created
    \\        -s: started
    \\        -f: finished
    \\        -d: canceled
    \\        -x: not finished or canceled
    \\
    \\        todo list [opt]
    \\
    \\    show        Show task information
    \\
    \\        todo show 4
    \\
    \\    cancel      Cancel a task
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
;
