//
//  ScanSearchViewController.m
//
//  Copyright 2022 Long Term Glass Wares, LLC. All rights reserved.
//

#import "ScanSearchViewController.h"

#import "SearchItem.h"

#define TAG_STATUS_LABEL 210

@interface ScanSearchViewController()
@property (nonatomic,strong) SearchItem * fetchedItem;
@property (nonatomic,strong) SearchItem * remoteItem;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer * scanPreviewLayer;
@property (nonatomic,strong) AVCaptureSession * scanAVSession;
@end

// TODO: Replace UISearchDisplayController, presumably with UISearchController and UISearchControllerDelegate (if needed)
// Otherwise on iOS 13+: 'NSInternalInconsistencyException', reason: 'No UISearchDisplayController support methods should run on this version of iOS'

@implementation ScanSearchViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    self.scanAVSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice * scanAVCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;

    AVCaptureDeviceInput * scanAVCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:scanAVCaptureDevice error:&error];
    if (scanAVCaptureInput) {
        [self.scanAVSession addInput:scanAVCaptureInput];
    } else {
        NSLog(@"ScanSearchViewController scanAVCaptureInput: Error: %@", error);
        return;
    }

    AVCaptureMetadataOutput * scanCaptureOutput = [[AVCaptureMetadataOutput alloc] init];
    [scanCaptureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.scanAVSession addOutput:scanCaptureOutput];
    scanCaptureOutput.metadataObjectTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code];

    self.scanPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.scanAVSession];
    self.scanPreviewLayer.frame = self.cameraView.bounds;
    self.scanPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.cameraView.layer addSublayer:self.scanPreviewLayer];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateStatus:NSLocalizedString(@"Initializing camera...",@"Camera status")];
    if (self->clearOnAppear)
        [self.searchDisplayController setActive:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	// Remove Search keyboard ...
	BOOL activateField =
		!(self.searchDisplayController.active
       && self.fetchedItem != nil);	// and something to look at
		// activate search if no Camera available
	[self updateCameraStatusActivateTextField:activateField];
	self->clearOnAppear = FALSE;
    if (!self.searchDisplayController.active)
        [self startCameraSession];
}

- (void) viewWillDisappear: (BOOL) animated
{
    [super viewWillDisappear:animated];
    [self stopCameraSession];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.scanPreviewLayer.connection == nil)
        return;
    AVCaptureConnection * previewLayerConnection = self.scanPreviewLayer.connection;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (previewLayerConnection.supportsVideoOrientation) {
        self.scanPreviewLayer.frame = self.cameraView.bounds;
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
            default:
                break;
        }
    }
}

- (void)startCameraSession {
    [self.scanAVSession startRunning];
}

- (void)stopCameraSession {
    [self.scanAVSession stopRunning];
}

#pragma mark Search functions

- (void)setSearchActive {
	[self.searchDisplayController setActive:YES animated:NO];
	[self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)setSearchInactive {
	[self.searchDisplayController setActive:NO animated:NO];
}

- (void)performLocalFetchWithText:(NSString *)searchText {
    if ([searchText length] > 2) {
        if (self.fetchedItem == nil) {
            self.fetchedItem = [[SearchItem alloc] init];
        }
        self.fetchedItem.itemName = [@"Local %@" stringByAppendingString:searchText];
    }
    else
        self.fetchedItem = nil;
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void) performRemoteLookupWithText:(NSString *)searchText {
	[self discardRemoteItem];

	// create result object and add into context/results
    self.remoteItem = [[SearchItem alloc] init];
    self.remoteItem.itemName = [@"Remote " stringByAppendingString:searchText];

    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL) conditionalRemoteLookupWithText:(NSString *)searchText {
	if ([searchText isEqualToString:@"abc"]) {
		[self performRemoteLookupWithText:searchText];
		return TRUE;
	}
	return FALSE;
}

- (void) discardRemoteItem {
    if (self.remoteItem != nil) {
        self.remoteItem = nil;
    }
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"searchDisplayControllerWillBeginSearch");
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    NSLog(@"searchDisplayControllerDidBeginSearch");
    [self stopCameraSession];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    NSLog(@"searchDisplayControllerWillEndSearch");
    [self discardRemoteItem];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    NSLog(@"searchDisplayControllerDidEndSearch");
    [self startCameraSession];
    [self updateCameraStatusActivateTextField:FALSE];
}

