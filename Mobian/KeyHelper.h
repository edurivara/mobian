//
//  KeyHelper.h
//  SafeSound
//
//  Created by Demetri Miller on 10/22/2010
//  Copyright 2010 Demetri Miller. All rights reserved.
//

/*
 *	This class is a singleton providing globally accessible methods 
 *	and properties that may be needed by multiple classes wanting to map frequency
 *	values to pitches (e.g. A, Bb, C, F#, etc).
 */


#import <Foundation/Foundation.h>

@interface KeyHelper : NSObject {
	NSMutableDictionary *keyMapping;
	NSMutableDictionary *frequencyMapping;
}

@property(nonatomic, strong) NSMutableDictionary *keyMapping;
@property(nonatomic, strong) NSMutableDictionary *frequencyMapping;

#pragma mark Key Generation
- (void)buildKeyMapping;
- (NSArray *)closestCharForFrequency:(float)frequency;
- (NSNumber *)frequencyForChar:(NSString *)letra;

#pragma mark Singleton Methods
+ (KeyHelper *)sharedInstance;


@end