#import "NSData+Decompression.h"
#import <zlib.h>
#import <bzlib.h>
#import "lzma.h"

@implementation NSData(Decompression)

// Source: https://stackoverflow.com/a/3912510/7085621
+ (BOOL)bunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile {
	BOOL success = YES;
	FILE *inputFileHandle = fopen(inputFile.UTF8String, "r");
	FILE *outputFileHandle = fopen(outputFile.UTF8String, "w");
	int bzError;
	BZFILE *BZ2InputFileHandle;
	char buf[4096];
	BZ2InputFileHandle = BZ2_bzReadOpen(&bzError, inputFileHandle, 0, 0, NULL, 0);
	if ((success = (bzError == BZ_OK))) {
		while (bzError == BZ_OK) {
			int nread = BZ2_bzRead(&bzError, BZ2InputFileHandle, buf, sizeof(buf));
			if (bzError == BZ_OK || bzError == BZ_STREAM_END) {
				size_t nwritten = fwrite(buf, 1, nread, outputFileHandle);
				if (nwritten != (size_t)nread) {
					success = NO;
					break;
				}
			}
		}
		if (bzError != BZ_STREAM_END) {
			success = NO;
		}
	}
	BZ2_bzReadClose(&bzError, BZ2InputFileHandle);
	fclose(inputFileHandle);
	fclose(outputFileHandle);
    return success;
}

#define CHUNK 0x4000
+ (BOOL)gunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile {
	NSNumber *success = nil;
	
	FILE *inputFileHandle = fopen(inputFile.UTF8String, "r");
	FILE *outputFileHandle = fopen(outputFile.UTF8String, "w");
	
	unsigned char inputBuffer[CHUNK];
	unsigned char outputBuffer[CHUNK];
	
	z_stream stream;
	
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
	stream.opaque = Z_NULL;
	stream.next_in = inputBuffer;
	stream.avail_in = 0;
	
	if (inflateInit2(&stream, 47) == Z_OK) {
		int status;
		while (true) {
			unsigned int bytes_read;
			bytes_read = (unsigned int)fread(inputBuffer, sizeof(char), sizeof(inputBuffer), inputFileHandle);
			stream.avail_in = bytes_read;
			stream.next_in = inputBuffer;
			do {
				stream.avail_out = CHUNK;
				stream.next_out = outputBuffer;
				status = inflate(&stream, Z_NO_FLUSH);
				switch (status) {
					case Z_OK:
					case Z_STREAM_END:
					case Z_BUF_ERROR:
						break;
					default:
						success = @NO;
						break;
				}
				if (success) break;
				unsigned have = (CHUNK - stream.avail_out);
				fwrite(outputBuffer, sizeof(unsigned char), have, outputFileHandle);
			}
			while (stream.avail_out == 0);
			if (success) break;
			if (feof(inputFileHandle)) {
				success = @YES;
				break;
			}
		}
		inflateEnd(&stream);
	}
	
	fclose(outputFileHandle);
	fclose(inputFileHandle);
	return success.boolValue;
}
#undef CHUNK