#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] > 0)
        [self stopCameraSession];
    [self discardRemoteItem];
    self->clearOnAppear = FALSE;     //any future changes are not scanned
    [self performLocalFetchWithText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	// perform search online IFF no results and is a barcode number
	if (self.fetchedItem == nil)
		[self conditionalRemoteLookupWithText:searchBar.text];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	return TRUE;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //NSLog(@"searchBarTextDidBeginEditing: '%@'", searchBar.text);
    [self stopCameraSession];
    [self discardRemoteItem];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //NSLog(@"searchBarTextDidEndEditing: '%@'", searchBar.text);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //NSLog(@"searchBarCancelButtonClicked");
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate - Scanning Result

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            AVMetadataMachineReadableCodeObject *barCodeObject = (AVMetadataMachineReadableCodeObject *)[self.scanPreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
            [self foundBarcodeSymbol:[barCodeObject stringValue]];
        }
    }
}

- (void) foundBarcodeSymbol:(NSString *)symbol {
    [self updateStatus:NSLocalizedString(@"Barcode found.",@"Camera status")];
    //
    [self.searchDisplayController setActive:YES animated:NO];
    self.searchDisplayController.searchBar.text = symbol;
    NSLog(@"foundBarcodeSymbol: '%@'",symbol);
    [self performLocalFetchWithText:symbol];
    self->clearOnAppear = TRUE;

    // only do remote lookup if no items found
    if (self.fetchedItem == nil)
        [self performRemoteLookupWithText:symbol];
}

#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat) itemSetCellRowHeight {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? /*iPad:*/ 27 : /*iPhone:*/ 44);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	SearchItem * item = [self itemAtIndexPath:indexPath];
    CGFloat defaultHeight = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? /*iPad:*/ 84 : /*iPhone:*/ 117);
	if ([item.fromRemoteLookup boolValue])
        return 72; // see: RemoteItemTableCellView
    // From
    else
        return defaultHeight;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ((self.fetchedItem != nil) ? 1 : 0) // 1st section
         + ((self.remoteItem != nil) ? 1 : 0); // 2nd section
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Section %ld", (long)section];
}

- (SearchItem *) itemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = [indexPath section];
    if (section == 1) {
        return self.remoteItem;
    }
    if (section == 0) {
        if (self.fetchedItem != nil) {
            return self.fetchedItem;
        }
    }
    return self.remoteItem;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchItem * item = [self itemAtIndexPath:indexPath];
	NSString *CellIdentifier = @"ItemTableCellViewId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    cell.textLabel.text = item.itemName;

	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	SearchItem * item = [self itemAtIndexPath:indexPath];
	if ([item.fromRemoteLookup boolValue]) {
		if ([item.itemName length] > 0)
			[cell setBackgroundColor:[UIColor colorWithRed:171.0/255.0 green:245.0/255.0 blue:137.0/255.0 alpha:1.0]];
		else
			[cell setBackgroundColor:[UIColor colorWithRed:248.0/255.0 green:233.0/255.0 blue:175.0/255.0 alpha:1.0]];
	}
}

#pragma mark Interface updates
- (void)updateStatus:(NSString *)status {
    UILabel * label = (UILabel *)[self.view viewWithTag:TAG_STATUS_LABEL];	
	label.text = status;
	label.textColor = [UIColor blackColor];
}

- (void)updateCameraStatusActivateTextField:(BOOL)activateTextField{
    if ([self.scanAVSession.inputs count] == 1) {
		[self updateStatus:NSLocalizedString(@"Scanning image for barcode...",@"Camera status")];
    }
    else {
		// activate search if no Camera available
		[self updateStatus:NSLocalizedString(@"Camera not available.",@"Camera status")];
		UILabel * label = (UILabel *)[self.view viewWithTag:TAG_STATUS_LABEL];
        label.textColor = [UIColor lightGrayColor];
		if (activateTextField)
			[self setSearchActive];
	}
}

@end
