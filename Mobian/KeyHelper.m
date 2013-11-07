//
//  KeyHelper.m
//  Mobian2
//


#import "KeyHelper.h"

@implementation KeyHelper

@synthesize keyMapping;
@synthesize frequencyMapping;

- (void)buildKeyMapping {
	self.keyMapping = [[NSMutableDictionary alloc] initWithCapacity:9];
	[keyMapping setObject:[NSNumber numberWithFloat:1248] forKey:@"Start"];
	[keyMapping setObject:[NSNumber numberWithFloat:2500] forKey:@"0"];
	[keyMapping setObject:[NSNumber numberWithFloat:2650] forKey:@"1"];
	[keyMapping setObject:[NSNumber numberWithFloat:2800] forKey:@"2"];
	[keyMapping setObject:[NSNumber numberWithFloat:2950] forKey:@"3"];
	[keyMapping setObject:[NSNumber numberWithFloat:3100] forKey:@"4"];
	[keyMapping setObject:[NSNumber numberWithFloat:3250] forKey:@"5"];
	[keyMapping setObject:[NSNumber numberWithFloat:3400] forKey:@"6"];
	[keyMapping setObject:[NSNumber numberWithFloat:3550] forKey:@"7"];
	[keyMapping setObject:[NSNumber numberWithFloat:3700] forKey:@"8"];
	[keyMapping setObject:[NSNumber numberWithFloat:3850] forKey:@"9"];
	
	self.frequencyMapping = [[NSMutableDictionary alloc] initWithCapacity:9];
	[frequencyMapping setObject:@"Start" forKey:[NSNumber numberWithFloat:1248]];
	[frequencyMapping setObject:@"0" forKey:[NSNumber numberWithFloat:2500]];
	[frequencyMapping setObject:@"1" forKey:[NSNumber numberWithFloat:2650]];
	[frequencyMapping setObject:@"2" forKey:[NSNumber numberWithFloat:2800]];
	[frequencyMapping setObject:@"3" forKey:[NSNumber numberWithFloat:2950]];
	[frequencyMapping setObject:@"4" forKey:[NSNumber numberWithFloat:3100]];
	[frequencyMapping setObject:@"5" forKey:[NSNumber numberWithFloat:3250]];
	[frequencyMapping setObject:@"6" forKey:[NSNumber numberWithFloat:3400]];
	[frequencyMapping setObject:@"7" forKey:[NSNumber numberWithFloat:3550]];
	[frequencyMapping setObject:@"8" forKey:[NSNumber numberWithFloat:3700]];
	[frequencyMapping setObject:@"9" forKey:[NSNumber numberWithFloat:3850]];

}

// Gets the character closest to the frequency passed in.
// Agregado un filtro, si la diferencia es mayor a x no devuelve
- (NSArray *)closestCharForFrequency:(float)frequency {
	NSString *closestKey = nil;
	float closestFloat = MAXFLOAT;	// Init to largest float value so all ranges closer.
	
	// Check each values distance to the actual frequency.
	for(NSNumber *num in [keyMapping allValues]) {
		float mappedFreq = [num floatValue];
		float tempVal = fabsf(mappedFreq-frequency);
		if (tempVal < closestFloat) {
			closestFloat = tempVal;
			closestKey = [frequencyMapping objectForKey:num];
		}
	}
    NSNumber *proximity = [[NSNumber alloc] initWithFloat:closestFloat];
	NSArray *closestArray = [[NSArray alloc] initWithObjects:closestKey, proximity, nil];
    
	return closestArray;
}

- (NSNumber *)frequencyForChar:(NSString *)letra{
	NSNumber *frequencia;
	
    frequencia = [keyMapping objectForKey:letra];
    
	return frequencia;
}



static KeyHelper *sharedInstance = nil;

#pragma mark -
#pragma mark Singleton Methods
+ (KeyHelper *)sharedInstance
{
	if (sharedInstance == nil) {
		sharedInstance = [[KeyHelper alloc] init];
		[sharedInstance buildKeyMapping];
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
@end
