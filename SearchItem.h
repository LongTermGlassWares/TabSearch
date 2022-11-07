//
//  SearchItem.h
//
//  Copyright 2022 Long Term Glass Wares, LLC. All rights reserved.
//

@import Foundation;

@interface SearchItem : NSObject

@property (nonatomic, strong) NSString * itemName;
@property (nonatomic, strong) NSNumber * fromRemoteLookup;

- (NSComparisonResult) compare:(SearchItem *)anItem;
- (void) updateFromDictionary:(NSDictionary *)dict;

@end
