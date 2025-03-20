//
//  Spigot Pi Calculator
//  Written By: Vincent S.
//  Date: 3/14/2025
//  
//  This is my implementation of piG3 defined here:
//  https://www.cs.ox.ac.uk/jeremy.gibbons/publications/spigot.pdf
//  The piG3 algorithm relies on Conjecture 1 in the paper 
//  suggested by Christoph Haenel. This conjecture has not been
//  formally proven, but the authors of the paper have verified it
//  for the first thousand terms according to the paper. 
//  
//  As of 2021, according to 
//  https://www.gavalas.dev/blog/spigot-algorithms-for-pi-in-python/
//  the conjecture has still not been proven, however the author of that
//  article has verified it to be true for the first million digits.
//
//  I'm not smart enough to prove the conjecture, but I have 
//  independently verified it to be true for the first 4,025,000
//  digits which is more than anyone else has as far as I can find.
//  
//  piG3 is neither the fastest nor most concise algorithm for
//  calculating pi. As mentioned above, this algorithm hasn't even been
//  proven to output correct results. I just thought it was 
//  cool because it outputs one digit of pi at a time and is faster
//  than more common methods of calcuating pi such as the 
//  Gregory-Leibniz Series.
// 
//  Yes, I am aware this code contest is scored by lines of code
//  and that this program is not small. I just wanted to implement
//  this specific algorithm because it was interesting.
//
//  I originally wrote this in JavaScript which was very slow. So I 
//  rewrote it in Zig using Zig's built in bigint library and it was
//  4x faster than JS. I then rewrote it again using GMP which was 
//  3x faster than Zig's bigint.
//  
//  Time to compute pi on Ryzen 7 8845HS using Zig's big int
//      1,000 digits in 0.11 seconds
//      10,000 digits in 0.52 seconds
//      100,000 digits in 54 seconds
//      1,000,000 digits in 2.11 hours
//      2,000,000 digits in 9.48 hours
//      2,500,000 digits in 15.76 hours
//
//  Time to compute pi on Ryzen 7 8845HS using GMP
//      1,000 digits in 0.10 seconds
//      10,000 digits in 0.12 seconds
//      100,000 digits in 18.13 seconds
//      1,000,000 digits in 0.71 hours
//      2,000,000 digits in 3.18 hours
//      2,500,000 digits in 5.07 hours
//      3,000,000 digits in 7.42 hours
//      4,000,000 digits in 13.73 hours
// 
//  Dependencies:
//      vexlib
//          version: v0.0.26
//          source: https://github.com/vExcess/zig-vexlib
//      gmplib
//          version: v6.3.0
//          source: https://gmplib.org/
//  
//  Compile using Zig v0.15.0-dev.10+214750fcf or newer
//  Zig can be downloaded at https://ziglang.org/download/
//  To compile and run:
//      zig build-exe main.zig -O ReleaseFast -lc -lgmp
//      ./main
//
//  Note: Without modifications this program will compile and run
//  on Linux running on a x64 CPU. It's theorertically possible to
//  run on Windows using MinGW but that's probably a pain. Compiling
//  on ARM has also been known to have issues.
//

//  Here is a Dart program I wrote to verify the output of my program:
//
//  // Download Dart compiler from https://dart.dev/get-dart
//  // Run using: dart validate.dart
//  import 'dart:io';
//  import 'dart:math';
//  
//  void main() {
//      // Actual digits of pi from https://stuff.mit.edu/afs/sipb/contrib/pi/
//      var actual = File("actual.txt").readAsStringSync();
//      var output = File("out-copy.txt").readAsStringSync();
//      var len = min(actual.length, output.length);
//      print(len);
//      print(actual.substring(0, len) == output.substring(0, len));
//  }
//

const std = @import("std");
const vexlib = @import("./vexlib.zig");
const As = vexlib.As;
const String = vexlib.String;
const Time = vexlib.Time;

pub const gmp = @cImport({
    @cInclude("x86_64-linux-gnu/gmp.h");
});

const allocator: std.mem.Allocator = std.heap.c_allocator;

const BigInt = struct {
    num: gmp.mpz_t = undefined,

    fn alloc() BigInt {
        var bi = BigInt{
            .num = undefined
        };
        gmp.mpz_init(&bi.num);
        return bi;
    }

    fn allocSet(val: anytype) BigInt {
        var bi = BigInt{
            .num = undefined
        };
        gmp.mpz_init(&bi.num);
        if (@TypeOf(val) == String) {
            const flag = gmp.mpz_set_str(&bi.num, val.cstring(), 10);
            if (flag != 0) {
                std.debug.panic("failed to initialize", .{});
            }
        } else {
            gmp.mpz_set_ui(&bi.num, val);
        }
        return bi;
    }

    fn dealloc(self: *BigInt) void {
        gmp.mpz_clear(&self.num);
    }

    fn toString(self: *BigInt, radix: u32) String {
        var s = String.alloc(As.u32(gmp.mpz_sizeinbase(&self.num, 10) + 2));
        _=gmp.mpz_get_str(s.bytes.buffer.ptr, @as(c_int, @intCast(radix)), &self.num);
        s.viewEnd = s.bytes.capacity();
        s.viewEnd = As.u32(s.indexOf('\x00'));
        return s;
    }

    fn add(self: *BigInt, a: *const BigInt, b: *const BigInt) void {
        gmp.mpz_add(&self.num, &a.num, &b.num);
    }

    fn addu64(self: *BigInt, a: *const BigInt, b: u64) void {
        gmp.mpz_add_ui(&self.num, &a.num, b);
    }

    fn addMul(self: *BigInt, a: *const BigInt, b: *const BigInt) void {
        // this = this + a * b
        gmp.mpz_addmul(&self.num, &a.num, &b.num);
    }

    fn addMulu64(self: *BigInt, a: *const BigInt, b: u64) void {
        // this = this + a * b
        gmp.mpz_addmul(&self.num, &a.num, b);
    }

    fn sub(self: *BigInt, a: *const BigInt, b: *const BigInt) void {
        gmp.mpz_sub(&self.num, &a.num, &b.num);
    }

    fn subu64(self: *BigInt, a: *const BigInt, b: u64) void {
        gmp.mpz_sub_ui(&self.num, &a.num, b);
    }

    fn mul(self: *BigInt, a: *const BigInt, b: *const BigInt) void {
        gmp.mpz_mul(&self.num, &a.num, &b.num);
    }

    fn muli64(self: *BigInt, a: *const BigInt, b: i64) void {
        gmp.mpz_mul_si(&self.num, &a.num, b);
    }

    fn divFloor(self: *BigInt, a: *const BigInt, b: *const BigInt) void {
        gmp.mpz_fdiv_q(&self.num, &a.num, &b.num);
    }
};

