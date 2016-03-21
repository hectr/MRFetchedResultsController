// MRFetchedResultsController_Internal.h
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

#import "MRFetchedResultsController.h"

@class NSManagedObjectID;

/**
 Extension that exposes non-public methods of `MRFetchedResultsController` instances.
 */
@interface MRFetchedResultsController (Internal)

/**
 The cache used by the fetched results controller when a `cacheName` is provided.
 */
@property (nonatomic, strong) NSCache *cache;

/**
 Set when a fetch has been performed.
 */
@property (nonatomic, assign) BOOL didPerformFetch;

/**
 Number of objects in the results set.
 */
@property (nonatomic, assign) NSUInteger numberOfObjects;

/**
 Section info objects by name.
 */
@property (nonatomic, strong) NSDictionary<NSString *, id> *sectionsByName;

/**
 Indexes of the sections in the section index.
 */
@property (nonatomic, strong) NSArray<NSNumber *> *sectionIndexTitlesSections;

/**
 Set when the `delegate` responds to `controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:`.
 */
@property (nonatomic, assign) BOOL notifyDidChangeObject;

/**
 Set when the `delegate` responds to `controller:didChangeSection:atIndex:forChangeType:`.
 */
@property (nonatomic, assign) BOOL notifyDidChangeSection;

/**
 Set when the `delegate` responds to `controllerWillChangeContent:`.
 */
@property (nonatomic, assign) BOOL notifyWillChangeContent;

/**
 Set when the `delegate` responds to `controllerDidChangeContent:`.
 */
@property (nonatomic, assign) BOOL notifyDidChangeContent;

/**
 Set when the `delegate` responds to `controller:didChangeSections:andObjects:`.
 */
@property (nonatomic, assign) BOOL notifyDidChangeSectionsAndObjects;

/**
 Set when the `delegate` responds to `controller:sectionIndexTitleForSectionName:`.
 */
@property (nonatomic, assign) BOOL notifySectionIndexTitle;

/**
 The observer object used for monitoring the results set changes.
 */
@property (nonatomic, strong) id<NSObject> observer;

/**
 Property used for storing inserted objects until they are applied to the results set.
 */
@property (nonatomic, strong) NSMutableSet<__kindof NSManagedObject *> *insertedObjects;

/**
 Property used for storing updated objects until they are applied to the results set.
 */
@property (nonatomic, strong) NSMutableSet<__kindof NSManagedObject *> *updatedObjects;

/**
 Property used for storing deleted objects until they are applied to the results set.
 */
@property (nonatomic, strong) NSMutableSet<__kindof NSManagedObject *> *deletedObjects;

/** 
 Updates the receiver's `notify*` delegate flags for the given delegate object.
 
 @param delegate The object used for setting the delegate flags values.
 */
- (void)mr_updateDelegateFlags:(id<MRFetchedResultsControllerDelegate>)delegate;

/**
 Performs the given fetch request in the given context using the given keypath for the name of the sections.
 
 @param fetchRequest The fetch request used to get the objects.
 @param context The context that will hold the fetched objects.
 @param sectionNameKeyPath Keypath on resulting objects that returns their section name.
 @param errorPtr If the fetch request fails, it may contain an `NSError` object describing the failure.
 @return `YES` if the fetch request is performed successfully; `NO` otherwise.
 */
- (BOOL)mr_performRequest:(NSFetchRequest *)fetchRequest
                inContext:(NSManagedObjectContext *)context
       sectionNameKeyPath:(NSString *)sectionNameKeyPath
                    error:(NSError **)errorPtr;

/**
 Builds the structures that store the sections information
 
 This method will set `sections` and `sectionsByName` properties and will invoke `mr_setSectionIndexTitles` if needed.
 
 @param keyPath The keypath used for determining the name of the sections.
 @param objects The fetched objects.
 @param context The context used for fetching the objects.
 */
- (void)mr_buildSectionsWithKeyPath:(NSString *)keyPath
                         andObjects:(NSArray<__kindof NSManagedObject *> *)objects
                          inContext:(NSManagedObjectContext *)context;

/**
 Returns the corresponding section index title for a given section name taking into account delegate's `controller:sectionIndexTitleForSectionName:`.
 
 @param sectionName The name of a section.
 @return The section index entry corresponding to the section with the given name.
 */

- (NSString *)mr_sectionIndexTitleForSectionName:(NSString *)sectionName;

/**
 Sets the value of `sectionIndexTitles` and `sectionIndexTitlesSections` properties.
 */
