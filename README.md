[![Version](https://img.shields.io/cocoapods/v/MRFetchedResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRFetchedResultsController)
[![License](https://img.shields.io/cocoapods/l/MRFetchedResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRFetchedResultsController)
[![Platform](https://img.shields.io/cocoapods/p/MRFetchedResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRFetchedResultsController)

MRFetchedResultsController
==========================

**MRFetchedResultsController** is a drop-in replacement for `NSFetchedResultsController` that works on Mac and iOS.

Its purpose is to provide an alternative that makes it possible to extend `NSFetchedResultsController` functionallity without having to deal with private APIs.

Installation
------------

### CocoaPods

**MRFetchedResultsController** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your *Podfile*:

```ruby
pod "MRFetchedResultsController"
```

### Manually

Copy *MRFetchedResultsController* directory into your project.

Usage
-----

After adding files under the *MRFetchedResultsController* folder to your project, you can use it as you would do with `NSFetchedResultsController`.

When extending `MRFetchedResultsController`, you can expose its private methods to categories and/or subclasses by importing *MRFetchedResultsController+Internal.h*.

When using the fetched results controller with `UICollectionView` you can handle content changes by implementing the method `- (void)controller:(MRFetchedResultsController *)controller didChangeSections:(NSArray *)sectionChanges andObjects:(NSArray *)objectChanges` in the delegate:

```objc
- (void)controller:(MRFetchedResultsController *)controller didChangeSections:(NSArray *)sectionChanges andObjects:(NSArray *)objectChanges
{
    [self.collectionView performBatchUpdates:^{
        for (id<MRFetchedResultsSectionChangeInfo> change in sectionChanges) {
            [change performUpdateInCollectionView:self.collectionView];
        }
        for (id<MRFetchedResultsObjectChangeInfo> change in objectChanges) {
            [change performUpdateInCollectionView:self.collectionView];
        }
    } completion:nil];
}
```

Extras
------

Besides the new delegate method that provides support for `- [UICollectionView performBatchUpdates:completion:]`; *MRFetchedResultsController.h* contains 2 extra properties -not present in *NSFetchedResultsController.h*- for fine-tuning the behaviour of the fetched results controller's change tracking:

```objc
// Changes in the context are not applied to the fetchedObjects array until applyFetchedObjectsChanges is set.
@property (nonatomic, assign) BOOL applyFetchedObjectsChanges;
// If set, changes in the context are not applied until the context is successfully saved.
@property (nonatomic, assign) BOOL changesAppliedOnSave;
```

License
-------

`MRFetchedResultsController` is available under the MIT license. See the *LICENSE* file for more info.
