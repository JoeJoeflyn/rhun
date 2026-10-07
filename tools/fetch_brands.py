#!/usr/bin/env python3
"""Fetches simple-icons.org brand paths (CC0) into assets/icons/providers/contours.json.
Each slug's single SVG 'd' path is flattened to polylines on the 128x128 icon grid
(scale 24 -> 128), simplified to <= 240 points per contour (the F op's byte limit),
and appended after the hand-drawn entries so existing icon indices never shift.
Re-run to refresh brands: python3 tools/fetch_brands.py && python3 tools/icons.py"""
import json, math, os, re, urllib.request

# icon name -> simple-icons slug
BRANDS = {
    'B_RUST': 'rust', 'B_PY': 'python', 'B_JS': 'javascript', 'B_TS': 'typescript',
    'B_GO': 'go', 'B_RUBY': 'ruby', 'B_PHP': 'php', 'B_C': 'c', 'B_CPP': 'cplusplus',
    'B_JAVA': 'openjdk', 'B_KOTLIN': 'kotlin', 'B_SWIFT': 'swift', 'B_HS': 'haskell',
    'B_EX': 'elixir', 'B_ERL': 'erlang', 'B_DART': 'dart', 'B_ZIG': 'zig',
    'B_NIM': 'nim', 'B_LUA': 'lua', 'B_PERL': 'perl', 'B_R': 'r', 'B_JL': 'julia',
    'B_CLJ': 'clojure', 'B_SCALA': 'scala', 'B_FS': 'fsharp', 'B_CS': 'dotnet',
    'B_FORTRAN': 'fortran', 'B_OCAML': 'ocaml', 'B_ELM': 'elm', 'B_CRYSTAL': 'crystal',
    'B_D': 'd', 'B_SOL': 'solidity', 'B_GRAPHQL': 'graphql', 'B_PRISMA': 'prisma',
    'B_ARDUINO': 'arduino', 'B_WASM': 'webassembly', 'B_HTML': 'html5', 'B_CSS': 'css',
    'B_SASS': 'sass', 'B_VUE': 'vuedotjs', 'B_SVELTE': 'svelte', 'B_ASTRO': 'astro',
    'B_COFFEE': 'coffeescript', 'B_GROOVY': 'apachegroovy', 'B_RACKET': 'racket',
    'B_EMACS': 'gnuemacs', 'B_CLISP': 'commonlisp', 'B_HAXE': 'haxe',
    'B_NUSHELL': 'nushell', 'B_VALA': 'vala', 'B_PURS': 'purescript', 'B_V': 'v',
    'B_VIM': 'vim', 'B_JINJA': 'jinja', 'B_HBS': 'handlebarsdotjs',
    'B_JUPYTER': 'jupyter',
}
URL = 'https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/%s.svg'
SCALE = 128.0 / 24.0
MAXPTS = 240

TOK = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?')

def cubic(p0, p1, p2, p3, t):
    u = 1 - t
    return (u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0],
            u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1])

def quad(p0, p1, p2, t):
    u = 1 - t
    return (u*u*p0[0] + 2*u*t*p1[0] + t*t*p2[0],
            u*u*p0[1] + 2*u*t*p1[1] + t*t*p2[1])

def arc(p0, rx, ry, rot, laf, sf, p1):
    # SVG endpoint -> center parameterization, sampled on the ellipse
    rx, ry = abs(rx), abs(ry)
    phi = math.radians(rot)
    dx, dy = (p0[0]-p1[0])/2, (p0[1]-p1[1])/2
    x1p = math.cos(phi)*dx + math.sin(phi)*dy
    y1p = -math.sin(phi)*dx + math.cos(phi)*dy
    lam = (x1p/rx)**2 + (y1p/ry)**2
    if lam > 1:
        s = math.sqrt(lam); rx, ry = rx*s, ry*s
    den = rx*rx*y1p*y1p + ry*ry*x1p*x1p
    co = math.sqrt(max(0, (rx*rx*ry*ry - den) / den)) * (1 if laf != sf else -1)
    cxp = co * rx * y1p / ry
    cyp = -co * ry * x1p / rx
    cx = math.cos(phi)*cxp - math.sin(phi)*cyp + (p0[0]+p1[0])/2
    cy = math.sin(phi)*cxp + math.cos(phi)*cyp + (p0[1]+p1[1])/2
    def ang(ux, uy, vx, vy):
        d = math.hypot(ux, uy) * math.hypot(vx, vy)
        a = math.acos(max(-1, min(1, (ux*vx + uy*vy) / d)))
        return -a if ux*vy - uy*vx < 0 else a
    th0 = ang(1, 0, (x1p-cxp)/rx, (y1p-cyp)/ry)
    dth = ang((x1p-cxp)/rx, (y1p-cyp)/ry, (-x1p-cxp)/rx, (-y1p-cyp)/ry)
    if not sf and dth > 0: dth -= 2*math.pi
    if sf and dth < 0: dth += 2*math.pi
    n = max(4, int(abs(dth) * max(rx, ry) * SCALE / 2.0))
    return [(cx + rx*math.cos(th0 + dth*i/n) * math.cos(phi)
             - ry*math.sin(th0 + dth*i/n) * math.sin(phi),
             cy + rx*math.cos(th0 + dth*i/n) * math.sin(phi)
             + ry*math.sin(th0 + dth*i/n) * math.cos(phi)) for i in range(1, n + 1)]