- (void)mr_setSectionIndexTitles;

/**
 Calculates a hash of the given fetch request.
 
 This hash is used for forming the keys used by the `cache`.
 
 @param fetchRequest The fetch request whose hash will be calculated.
 @return An integer that can be used as a hash number.
 */
- (NSUInteger)mr_customHashForFetchRequest:(NSFetchRequest *)fetchRequest;

/**
 Caches not only the given `fetchedObjects`, but also the `_sections`, `_sectionsByName`, `_sectionIndexTitles`, `_sectionIndexTitlesSections` ivars.
 
 See `cache` and `cacheName` properties.
 */
- (void)mr_cacheResults:(NSArray<__kindof NSManagedObject *> *)fetchedObjects;

/**
 Returns a predicate that filters managed objects whose entity name is not equal to the `entityName` of the parameter.
 
 @param fetchRequest The fetch request whose `entityName` will be used for creating the predicate.
 @return A predicate that can filter objects that don't match fetch request's entity name.
 */
- (NSPredicate *)mr_buildEntityPredicateForFetchRequest:(NSFetchRequest *)fetchRequest;

/**
 Uses the managed object context notification's `userInfo` dictionary for updating the results set.
 
 Depending on the value of `changesAppliedOnSave`, the changes are applied immediately or stored in `insertedObjects`, `updatedObjects` and `deletedObjects` properties.
 */
- (void)mr_updateContent:(NSDictionary<NSString *, __kindof NSManagedObject *> *)userInfo;

/**
 Applies the changes represented by the given parameters in the results set.
 
 @parameter deletedObjects Set of objects from the results set that have been deleted.
 @parameter insertedObjects Set of objects that should be inserted into the results set.
 @parameter updatedObjects Set of objects from the results set that have been updated.
 */
- (void)mr_applyChangesWithDeletedObjects:(NSSet<__kindof NSManagedObject *> *)deletedObjects
                          insertedObjects:(NSSet<__kindof NSManagedObject *> *)insertedObjects
                           updatedObjects:(NSSet<__kindof NSManagedObject *> *)updatedObjects;

/**
 Builds a section change info with the given parameters.
 
 @param type The type of the change.
 @param index The index of the changed section.
 @return The object that represents a change of the given type in the section at the given index.
 */
- (id<MRFetchedResultsSectionChangeInfo>)mr_changeInfoWithType:(MRFetchedResultsChangeType)type
                                                     atSection:(NSUInteger)index;

/**
 Builds an object change info with the given parameters.
 
 @param type The type of the change.
 @param indexPath The original index path of the changed object or `nil`.
 @param newIndexPath The new index path of the changed object or `nil`.
 @return The object that represents a change of the given type in the object that was at the given index path and/or will be in the new index path.
 */
- (id<MRFetchedResultsObjectChangeInfo>)mr_changeInfoWithType:(MRFetchedResultsChangeType)type
                                                  atIndexPath:(NSIndexPath *)indexPath
                                                 newIndexPath:(NSIndexPath *)newIndexPath;

/**
 Notifies the changes represented by the parameters to the receiver's `delegate`.
 
 @param oldSections The section info objects of the sections moved or deleted.
 @param oldIndexPaths The index paths of the deleted objects.
 @param oldMatches The fetched objects updated or moved.
 @param newMatches The fetched objects inserted into the results set.
 @param goneMatches The fetched objects deleted from the results set.
 */
- (void)mr_notifyChangesInSections:(NSArray<id<MRFetchedResultsSectionInfo>> *)oldSections
                        indexPaths:(NSMutableDictionary<NSManagedObjectID *, NSIndexPath *> *)oldIndexPaths
                           objects:(NSSet<__kindof NSManagedObject *> *)oldMatches
                     andNewObjects:(NSSet<__kindof NSManagedObject *> *)newMatches
                    andGoneObjects:(NSMutableSet<__kindof NSManagedObject *> *)goneMatches;

/**
 Returns the notification that must be used for monitoring changes in the results set.
 
 See `changesAppliedOnSave` property.
 */
- (NSString *)mr_managedObjectContextNotificationName;

/**
 If the receiver is not doing so, it starts monitoring changes in the results set.
 */
- (void)mr_startMonitoringChanges;

/**
 If the receiver is monitoring changes in the results set, it stops doing so.
 
 @return `YES` if the receiver was monitoring changes; `NO` otherwise.
 */
- (BOOL)mr_stopMonitoringChanges;

@end
