# 3.8 File uploads

## PASS
```ts
import { fileTypeFromBuffer } from "file-type"

const ALLOWED = new Set(["image/png", "image/jpeg", "image/webp"])
const MAX = 5 * 1024 * 1024  // 5MB

async function handleUpload(file: File, ownerId: string) {
  if (file.size > MAX) throw new Error("too large")

  const buf = Buffer.from(await file.arrayBuffer())
  const sniffed = await fileTypeFromBuffer(buf)        // sniff magic bytes
  if (!sniffed || !ALLOWED.has(sniffed.mime)) throw new Error("bad type")

  const id  = crypto.randomUUID()                       // server-generated name
  const key = `u/${ownerId}/${id}.${sniffed.ext}`

  await s3.putObject({
    Bucket: "uploads",
    Key: key,
    Body: buf,
    ContentType: sniffed.mime,
    Metadata: { "uploaded-by": ownerId },
  })
  return id
}
```

## Rules

- Sniff content type from magic bytes. Never trust `Content-Type` header or filename extension.
- Server-generates the filename. Discard the client name (or store as metadata only, never use as a path).
- Store outside the web root, or behind a signed-URL endpoint.
- Re-encode images server-side (`sharp` / ImageMagick) to strip embedded scripts and EXIF.
- Never execute uploaded files. Set `Content-Disposition: attachment` for downloads.
- Scan with ClamAV / VirusTotal for high-risk surfaces (anything user-shareable).
- Cap total upload count and total bytes per user.
- Reject double-extension names (`evil.php.png`), zero-byte files, and files with paths in their name (`../../etc/passwd`).
