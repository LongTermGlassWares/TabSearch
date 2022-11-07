#  UISearchDisplayController replacement

## Background

`UISearchDisplayController` was deprecated in iOS 8. 

Calling a method on `UISearchDisplayController` will now produce this exception (built and deployed to iOS 13 or later):
```'NSInternalInconsistencyException', reason: 'No UISearchDisplayController support methods should run on this version of iOS'```

## Changes

Replace the `UISearchDisplayController` on the Search tab, presumably with `UISearchController`, `UISearchResultsUpdating` and `UISearchControllerDelegate` (as needed).

Maintain the existing functionality relating to search:
- Both the text entry and the barcode scanning (camera) can be used for searching.
- The camera is active by default; if a device does not have a camera, the text field is active.
- Text entry activation stops the camera and shows the results table view. Results update on every search text change (UISearchBarDelegate)
- Barcode detection (via `AVCaptureMetadataOutputObjectsDelegate`) stops the camera and shows the results table view.

Updates are expected in `ScanSearchViewController`, `ScanSearchView` and possbily `MainWindow`.
