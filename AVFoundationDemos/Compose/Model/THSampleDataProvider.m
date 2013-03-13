//
//  MIT License
//
//  Copyright (c) 2013 Bob McCune http://bobmccune.com/
//  Copyright (c) 2013 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#import "THSampleDataProvider.h"

@interface THSampleDataProvider ()
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, assign) CGFloat maxWidth;
@end

@implementation THSampleDataProvider

- (id)initWithAsset:(AVAsset *)asset maxWidth:(CGFloat)maxWidth {
	self = [super init];
	if (self) {
		_asset = asset;
		_maxWidth = maxWidth;
	}
	return self;
}

/*
 * WARNING: Lots of assumptions are being made in this code about the nature of the audio files.
 * Don't consider this a generally applicable way of reading audio data.
 */
- (void)loadSamples:(SampleDataBlock)block {

	NSError *error = nil;
	AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];

	if (!assetReader) {
		NSLog(@"Error initializing AVAssetReader: %@", [error localizedDescription]);
		return;
	}

	AVAssetTrack *track = [self.asset.tracks objectAtIndex:0];

	NSDictionary *outputSettings = (@{
			AVFormatIDKey : @(kAudioFormatLinearPCM),
			AVSampleRateKey : @44100.0f,
			AVNumberOfChannelsKey : @1,
			AVLinearPCMBitDepthKey : @16,
			AVLinearPCMIsBigEndianKey : @NO,
			AVLinearPCMIsFloatKey : @NO,
			AVLinearPCMIsNonInterleaved : @NO
	});


	AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track
	                                                                         outputSettings:outputSettings];
	[assetReader addOutput:trackOutput];


	NSMutableData *sampleData = [NSMutableData data];
	[assetReader startReading];

	while (assetReader.status == AVAssetReaderStatusReading) {

		CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];

		if (sampleBufferRef) {

			CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
			size_t length = CMBlockBufferGetDataLength(blockBufferRef);
			SInt16 sampleBytes[length];
			CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes);
			[sampleData appendBytes:sampleBytes length:length];
			CMSampleBufferInvalidate(sampleBufferRef);
			CFRelease(sampleBufferRef);
		}
	}

	if (assetReader.status == AVAssetReaderStatusFailed || assetReader.status == AVAssetReaderStatusUnknown) {
		block(nil);
	} else {
		block(sampleData);
	}
}

@end
