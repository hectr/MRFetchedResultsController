// MRFetchedResultsController.h
//
// Copyright (c) 2015 Héctor Marqués
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class NSManagedObjectContext, NSManagedObject, NSFetchRequest;
@protocol MRFetchedResultsControllerDelegate, MRFetchedResultsSectionInfo, MRFetchedResultsSectionChangeInfo, MRFetchedResultsObjectChangeInfo;


/**
 This class provides the same interface than `NSFetchedResultsController` for managing the results returned from a Core Data fetch request.
 */
@interface MRFetchedResultsController : NSObject

/**
 Initializes an instance of `MRFetchedResultsController`.
 
 @param fetchRequest The fetch request used to get the objects.
 @param context The context that will hold the fetched objects.
 @param sectionNameKeyPath Keypath on resulting objects that returns their section name.
 @param cacheName Identifier of the in-memory cache.
 @return The receiver initialized with the given parameters.
 */
- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext: (NSManagedObjectContext *)context sectionNameKeyPath:(NSString *)sectionNameKeyPath cacheName:(NSString *)name;

/**
 Executes the fetch request to get objects.
 
 @param errorPtr If the fetch is not successful, upon return contains an error object describing the problem.
 @return Returns `YES` if successful or `NO` otherwise.
 */
- (BOOL)performFetch:(NSError **)errorPtr;

/**
 `NSFetchRequest` instance used to do the fetching.
 */
@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;

/**
 Managed Object Context used to fetch objects.
 
 The controller registers to listen to change notifications on this context (see `applyFetchedObjectsChanges`) and properly update its result set and section information (see `changesAppliedOnSave`).
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/**
 The keyPath on the fetched objects used to determine the section they belong to.
 */
@property (nonatomic, strong, readonly) NSString *sectionNameKeyPath;

/**
 Name of the section information in-memory cache.
 */
@property (nonatomic, strong, readonly) NSString *cacheName;

/**
 Delegate that is notified when the result set changes.
 */
@property (nonatomic, weak) id<MRFetchedResultsControllerDelegate> delegate;

/**
 Deletes the cached section information with the given name. If name is `nil`, then the whole cache is deleted.
 */
+ (void)deleteCacheWithName:(NSString *)name;

/**
 Returns the results of the fetch.
 */
@property (nonatomic, strong, readonly) NSArray<__kindof NSManagedObject *> *fetchedObjects;

/**
 Returns the fetched object at the given index path.
 
 @param fetchedIndexPath An index path in the fetch results.
 @return The object at the given index path.
 */
- (id)objectAtIndexPath:(NSIndexPath *)fetchedIndexPath;

/**
 Returns the index path of a given object.
 
 @param object An object in the receiver’s fetch results.
 @return The index path of an object in the receiver’s fetch results, or `nil` if object could not be found.
 */
- (NSIndexPath *)indexPathForObject:(id)object;

/**
 Returns the default section index title for a given section name.
 
 @param sectionName The name of a section.
 @return The default section index title corresponding to the section with the given name.
 */
- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

/**
 Returns the array of section index titles.
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *sectionIndexTitles;

/**
 Returns an array of objects that implement the `MRFetchedResultsSectionInfo` protocol.
 */
@property (nonatomic, strong, readonly) NSArray<id<MRFetchedResultsSectionInfo>> *sections;

/**
 Returns the section number for the given section index title and index.
 
 @param title The index title of a section.
 @param sectionIndex The index of a section.
 @return The section number for the given section index title and index.
 */
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

/*
 Returns the section number for a given section index title.
 
 @param The title of a section in the section index.
 @return The section number for the given section index title.
 */
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title;

/**
 If set, changes in fetched objects and sections are applied immediately when a managed object context notification is received; otherwise changes are stored, but they are not applied until `applyFetchedObjectsChanges` is set.
 
 Default value is YES.
 */
@property (nonatomic, assign) BOOL applyFetchedObjectsChanges;

/**
 If set, the receiver listens to `NSManagedObjectContextDidSaveNotification`. Otherwise it listens to `NSManagedObjectContextObjectsDidChangeNotification`.
 
 Default value is NO.
 */
