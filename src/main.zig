const std = @import("std");
const stdout = std.io.getStdOut().writer();
const fs = std.fs;

const Queue = struct {
    mutex: std.Thread.Mutex,
    items: std.ArrayList([]const u8),

    fn init(allocator: std.mem.Allocator) Queue {
        return .{
            .mutex = std.Thread.Mutex{},
            .items = std.ArrayList([]const u8).init(allocator),
        };
    }

    fn push(self: *Queue, item: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.items.append(item);
    }

    fn pop(self: *Queue) ?[]const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        return if (self.items.items.len > 0) self.items.orderedRemove(0) else null;
    }
};

fn httpRequest(client: *std.http.Client, queue: *Queue) !void {
    while (queue.pop()) |url| {
        const request = try client.fetch(.{
            .method = .GET,
            .location = .{ .url = url },
        });

        switch (request.status) {
            .ok => try stdout.print("{s}HTTP 200 OK | {s}{s}\n", .{"\x1b[32m", url, "\x1b[0m"}),
            .not_found => try stdout.print("HTTP 404 NOT FOUND | {s}\n", .{url}),
            else => {},
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 7) {
        try stdout.print("[!] Usage: {s} -u https://example.com -w dictionary.txt -t thread_count\n", .{args[0]});
        return error.InvalidArguments;
    }

    try stdout.print("\x1B[2J\x1B[H", .{}); // Clear the screen
        
    const base_url: []const u8 = args[2];
    const filename: []const u8 = args[4];
    const thread_count = try std.fmt.parseInt(usize, args[6], 10);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var buffer: [1024]u8 = undefined;
    var url_queue = Queue.init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const url = try std.fmt.allocPrint(allocator, "{s}/{s}", .{base_url, line});
        try url_queue.push(url);
    }

    const threads = try allocator.alloc(std.Thread, thread_count);
    defer allocator.free(threads);

    for (threads) |*thread| {
        thread.* = try std.Thread.spawn(.{}, httpRequest, .{ &client, &url_queue });
    }

    for (threads) |thread| {
        thread.join();
    }
}
