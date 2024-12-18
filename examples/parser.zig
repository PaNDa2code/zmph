const std = @import("std");
const zmph = @import("zmph");

pub fn main() !void {
    const source_code =
        "let x = 42 in if x > 10 then print x else if print 0 ";
    const keywords = zmph.MinimalPerfectHashMap([]const u8, KeywordsEnum).comptimeInit(keyword_list);

    var tokinzer = std.mem.tokenizeAny(u8, source_code, " ");

    while (tokinzer.next()) |token| {
        const keyword_enum = keywords.get(token);
        if (keyword_enum) |kw_enum| {
            std.debug.print("Keyword found: {s: <6} => {any}\n", .{ token, kw_enum });
        } else {
            std.debug.print("Not a keyword: {s}\n", .{token});
        }
    }
}

const KeywordsEnum = enum(u3) {
    Let,
    If,
    Then,
    Else,
    Print,
    In,
};

const keyword_list = .{
    .{ "let", KeywordsEnum.Let },
    .{ "if", KeywordsEnum.If },
    .{ "then", KeywordsEnum.Then },
    .{ "else", KeywordsEnum.Else },
    .{ "print", KeywordsEnum.Print },
    .{ "in", KeywordsEnum.In },
};
