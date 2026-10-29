#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 PCAPdroid 导出的 pcap 中重组 TCP 流并提取 HTTP 请求/响应。
纯标准库实现，不依赖 scapy/tshark。

用法:
  python3 pcap_http.py <file.pcap> [--json out.json] [--list] [--dump] [--filter SUBSTR]

  --list     只列出所有请求行 + 状态码 + 响应长度（概览）
  --dump     打印完整请求/响应体
  --filter   只输出 URI 或 body 含该子串的事务
  --json     导出结构化 JSON
"""
import struct
import sys
import json
import gzip
import zlib

LINK_RAW = 101
LINK_ETHERNET = 1
LINK_LINUX_SLL = 113
LINK_LINUX_SLL2 = 276


def iter_packets(path):
    data = open(path, "rb").read()
    magic = data[:4]
    if magic == b"\xd4\xc3\xb2\xa1":
        endian = "<"
    elif magic == b"\xa1\xb2\xc3\xd4":
        endian = ">"
    elif magic == b"\x4d\x3c\xb2\xa1":
        endian = "<"
    elif magic == b"\xa1\xb2\x3c\x4d":
        endian = ">"
    else:
        raise SystemExit("不是 pcap 文件: %r" % magic)
    link = struct.unpack(endian + "I", data[20:24])[0]
    off = 24
    n = len(data)
    while off + 16 <= n:
        ts_s, ts_us, incl, orig = struct.unpack(endian + "IIII", data[off:off + 16])
        off += 16
        if off + incl > n:
            break
        yield ts_s + ts_us / 1e6, link, data[off:off + incl]
        off += incl


def parse_ip(pkt, link):
    if link == LINK_ETHERNET:
        if len(pkt) < 14:
            return None
        ethertype = struct.unpack(">H", pkt[12:14])[0]
        p = 14
        while ethertype in (0x8100, 0x88A8) and len(pkt) >= p + 4:
            ethertype = struct.unpack(">H", pkt[p + 2:p + 4])[0]
            p += 4
        if ethertype != 0x0800:
            return None
        ip = pkt[p:]
    elif link == LINK_LINUX_SLL:
        if len(pkt) < 16:
            return None
        if struct.unpack(">H", pkt[14:16])[0] != 0x0800:
            return None
        ip = pkt[16:]
    elif link == LINK_LINUX_SLL2:
        if len(pkt) < 20:
            return None
        if struct.unpack(">H", pkt[0:2])[0] != 0x0800:
            return None
        ip = pkt[20:]
    else:  # RAW
        ip = pkt
    if len(ip) < 20:
        return None
    vihl = ip[0]
    if (vihl >> 4) != 4:
        return None
    ihl = (vihl & 0x0F) * 4
    if len(ip) < ihl:
        return None
    proto = ip[9]
    total_len = struct.unpack(">H", ip[2:4])[0]
    src = ".".join(str(b) for b in ip[12:16])
    dst = ".".join(str(b) for b in ip[16:20])
    payload = ip[ihl:total_len] if total_len >= ihl else ip[ihl:]
    return proto, src, dst, payload


def parse_tcp(payload):
    if len(payload) < 20:
        return None
    sport, dport = struct.unpack(">HH", payload[0:4])
    seq = struct.unpack(">I", payload[4:8])[0]
    doff = (payload[12] >> 4) * 4
    flags = payload[13]
    if len(payload) < doff:
        return None
    return sport, dport, seq, flags, payload[doff:]


class Stream:
    """单方向 TCP 流重组"""

    def __init__(self):
        self.segs = {}      # seq -> bytes
        self.isn = None

    def add(self, seq, data):
        if not data:
            return
        if self.isn is None:
            self.isn = seq
        rel = (seq - self.isn) & 0xFFFFFFFF
        if rel > 0x7FFFFFFF:  # 回绕/乱序，保守丢弃
            rel = 0
        self.segs[rel] = data

    def bytes(self):
        if not self.segs:
            return b""
        out = bytearray()
        MAX_GAP = 65536          # 超过这个大小的空洞不填充（乱序/重传噪声）
        for rel in sorted(self.segs):
            if rel > len(out):
                gap = rel - len(out)
                if gap > MAX_GAP:
                    # 空洞过大，说明前面丢了或 seq 基准被污染，
                    # 直接丢弃这一段，避免分配巨量内存
                    continue
                out.extend(b"\x00" * gap)
            chunk = self.segs[rel]
            if rel + len(chunk) <= len(out):
                continue
            if rel < len(out):
                chunk = chunk[len(out) - rel:]
            out.extend(chunk)
        return bytes(out)


def find_headers_end(buf, start):
    idx = buf.find(b"\r\n\r\n", start)
    return idx


def parse_http_stream(buf, is_request):
    """把一个方向的流切成多个 HTTP 消息"""
    msgs = []
    pos = 0
    n = len(buf)
    while pos < n:
        # 跳过前导空行/垃圾
        while pos < n and buf[pos:pos + 2] in (b"\r\n", b"\n"):
            pos += 2 if buf[pos:pos + 2] == b"\r\n" else 1
        if pos >= n:
            break
        he = find_headers_end(buf, pos)
        if he < 0:
            break
        head = buf[pos:he]
        body_start = he + 4
        try:
            head_txt = head.decode("utf-8", "replace")
        except Exception:
            break
        lines = head_txt.split("\r\n")
        if not lines:
            break
        first = lines[0]
        if is_request:
            if not (first.startswith(("GET ", "POST ", "PUT ", "DELETE ", "PATCH ", "HEAD ", "OPTIONS "))):
                # 不是请求，尝试找下一个
                nxt = buf.find(b"\r\n\r\n", body_start)
                if nxt < 0:
                    break
                pos = nxt + 4
                continue
        else:
            if not first.startswith("HTTP/"):
                nxt = buf.find(b"\r\n\r\n", body_start)
                if nxt < 0:
                    break
                pos = nxt + 4
                continue
        headers = {}
        for ln in lines[1:]:
            if ":" in ln:
                k, v = ln.split(":", 1)
                headers[k.strip().lower()] = v.strip()
        # 决定 body 长度
        clen = headers.get("content-length")
        chunked = headers.get("transfer-encoding", "").lower() == "chunked"
        body = b""
        if chunked:
            p = body_start
            chunks = []
            while p < n:
                eol = buf.find(b"\r\n", p)
                if eol < 0:
                    break
                try:
                    sz = int(buf[p:eol].split(b";")[0].strip(), 16)
                except Exception:
                    break
                p = eol + 2
                if sz == 0:
                    if buf[p:p + 2] == b"\r\n":
                        p += 2
                    break
                chunks.append(buf[p:p + sz])
                p += sz + 2
            body = b"".join(chunks)
            pos = p
        elif clen is not None:
            try:
                ln = int(clen)
            except Exception:
                ln = 0
            body = buf[body_start:body_start + ln]
            pos = body_start + ln
        else:
            # 无长度：读到流末尾（对响应是 keep-alive 无法判断，这里读到下一个 HTTP/ 前）
            nxt = buf.find(b"HTTP/", body_start)
            if nxt < 0:
                body = buf[body_start:]
                pos = n
            else:
                body = buf[body_start:nxt]
                pos = nxt
        # 解压
        dec = body
        enc = headers.get("content-encoding", "").lower()
        try:
            if "gzip" in enc:
                dec = gzip.decompress(body)
            elif "deflate" in enc:
                dec = zlib.decompress(body)
        except Exception:
            dec = body
        msgs.append({
            "first_line": first,
            "headers": headers,
            "body_raw": body,
            "body": dec,
        })
    return msgs


def main():
    args = [a for a in sys.argv[1:]]
    if not args:
        print(__doc__)
        return
    path = args[0]
    want_list = "--list" in args
    want_dump = "--dump" in args
    filt = None
    out_json = None
    ports = {80, 3000, 3001, 8080}
    for i, a in enumerate(args):
        if a == "--filter" and i + 1 < len(args):
            filt = args[i + 1]
        if a == "--json" and i + 1 < len(args):
            out_json = args[i + 1]
        if a == "--any-port":
            ports = None
        if a == "--ports" and i + 1 < len(args):
            ports = {int(x) for x in args[i + 1].split(",")}

    streams = {}
    order = []
    first_ts = {}
    last_ts = {}
    for ts, link, pkt in iter_packets(path):
        r = parse_ip(pkt, link)
        if not r:
            continue
        proto, src, dst, ippayload = r
        if proto != 6:
            continue
        t = parse_tcp(ippayload)
        if not t:
            continue
        sport, dport, seq, flags, data = t
        if not data:
            continue
        if ports is not None and dport not in ports and sport not in ports:
            continue
        key = (src, sport, dst, dport)
        if key not in streams:
            streams[key] = Stream()
            order.append(key)
            first_ts[key] = ts
        last_ts[key] = ts
        streams[key].add(seq, data)

    # 配对：把 (A->B) 和 (B->A) 组合成事务
    pairs = {}
    for key in order:
        src, sport, dst, dport = key
        rkey = (dst, dport, src, sport)
        pk = tuple(sorted([key, rkey]))
        pairs.setdefault(pk, []).append(key)

    transactions = []
    for pk, keys in pairs.items():
        if len(keys) != 2:
            continue
        # 每个流只重组一次，之后立刻释放，避免 80MB 抓包把内存吃爆
        bufs = {}
        for k in keys:
            bufs[k] = streams[k].bytes()
            streams[k] = None
        # 判断哪个方向是请求：看流开头
        c2s = s2c = None
        for k in keys:
            b = bufs[k]
            if b.startswith((b"GET ", b"POST ", b"PUT ", b"DELETE ", b"PATCH ", b"HEAD ", b"OPTIONS ")):
                c2s = k
            elif b.startswith(b"HTTP/"):
                s2c = k
        if c2s is None or s2c is None:
            # 兜底：包含 3000/3001 的是服务端
            for k in keys:
                if k[3] in (3000, 3001, 80, 8080):
                    s2c = k
                else:
                    c2s = k
        if c2s is None or s2c is None:
            bufs = None
            continue
        reqs = parse_http_stream(bufs[c2s], True)
        resps = parse_http_stream(bufs[s2c], False)
        bufs = None
        n = max(len(reqs), len(resps))
        for i in range(n):
            req = reqs[i] if i < len(reqs) else None
            resp = resps[i] if i < len(resps) else None
            transactions.append({
                "ts": first_ts.get(c2s, 0),
                "client": "%s:%d" % (c2s[0], c2s[1]),
                "server": "%s:%d" % (c2s[2], c2s[3]),
                "req": req,
                "resp": resp,
            })
    transactions.sort(key=lambda x: x["ts"])

    if out_json:
        serial = []
        for t in transactions:
            d = {"ts": t["ts"], "client": t["client"], "server": t["server"]}
            if t["req"]:
                d["request"] = {
                    "line": t["req"]["first_line"],
                    "headers": t["req"]["headers"],
                    "body": t["req"]["body"].decode("utf-8", "replace"),
                }
            if t["resp"]:
                d["response"] = {
                    "line": t["resp"]["first_line"],
                    "headers": t["resp"]["headers"],
                    "body": t["resp"]["body"].decode("utf-8", "replace"),
                }
            serial.append(d)
        open(out_json, "w", encoding="utf-8").write(
            json.dumps(serial, ensure_ascii=False, indent=1))
        print("已写入 %s (%d 个事务)" % (out_json, len(serial)), file=sys.stderr)

    for t in transactions:
        req = t["req"]
        resp = t["resp"]
        reqline = req["first_line"] if req else "(无请求)"
        respline = resp["first_line"] if resp else "(无响应)"
        blen = len(resp["body"]) if resp else 0
        hay = (reqline + " " + (resp["body"].decode("utf-8", "replace") if resp else "")
               + " " + (req["body"].decode("utf-8", "replace") if req else ""))
        if filt and filt not in hay:
            continue
        print("%10.3f  %-58s  %-16s body=%d" % (t["ts"], reqline[:58], respline[:16], blen))
        if want_dump:
            if req:
                print("  >>> REQ HEADERS:", {k: v for k, v in req["headers"].items()
                                             if k in ("authorization", "content-type", "content-length")})
                b = req["body"].decode("utf-8", "replace")
                if b:
                    print("  >>> REQ BODY:", b[:3000])
            if resp:
                b = resp["body"].decode("utf-8", "replace")
                if b:
                    print("  <<< RESP BODY:", b[:3000])
            print()


if __name__ == "__main__":
    main()
