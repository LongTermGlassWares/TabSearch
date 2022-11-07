// 
//  SearchItem.m
//
//  Copyright 2022 Long Term Glass Wares, LLC. All rights reserved.
//

#import "SearchItem.h"

@implementation SearchItem

# pragma mark Information Display

- (NSString *)stringValue {
	return self.itemName;
}

- (NSString *) lookupSection {
	//
	if (! [self.fromRemoteLookup boolValue])
		return @"Local Search";
	else if ([self.itemName length] > 0)
		return NSLocalizedString(@"Online Search",@"Section heading");
	else
		return NSLocalizedString(@"Unknown",@"Section heading");
}

// Unused. For key-value coding completeness
- (void) setLookupSection:(NSString *)lookup {
	// unused
}

#pragma mark Miscellaneous
- (NSComparisonResult) compare:(SearchItem *)anItem {
    NSString * str1 = [self stringValue];
    NSString * str2 = [anItem stringValue];
    if (str1 == nil) {
        if (str2 == nil)
            return NSOrderedSame;
        else
            return NSOrderedDescending;
    }
    else
        return [str1 compare:str2];
}

#pragma mark Remote instantiation update
- (void) updateFromDictionary:(NSDictionary *)dict {
	if (dict == nil)
		return;
	self.itemName = [dict valueForKey:@"itemName"];
	self.fromRemoteLookup = @YES;
}

@end
