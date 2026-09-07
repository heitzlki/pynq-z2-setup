#!/usr/bin/env python3
"""Convert a Xilinx .bit file to the byte-swapped .bin that the Zynq-7000
fpga_manager kernel driver expects. Usage: bit2bin.py in.bit out.bin"""
import struct, sys

def bit2bin(data: bytes) -> bytes:
    pos = 0
    # initial header: 2-byte length + that many bytes, then 2-byte field
    n = struct.unpack(">H", data[pos:pos + 2])[0]; pos += 2 + n
    pos += 2
    while True:
        key = data[pos:pos + 1]; pos += 1
        if key == b"e":
            n = struct.unpack(">I", data[pos:pos + 4])[0]; pos += 4
            body = data[pos:pos + n]
            break
        n = struct.unpack(">H", data[pos:pos + 2])[0]; pos += 2
        print(f"{key.decode()}: {data[pos:pos + n].rstrip(b'\\0').decode(errors='replace')}", file=sys.stderr)
        pos += n
    words = struct.unpack(f">{len(body) // 4}I", body[: len(body) // 4 * 4])
    return struct.pack(f"<{len(words)}I", *words)

if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    out = bit2bin(open(src, "rb").read())
    open(dst, "wb").write(out)
    print(f"wrote {dst}: {len(out)} bytes", file=sys.stderr)