@property (nonatomic, assign) BOOL changesAppliedOnSave;

@end


// ================== PROTOCOLS ==================


/**
 This protocol defines the interface for section objects.
 */
@protocol MRFetchedResultsSectionInfo <NSObject>

/**
 Name of the section.
 */
@property (nonatomic, readonly) NSString *name;

/**
 Section index title.
 */
@property (nonatomic, readonly) NSString *indexTitle;

/**
 Number of objects in section.
 */
@property (nonatomic, readonly) NSUInteger numberOfObjects;

/**
 Array of objects in the section.
 */
@property (nonatomic, readonly) NSArray<__kindof NSManagedObject *> *objects;

@end


/**
 `MRFetchedResultsController` instances use methods in this protocol for notifying changes in fetch results to their delegates.
 */
@protocol MRFetchedResultsControllerDelegate <NSObject>

typedef NS_ENUM(NSUInteger, MRFetchedResultsChangeType) {
    /** Specifies that an object was inserted. */
    MRFetchedResultsChangeInsert = 1,
    /** Specifies that an object was deleted. */
    MRFetchedResultsChangeDelete = 2,
    /** Specifies that an object was moved. */
    MRFetchedResultsChangeMove = 3,
    /** Specifies that an object was updated. */
    MRFetchedResultsChangeUpdate = 4
};

// Notifies the delegate that a fetched object has been changed.
@optional
- (void)controller:(MRFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(MRFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

// Notifies the delegate of added or removed sections.
@optional
- (void)controller:(MRFetchedResultsController *)controller didChangeSection:(id <MRFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(MRFetchedResultsChangeType)type;

//  Notifies the delegate that section and object changes are about to be processed.
@optional
- (void)controllerWillChangeContent:(MRFetchedResultsController *)controller;

// Notifies the delegate of all changes in sections and objects. See `MRFetchedResultsSectionChangeInfo` and `MRFetchedResultsObjectChangeInfo`.
@optional
- (void)controller:(MRFetchedResultsController *)controller didChangeSections:(NSArray<id<MRFetchedResultsSectionChangeInfo>> *)sectionChanges andObjects:(NSArray<id<MRFetchedResultsObjectChangeInfo>> *)objectChanges;

// Notifies the delegate that all section and object changes have been sent.
@optional
- (void)controllerDidChangeContent:(MRFetchedResultsController *)controller;

// Asks the delegate to return the corresponding section index title for a given section name.
@optional
- (NSString *)controller:(MRFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName;

@end


/**
 This protocol defines the interface for section changes in `MRFetchedResultsController`.
 */
@protocol MRFetchedResultsSectionChangeInfo <NSObject>

/**
 The type of change.
 */
@property (nonatomic, readonly) MRFetchedResultsChangeType changeType;

/**
 The original index of the deleted/moved section.
 */
@property (nonatomic, readonly) NSUInteger sectionIndex;

/**
 The new index of the inserted/moved section.
 */
@property (nonatomic, readonly) NSUInteger sectionNewIndex;

/**
 Inserts/Deletes/Moves the changed section in the given collection view.
 
 You should invoke this method within the updates block in `- [UICollectionView performBatchUpdates:completion:]`.
 
 @param collectionView The collection view that will be updated.
 */
- (void)performUpdateInCollectionView:(id)collectionView;

@end


/**
 This protocol defines the interface for object changes in `MRFetchedResultsController`.
 */
@protocol MRFetchedResultsObjectChangeInfo <NSObject>

/**
 The type of change.
 */
@property (nonatomic, readonly) MRFetchedResultsChangeType changeType;

/**
 The original index path of the deleted/moved/updated object.
 */
@property (nonatomic, readonly) NSIndexPath *objectIndexPath;

/**
 The new index path of the inserted/moved object.
 */
@property (nonatomic, readonly) NSIndexPath *objectNewIndexPath;

/**
 Inserts/Deletes/Moves/Updates the changed object in the given collection view.
 
 You should invoke this method within the updates block in `- [UICollectionView performBatchUpdates:completion:]`.
 
 @param collectionView The collection view that will be updated.
 */
- (void)performUpdateInCollectionView:(id)collectionView;

@end
