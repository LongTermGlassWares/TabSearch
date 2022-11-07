//
//  ScanSearchViewController.h
//
//  Copyright 2022 Long Term Glass Wares, LLC. All rights reserved.
//

@import UIKit;
@import Foundation;
@import AVFoundation;

#import "SearchItem.h"

@interface ScanSearchViewController : UIViewController <UISearchBarDelegate,
                                                        UITableViewDelegate, UITableViewDataSource,
                                                        UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate> {
    BOOL clearOnAppear;
}

@property (nonatomic,weak) IBOutlet UIView * cameraView;

- (void)setSearchActive;
- (void)setSearchInactive;

@end
