//
//  ZipExtractor.m
//  Vital Synth
//
//  Parses the ZIP central directory and decompresses deflated entries
//  using libz with raw inflate (inflateInit2 window=-15, no zlib header).
//

#import "ZipExtractor.h"
#import <zlib.h>

// ZIP signatures
static const uint32_t kLocalSig   = 0x04034b50;
static const uint32_t kCentralSig = 0x02014b50;
static const uint32_t kEOCDSig    = 0x06054b50;

static inline uint16_t u16(const uint8_t *p) {
    return (uint16_t)(p[0] | (p[1] << 8));
}
static inline uint32_t u32(const uint8_t *p) {
    return (uint32_t)(p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24));
}

@implementation ZipExtractor

+ (nullable NSArray<NSURL *> *)extractZip:(NSURL *)zipURL
                              toDirectory:(NSURL *)destDir
                            fileExtension:(NSString *)ext
                                    error:(NSError **)error {
    NSData *zip = [NSData dataWithContentsOfURL:zipURL
                                        options:NSDataReadingMappedIfSafe
                                          error:error];
    if (!zip) return nil;

    const uint8_t *b = (const uint8_t *)zip.bytes;
    NSUInteger n = zip.length;

    // ── Find End of Central Directory ──────────────────────────────────────
    NSUInteger eocd = NSNotFound;
    for (NSInteger i = (NSInteger)n - 22; i >= 0; i--) {
        if (u32(b + i) == kEOCDSig) { eocd = (NSUInteger)i; break; }
    }
    if (eocd == NSNotFound) {
        if (error) *error = [NSError errorWithDomain:@"ZipExtractor" code:-1
            userInfo:@{NSLocalizedDescriptionKey: @"Not a valid ZIP file"}];
        return nil;
    }

    uint16_t totalEntries = u16(b + eocd + 10);
    uint32_t cdOffset     = u32(b + eocd + 16);

    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtURL:destDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSMutableArray<NSURL *> *results = [NSMutableArray array];
    NSString *lext = ext.lowercaseString;
    NSUInteger pos = cdOffset;

    // ── Walk Central Directory ─────────────────────────────────────────────
    for (int e = 0; e < totalEntries && pos + 46 <= n; e++) {
        if (u32(b + pos) != kCentralSig) break;

        uint16_t method    = u16(b + pos + 10);
        uint32_t cSize     = u32(b + pos + 20);
        uint32_t uSize     = u32(b + pos + 24);
        uint16_t fnLen     = u16(b + pos + 28);
        uint16_t exLen     = u16(b + pos + 30);
        uint16_t cmtLen    = u16(b + pos + 32);
        uint32_t lhOffset  = u32(b + pos + 42);

        NSString *name = [[NSString alloc] initWithBytes:b + pos + 46
                                                  length:fnLen
                                                encoding:NSUTF8StringEncoding];
        if (!name) name = [[NSString alloc] initWithBytes:b + pos + 46
                                                   length:fnLen
                                                 encoding:NSISOLatin1StringEncoding];
        pos += 46 + fnLen + exLen + cmtLen;

        // Skip directories and non-matching extensions
        if (!name || [name hasSuffix:@"/"] ||
            ![name.pathExtension.lowercaseString isEqualToString:lext]) continue;

        // Read local header for actual data offset
        if (lhOffset + 30 > n) continue;
        if (u32(b + lhOffset) != kLocalSig) continue;
        uint16_t lhFnLen = u16(b + lhOffset + 26);
        uint16_t lhExLen = u16(b + lhOffset + 28);
        NSUInteger dataStart = lhOffset + 30 + lhFnLen + lhExLen;
        if (dataStart + cSize > n) continue;

        const uint8_t *src = b + dataStart;

        // ── Decompress ─────────────────────────────────────────────────────
        NSData *fileData = nil;
        if (method == 0) {
            // Stored — no compression
            fileData = [NSData dataWithBytes:src length:cSize];
        } else if (method == 8 && uSize > 0) {
            // Deflate — raw inflate (window = -15)
            NSMutableData *out = [NSMutableData dataWithLength:uSize];
            z_stream zs;
            memset(&zs, 0, sizeof(zs));
            zs.next_in  = (Bytef *)src;
            zs.avail_in = cSize;
            zs.next_out = (Bytef *)out.mutableBytes;
            zs.avail_out = uSize;
            if (inflateInit2(&zs, -15) == Z_OK) {
                int r = inflate(&zs, Z_FINISH);
                inflateEnd(&zs);
                if (r == Z_STREAM_END) {
                    out.length = zs.total_out;
                    fileData = out;
                }
            }
        }

        if (!fileData) continue;

        // Write — flatten to filename only (strip in-archive path)
        NSString *baseName = name.lastPathComponent;
        NSURL *dest = [destDir URLByAppendingPathComponent:baseName];
        if ([fileData writeToURL:dest atomically:YES]) {
            [results addObject:dest];
        }
    }

    return results;
}

@end