def flatten(d):
    toks = TOK.findall(d)
    i = 0
    out, cur, pos, start, pc, pq = [], None, (0, 0), (0, 0), None, None
    def num():
        nonlocal i
        v = float(toks[i]); i += 1; return v
    def flag():
        # arc flags are single chars and may be packed against the next coord (svgo "018" = 0,1,8)
        nonlocal i
        t = toks[i]
        if len(t) > 1:
            toks[i] = t[1:]
            return int(t[0])
        i += 1
        return int(t)
    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]; i += 1
        else:
            cmd = 'L' if cmd == 'M' else ('l' if cmd == 'm' else cmd)   # implicit lineto
        rel = cmd.islower(); C = cmd.upper()
        if cur is None and C != 'Z' and C != 'M':
            cur = [pos]
        if C == 'Z':
            if cur: out.append(cur)
            cur = None; pos = start; pc = pq = None; continue
        if C == 'M':
            if cur: out.append(cur)
            x, y = num(), num()
            pos = (pos[0]+x, pos[1]+y) if rel else (x, y)
            start = pos; cur = [pos]; pc = pq = None; continue
        def pt():
            x, y = num(), num()
            return (pos[0]+x, pos[1]+y) if rel else (x, y)
        if C == 'L':
            pos = pt(); cur.append(pos)
        elif C == 'H':
            x = num(); pos = (pos[0]+x, pos[1]) if rel else (x, pos[1]); cur.append(pos)
        elif C == 'V':
            y = num(); pos = (pos[0], pos[1]+y) if rel else (pos[0], y); cur.append(pos)
        elif C == 'C' or C == 'S':
            if C == 'S':
                p1 = (2*pos[0]-pc[0], 2*pos[1]-pc[1]) if pc else pos
            else:
                p1 = pt()
            p2, p3 = pt(), pt()
            ln = math.dist(pos, p1) + math.dist(p1, p2) + math.dist(p2, p3)
            for k in range(1, max(4, int(ln * SCALE / 2.0)) + 1):
                cur.append(cubic(pos, p1, p2, p3, k / max(4, int(ln * SCALE / 2.0))))
            pos, pc, pq = p3, p2, None
        elif C == 'Q' or C == 'T':
            if C == 'T':
                p1 = (2*pos[0]-pq[0], 2*pos[1]-pq[1]) if pq else pos
            else:
                p1 = pt()
            p2 = pt()
            ln = math.dist(pos, p1) + math.dist(p1, p2)
            n = max(4, int(ln * SCALE / 2.0))
            for k in range(1, n + 1):
                cur.append(quad(pos, p1, p2, k / n))
            pos, pq, pc = p2, p1, None
        elif C == 'A':
            rx, ry, rot, laf, sf = num(), num(), num(), flag(), flag()
            p1 = pt()
            pts = arc(pos, rx, ry, rot, int(laf), int(sf), p1)
            cur += pts; pos = p1; pc = pq = None
        else:
            pc = pq = None
    if cur: out.append(cur)
    return out

def dp(pts, eps):
    if len(pts) < 3:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]; bx, by = pts[b]
        ln = math.hypot(bx-ax, by-ay)
        dmax, imax = -1, -1
        for k in range(a+1, b):
            px, py = pts[k]
            d = (abs((bx-ax)*(ay-py) - (ax-px)*(by-ay)) / ln) if ln else math.dist(pts[a], pts[k])
            if d > dmax: dmax, imax = d, k
        if dmax > eps:
            keep[imax] = True
            stack += [(a, imax), (imax, b)]
    return [p for p, k in zip(pts, keep) if k]

def simplify(pts):
    scaled = [(x * SCALE, y * SCALE) for x, y in pts]
    eps = 0.35
    while True:
        simp = dp(scaled, eps)
        ints = []
        for x, y in simp:
            p = (min(255, max(0, round(x))), min(255, max(0, round(y))))
            if not ints or ints[-1] != p:
                ints.append(p)
        if len(ints) <= MAXPTS or eps > 4:
            return ints
        eps *= 1.6

def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
    path = os.path.join(root, 'assets/icons/providers/contours.json')
    data = json.load(open(path))
    for name, slug in BRANDS.items():
        svg = urllib.request.urlopen(URL % slug).read().decode()
        d = re.search(r'\bd="([^"]+)"', svg).group(1)
        vb = [float(v) for v in (re.search(r'viewBox="([^"]+)"', svg).group(1).split())]
        assert vb == [0.0, 0.0, 24.0, 24.0], (name, vb)
        contours = [c for c in (simplify(c) for c in flatten(d)) if len(c) >= 3]
        data[name] = [[[x, y] for x, y in c] for c in contours]
        print('%-10s %-18s %d contours, %d pts' % (name, slug, len(contours), sum(map(len, contours))))
    with open(path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
        f.write('\n')

if __name__ == '__main__':
    main()
