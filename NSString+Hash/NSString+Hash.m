//
//  NSString+Hash.m
//  Magma
//
//  Created by PixelOmer on 17.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "NSString+Hash.h"
#import <objc/runtime.h>

@implementation NSString(Hash)

+ (instancetype)stringWithHashOfFile:(NSString *)filePath context:(void *)context initFunction:(void(*)(void *))init updateFunction:(void(*)(void *, void *, CC_LONG))update finalizeFunction:(void(*)(unsigned char *, void *))finalize digestLength:(unsigned int)digestLength {
	FILE *file = fopen(filePath.UTF8String, "r");
	if (!file) return nil;
	init(context);
	while (!feof(file)) {
		char data[0x1000];
		CC_LONG length = (CC_LONG)fread(data, 1, sizeof(data), file);
		update(context, data, length);
	}
	unsigned char hash[digestLength];
	finalize(hash, context);
	fclose(file);
	NSMutableString *finalString = [NSMutableString new];
	for (int i = 0; i < digestLength; i++) {
		[finalString appendFormat:@"%02x", hash[i]];
	}
	return finalString.copy;
}

+ (instancetype)stringWithMD5HashOfFileAtPath:(NSString *)path {
	CC_MD5_CTX context;
	return [self stringWithHashOfFile:path context:(void *)&context initFunction:(void(*)(void *))&CC_MD5_Init updateFunction:(void(*)(void *, void *, CC_LONG))&CC_MD5_Update finalizeFunction:(void(*)(unsigned char *, void *))&CC_MD5_Final digestLength:CC_MD5_DIGEST_LENGTH];
}

+ (instancetype)stringWithSHA256HashOfFileAtPath:(NSString *)path {
	CC_SHA256_CTX context;
	return [self stringWithHashOfFile:path context:(void *)&context initFunction:(void(*)(void *))&CC_SHA256_Init updateFunction:(void(*)(void *, void *, CC_LONG))&CC_SHA256_Update finalizeFunction:(void(*)(unsigned char *, void *))&CC_SHA256_Final digestLength:CC_SHA256_DIGEST_LENGTH];
}

+ (instancetype)stringWithSHA1HashOfFileAtPath:(NSString *)path {
	CC_SHA1_CTX context;
	return [self stringWithHashOfFile:path context:(void *)&context initFunction:(void(*)(void *))&CC_SHA1_Init updateFunction:(void(*)(void *, void *, CC_LONG))&CC_SHA1_Update finalizeFunction:(void(*)(unsigned char *, void *))&CC_SHA1_Final digestLength:CC_SHA1_DIGEST_LENGTH];
}

+ (instancetype)stringWithSHA512HashOfFileAtPath:(NSString *)path {
	CC_SHA512_CTX context;
	return [self stringWithHashOfFile:path context:(void *)&context initFunction:(void(*)(void *))&CC_SHA512_Init updateFunction:(void(*)(void *, void *, CC_LONG))&CC_SHA512_Update finalizeFunction:(void(*)(unsigned char *, void *))&CC_SHA512_Final digestLength:CC_SHA512_DIGEST_LENGTH];
}

+ (instancetype)stringWithHash:(NSString *)hash ofFileAtPath:(NSString *)path {
	SEL selector = NSSelectorFromString([NSString stringWithFormat:@"stringWith%@HashOfFileAtPath:", hash.uppercaseString]);
	return ((NSString *(*)(Class, SEL, NSString *))method_getImplementation(class_getClassMethod(self, selector)))(self, selector, path);
}

@end

