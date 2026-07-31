//
//  ZipExtractor.h
//  Vital Synth
//
//  Minimal ZIP reader using libz raw-inflate. Extracts files from a ZIP
//  archive to a destination directory. No third-party dependencies.
//

#pragma once
#import <Foundation/Foundation.h>

@interface ZipExtractor : NSObject

/// Extract all entries whose filename ends in `extension` (e.g. @"vital")
/// from the ZIP at `zipURL` into `destDir`. Returns extracted file URLs.
+ (nullable NSArray<NSURL *> *)extractZip:(NSURL *)zipURL
                              toDirectory:(NSURL *)destDir
                            fileExtension:(NSString *)extension
                                    error:(NSError **)error;
@end
