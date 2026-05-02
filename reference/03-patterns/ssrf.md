# 3.7 Server-side request forgery (SSRF)

## FAIL
```ts
const r = await fetch(req.body.url)  // user-supplied URL fetched from server
```

## PASS
```ts
import dns from "dns/promises"
import ipaddr from "ipaddr.js"

async function safeFetch(input: string) {
  const u = new URL(input)
  if (!["http:", "https:"].includes(u.protocol)) throw new Error("bad protocol")

  const addrs = await dns.resolve(u.hostname)
  for (const a of addrs) {
    const ip = ipaddr.parse(a)
    if (ip.range() !== "unicast") throw new Error("private IP")
  }
  return fetch(u, { redirect: "error", signal: AbortSignal.timeout(5000) })
}
```

## Block

- `127.0.0.0/8`, `::1` (loopback)
- `169.254.0.0/16`, `fe80::/10` (link-local — includes cloud metadata `169.254.169.254`)
- `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `fc00::/7` (private)
- `0.0.0.0`, `::`

Disallow redirects (`redirect: "error"`) or re-validate after each redirect. Set a hard timeout. Consider an egress allowlist for production.

> **DNS rebinding:** the IP set returned at handshake time can differ from the IP set returned by the pre-flight DNS check. For high-stakes flows, resolve once, pin the IP, and dial that IP directly with the original `Host:` header.