// Source: https://github.com/pixelomer/ARDecompression
#define CHUNK 0x800
+ (BOOL)unarchiveFileAtPath:(NSString *)path toDirectoryAtPath:(NSString *)targetDir {
	BOOL result = NO;
	FILE *inputHandle = fopen(path.UTF8String, "r");
	if (!inputHandle) return NO;
	if ([NSFileManager.defaultManager createDirectoryAtPath:targetDir withIntermediateDirectories:NO attributes:nil error:nil] || ![NSFileManager.defaultManager contentsOfDirectoryAtPath:targetDir error:nil].count) {
		char buffer[9];
		if (fread(buffer, 1, 8, inputHandle) && !strcmp(buffer, "!<arch>\n")) {
			char expectedSuffix[3];
			expectedSuffix[0] = 0x60;
			expectedSuffix[1] = '\n';
			expectedSuffix[2] = 0x0;
			BOOL shiftAttempt = NO;
			while(!feof(inputHandle)) {
#define read(size, output) if (fread(output, 1, size, inputHandle) != size) break; else output[size] = 0;
				char filename[17];
				char timestampStr[13];
				char fileSizeStr[11];
				char suffix[3];
				read(16, filename);
				read(12, timestampStr);
				fseek(inputHandle, 20, SEEK_CUR);
				read(10, fileSizeStr);
				read(2, suffix);
				if (!strcmp(suffix, expectedSuffix)) {
					shiftAttempt = NO;
					NSString *outputFile = [targetDir stringByAppendingPathComponent:[@(filename) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
#undef read
					FILE *outputFileHandle = fopen(outputFile.UTF8String, "w");
#define read(size, output) if (fread(output, 1, size, inputHandle) != size) break;
#define write(size) if (fwrite(buffer, 1, bytesToWrite, outputFileHandle) != size) break;
					if (!outputFileHandle) break;
					int timestamp = atoi(timestampStr);
					size_t remainingBytes = atoi(fileSizeStr);
					char buffer[CHUNK];
					while (remainingBytes > 0) {
						size_t bytesToWrite = (remainingBytes > CHUNK) ? CHUNK : remainingBytes;
						read(bytesToWrite, buffer);
						write(bytesToWrite);
						remainingBytes -= bytesToWrite;
					}
#undef write
#undef read
					fclose(outputFileHandle);
					if (remainingBytes > 0) break;
					[NSFileManager.defaultManager setAttributes:@{ NSFileModificationDate : [NSDate dateWithTimeIntervalSince1970:timestamp] } ofItemAtPath:outputFile error:nil];
					continue;
				}
				if (!shiftAttempt && (shiftAttempt = (suffix[1] == 0x60))) {
					fseek(inputHandle, -59, SEEK_CUR);
					continue;
				}
				break;
			}
			result = !!feof(inputHandle);
		}
	}
	fclose(inputHandle);
	return result;
}
#undef CHUNK

// Source: https://github.com/frida/xz/blob/master/doc/examples/02_decompress.c
+ (BOOL)extractUsingLZMAStream:(lzma_stream *)stream inputFile:(NSString *)inputFile outputFile:(NSString *)outputFile {
	FILE *inputFileHandle = fopen(inputFile.UTF8String, "r");
	if (!inputFileHandle) return NO;
	FILE *outputFileHandle = fopen(outputFile.UTF8String, "w");
	if (!outputFileHandle) {
		fclose(inputFileHandle);
		return NO;
	}
	lzma_action action = LZMA_RUN;

	uint8_t inputBuffer[BUFSIZ];
	uint8_t outputBuffer[BUFSIZ];
	
	BOOL result = NO;
	stream->next_in = NULL;
	stream->avail_in = 0;
	stream->next_out = outputBuffer;
	stream->avail_out = sizeof(outputBuffer);
	while (true) {
		if (stream->avail_in == 0 && !feof(inputFileHandle)) {
			stream->next_in = inputBuffer;
			stream->avail_in = fread(inputBuffer, 1, sizeof(inputBuffer), inputFileHandle);
			if (ferror(inputFileHandle)) break;
			if (feof(inputFileHandle)) action = LZMA_FINISH;
		}
		lzma_ret ret = lzma_code(stream, action);
		if (stream->avail_out == 0 || ret == LZMA_STREAM_END) {
			size_t writeSize = sizeof(outputBuffer) - stream->avail_out;
			if (fwrite(outputBuffer, 1, writeSize, outputFileHandle) != writeSize) break;
			stream->next_out = outputBuffer;
			stream->avail_out = sizeof(outputBuffer);
		}
		if (ret != LZMA_OK) {
			if (ret == LZMA_STREAM_END) result = YES;
			break;
		}
	}
	fclose(outputFileHandle);
	fclose(inputFileHandle);
	return result;
}

+ (BOOL)extractXZFileAtPath:(NSString *)inputFile toFileAtPath:(NSString *)targetPath {
	lzma_stream stream = LZMA_STREAM_INIT;
	if (lzma_stream_decoder(&stream, UINT64_MAX, LZMA_CONCATENATED) != LZMA_OK) return NO;
	return [self extractUsingLZMAStream:&stream inputFile:inputFile outputFile:targetPath];
}

+ (BOOL)extractLZMAFileAtPath:(NSString *)inputFile toFileAtPath:(NSString *)outputFile {
	lzma_stream stream = LZMA_STREAM_INIT;
	if (lzma_alone_decoder(&stream, UINT64_MAX) != LZMA_OK) return NO;
	return [self extractUsingLZMAStream:&stream inputFile:inputFile outputFile:outputFile];
}

@end
