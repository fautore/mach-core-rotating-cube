const mach = @import("mach");

pub const modules = .{
    mach.Core,
    @import("App.zig"),
};

pub fn main() !void {
    try mach.core.initModule();
    while (try mach.core.tick()) {}
}