// globals (must not change between next() calls)
var q: BigInt = undefined;
var r: BigInt = undefined;
var t: BigInt = undefined;
var i: BigInt = undefined;

// locals (change every next() call)
var digit: BigInt = undefined;
var u: BigInt = undefined;
var local1: BigInt = undefined;
var local1a: BigInt = undefined;
var local1b: BigInt = undefined;
var local2: BigInt = undefined;
var local2a: BigInt = undefined;
var local2b: BigInt = undefined;
var extra: BigInt = undefined;

var addTime: i64 = 0;
var subTime: i64 = 0;
var mulTime: i64 = 0;
var divTime: i64 = 0;

var count: i32 = 0;

fn pipeline1A() void {
    // digit = (q * (27 * i - 12) + 5 * r) / (5 * t)
    local2b.muli64(&i, 27);
    local2a.subu64(&local2b, 12);
    local1a.mul(&local2a, &q);
    local1b.muli64(&r, 5);
    local1.add(&local1a, &local1b);
    local2.muli64(&t, 5);
    digit.divFloor(&local1, &local2);
}

fn pipeline1B() void {
    // u = 3 * i
    u.muli64(&i, 3);

    // u = 3 * (u + 1) * (u + 2)
    local1a.addu64(&u, 1);
    local2.addu64(&u, 2);
    local1.muli64(&local1a, 3);
    u.mul(&local1, &local2);
}

fn pipeline2() void {
    // r = 10 * u * (q * (5 * i - 2) + r - digit * t)
    local1.muli64(&u, 10);
    extra.muli64(&i, 5);
    local1b.subu64(&extra, 2);
    local1a.mul(&q, &local1b);
    local2a.add(&local1a, &r);
    local2b.mul(&t, &digit);
    local2.sub(&local2a, &local2b);
    r.mul(&local1, &local2);
}

fn pipeline3() void {
    // q = 10 * q * i * (2 * i - 1)
    gmp.mpz_mul_2exp(&local2.num, &i.num, 1);
    local1a.muli64(&i, 10);
    local1b.subu64(&local2, 1);
    local1.mul(&local1a, &local1b);
    q.mul(&q, &local1);
}

fn pipeline4() void {
    // t = t * u
    t.mul(&t, &u);

    // i++
    i.addu64(&i, 1);
}


fn next() u8 {
    pipeline1A(); pipeline1B();    
    pipeline2();
    pipeline3();    
    pipeline4();

    return As.u8(gmp.mpz_get_ui(&digit.num));
}

pub fn main() !void {
    vexlib.init(&allocator);

    const start = Time.millis();

    // globals
    q = BigInt.allocSet(1);
    r = BigInt.allocSet(180);
    t = BigInt.allocSet(60);
    i = BigInt.allocSet(2);
    defer q.dealloc();
    defer r.dealloc();
    defer t.dealloc();
    defer i.dealloc();

    // locals
    digit = BigInt.alloc();
    u = BigInt.alloc();
    local1 = BigInt.alloc();
    local1a = BigInt.alloc();
    local1b = BigInt.alloc();
    local2 = BigInt.alloc();
    local2a = BigInt.alloc();
    local2b = BigInt.alloc();
    extra = BigInt.alloc();
    defer digit.dealloc();
    defer u.dealloc();
    defer local1.dealloc();
    defer local1a.dealloc();
    defer local1b.dealloc();
    defer local2.dealloc();
    defer local2a.dealloc();
    defer local2b.dealloc();
    defer extra.dealloc();

    const outFile = try std.fs.cwd().createFile(
        "./output.txt",
        .{ .read = false },
    );

    const outCopyFile = try std.fs.cwd().createFile(
        "./output-copy.txt",
        .{ .read = false },
    );

    var idx: u32 = 0;
    var chunk = try allocator.alloc(u8, 1000);
    defer allocator.free(chunk);
    var chunkIdx: usize = 0;
    while (true) : (idx += 1) {
        // add 48 to convert decimal to ascii
        chunk[chunkIdx] = 48 + next();
        chunkIdx += 1;

        if (chunkIdx == 1000) {
            // write chunk
            try outFile.writeAll(chunk);
            try outCopyFile.writeAll(chunk);

            // print statistics
            const timeMillis = Time.millis() - start;
            const seconds = @as(f64, @floatFromInt(timeMillis)) / 1000.0;
            var formattedSeconds = vexlib.Float.toFixed(seconds, 2);
            defer formattedSeconds.dealloc();
            std.debug.print("{} digits in {s}s\n", .{idx+1, formattedSeconds.raw()});

            // setup to create new chunk
            chunkIdx = 0;
        }
    }
}
