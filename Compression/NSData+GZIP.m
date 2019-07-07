#import "NSData+GZIP.h"
#import <zlib.h>
#define CHUNK 0x4000

@implementation NSData(GZIP)

+ (BOOL)gunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile {
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
						inflateEnd(&stream);
						return NO;
				}
				unsigned have = (CHUNK - stream.avail_out);
				fwrite(outputBuffer, sizeof(unsigned char), have, outputFileHandle);
			}
			while (stream.avail_out == 0);
			if (feof(inputFileHandle)) {
				inflateEnd (&stream);
				return YES;
			}
		}
	}
	return NO;
}

@end
