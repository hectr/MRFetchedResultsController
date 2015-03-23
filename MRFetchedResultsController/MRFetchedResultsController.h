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

@class NSManagedObjectContext, NSFetchRequest;
@protocol MRFetchedResultsControllerDelegate;


/**
 This class provides the same interface than `NSFetchedResultsController` for managing the results returned from a Core Data fetch request.
 */
@interface MRFetchedResultsController : NSObject

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext: (NSManagedObjectContext *)context sectionNameKeyPath:(NSString *)sectionNameKeyPath cacheName:(NSString *)name;

- (BOOL)performFetch:(NSError **)errorPtr;

@property (nonatomic, strong, readonly) NSFetchRequest *fetchRequest;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong, readonly) NSString *sectionNameKeyPath;

@property (nonatomic, strong, readonly) NSString *cacheName;

@property (nonatomic, weak) id<MRFetchedResultsControllerDelegate> delegate;

+ (void)deleteCacheWithName:(NSString *)name;

@property (nonatomic, strong, readonly) NSArray *fetchedObjects;

- (id)objectAtIndexPath:(NSIndexPath *)fetchedIndexPath;

- (NSIndexPath *)indexPathForObject:(id)object;

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

@property (nonatomic, strong, readonly) NSArray *sectionIndexTitles;

@property (nonatomic, strong, readonly) NSArray *sections;

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


// See `NSFetchedResultsSectionInfo`.
@protocol MRFetchedResultsSectionInfo

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *indexTitle;

@property (nonatomic, readonly) NSUInteger numberOfObjects;

@property (nonatomic, readonly) NSArray *objects;

@end


// See `NSFetchedResultsControllerDelegate`.
@protocol MRFetchedResultsControllerDelegate <NSObject>

typedef NS_ENUM(NSUInteger, MRFetchedResultsChangeType) {
    MRFetchedResultsChangeInsert = 1,
    MRFetchedResultsChangeDelete = 2,
    MRFetchedResultsChangeMove = 3,
    MRFetchedResultsChangeUpdate = 4
};

@optional
- (void)controller:(MRFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(MRFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

@optional
- (void)controller:(MRFetchedResultsController *)controller didChangeSection:(id <MRFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(MRFetchedResultsChangeType)type;

@optional
- (void)controllerWillChangeContent:(MRFetchedResultsController *)controller;

@optional
- (void)controllerDidChangeContent:(MRFetchedResultsController *)controller;

@optional
- (NSString *)controller:(MRFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName;

@end
