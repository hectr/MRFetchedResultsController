// MRFetchedResultsController.m
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
#import <CoreData/CoreData.h>


static NSCache *__cache = nil;


#pragma mark - MRCollectionViewProtocol -


@protocol MRCollectionViewProtocol <NSObject>
- (void)insertSections:(NSIndexSet *)sections;
- (void)deleteSections:(NSIndexSet *)sections;
- (void)reloadSections:(NSIndexSet *)sections;
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;
- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
@end


#pragma mark - MRFetchedResultsSectionInfo -


@interface MRFetchedResultsSectionInfo : NSObject <MRFetchedResultsSectionInfo>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *indexTitle;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong) NSArray *sourceObjects;
@property (nonatomic, assign, getter=isUsingObjectIDs) BOOL usingObjectIDs;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end


@implementation MRFetchedResultsSectionInfo

- (instancetype)initWithName:(NSString *const)name
                  indexTitle:(NSString *const)indexTitle
                       range:(NSRange const)range
               sourceObjects:(NSArray *const)sourceObjects
{
    NSParameterAssert(![sourceObjects.firstObject isKindOfClass:NSManagedObjectID.class]);
    self = [self init];
    if (self) {
        _name = name;
        _indexTitle = indexTitle;
        _range = range;
        _sourceObjects = sourceObjects;
    }
    return self;
}

- (instancetype)initWithName:(NSString *const)name
                  indexTitle:(NSString *const)indexTitle
                       range:(NSRange const)range
             sourceObjectIDs:(NSArray *const)sourceObjectIDs
        managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(![sourceObjectIDs.firstObject isKindOfClass:NSManagedObject.class]);
    NSParameterAssert(managedObjectContext);
    self = [self init];
    if (self) {
        _name = name;
        _indexTitle = indexTitle;
        _range = range;
        _usingObjectIDs = YES;
        _sourceObjects = sourceObjectIDs;
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (NSArray *)objects
{
    NSArray *const sourceObjects = self.sourceObjects;
    NSRange const range = self.range;
    NSArray *objects;
    BOOL const isUsingObjectIDs = self.isUsingObjectIDs;
    if (isUsingObjectIDs) {
        NSArray *const objectIDs = [sourceObjects subarrayWithRange:range];
        NSMutableArray *const mutableObjects = [NSMutableArray arrayWithCapacity:objectIDs.count];
        NSManagedObjectContext *const moc = self.managedObjectContext;
        for (NSManagedObjectID *const objectID in objectIDs) {
            NSManagedObject *const object = [moc objectWithID:objectID];
            [mutableObjects addObject:object];
        }
        objects = mutableObjects;
    } else {
        objects = [sourceObjects subarrayWithRange:range];
    }
    return objects;
}

- (NSUInteger)numberOfObjects
{
    NSRange const range = self.range;
    NSUInteger const numberOfObjects = range.length;
    return numberOfObjects;
}

@end


#pragma mark - MRFetchedResultsSectionInfo -


@interface MRFetchedResultsChangeInfo : NSObject <MRFetchedResultsSectionChangeInfo, MRFetchedResultsObjectChangeInfo>
@property (nonatomic, assign) BOOL isSectionChange;
@property (nonatomic, assign) MRFetchedResultsChangeType changeType;
@property (nonatomic, assign) NSUInteger sectionIndex;
@property (nonatomic, assign) NSUInteger sectionNewIndex;
@property (nonatomic, strong) NSIndexPath *objectIndexPath;
@property (nonatomic, strong) NSIndexPath *objectNewIndexPath;

@end


@implementation MRFetchedResultsChangeInfo

- (void)performUpdateInCollectionView:(id const)collectionView
{
    switch (self.changeType) {
        case MRFetchedResultsChangeInsert: {
            if (self.isSectionChange) {
                NSIndexSet * const indexSet = [NSIndexSet indexSetWithIndex:self.sectionNewIndex];
                NSParameterAssert([collectionView respondsToSelector:@selector(insertSections:)]);
                [collectionView performSelector:@selector(insertSections:)
                                     withObject:indexSet];
            } else {
                NSParameterAssert([collectionView respondsToSelector:@selector(insertItemsAtIndexPaths:)]);
                [collectionView performSelector:@selector(insertItemsAtIndexPaths:)
                                     withObject:@[ self.objectNewIndexPath ]];
            }
        } break;
        case MRFetchedResultsChangeDelete: {
            if (self.isSectionChange) {
                NSIndexSet * const indexSet = [NSIndexSet indexSetWithIndex:self.sectionIndex];
                NSParameterAssert([collectionView respondsToSelector:@selector(deleteSections:)]);
                [collectionView performSelector:@selector(deleteSections:)
                                     withObject:indexSet];
            } else {
                NSParameterAssert([collectionView respondsToSelector:@selector(deleteItemsAtIndexPaths:)]);
                [collectionView performSelector:@selector(deleteItemsAtIndexPaths:)
                                     withObject:@[ self.objectIndexPath ]];
            }
        } break;
        case MRFetchedResultsChangeMove: {
            if (self.isSectionChange) {
                NSParameterAssert([collectionView respondsToSelector:@selector(moveSection:toSection:)]);
                [collectionView performSelector:@selector(moveSection:toSection:)
                                     withObject:@(self.sectionIndex)
                                     withObject:@(self.sectionNewIndex)];
            } else {
                NSParameterAssert([collectionView respondsToSelector:@selector(moveItemAtIndexPath:toIndexPath:)]);
                [collectionView performSelector:@selector(moveItemAtIndexPath:toIndexPath:)
                                     withObject:self.objectIndexPath
                                     withObject:self.objectNewIndexPath];
            }
        } break;
        case MRFetchedResultsChangeUpdate: {
            if (self.isSectionChange) {
                NSIndexSet * const indexSet = [NSIndexSet indexSetWithIndex:self.sectionIndex];
                NSParameterAssert([collectionView respondsToSelector:@selector(reloadSections:)]);
                [collectionView performSelector:@selector(reloadSections:)
                                     withObject:indexSet];
            } else {
                NSParameterAssert([collectionView respondsToSelector:@selector(reloadItemsAtIndexPaths:)]);
                [collectionView performSelector:@selector(reloadItemsAtIndexPaths:)
                                     withObject:@[ self.objectIndexPath ]];
            }
        } break;
    }
}

@end


#pragma mark - MRFetchedResultsController -


@interface MRFetchedResultsController ()
@property (nonatomic, strong, readwrite) NSFetchRequest *fetchRequest;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSString *sectionNameKeyPath;
@property (nonatomic, strong, readwrite) NSString *cacheName;
@property (nonatomic, strong, readwrite) NSCache *cache;
@property (nonatomic, assign, readwrite) BOOL didPerformFetch;
@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;
@property (nonatomic, strong, readwrite) NSArray *fetchedObjects;
@property (nonatomic, strong, readwrite) NSArray *sectionIndexTitles;
@property (nonatomic, strong, readwrite) NSArray *sections;
@property (nonatomic, strong, readwrite) NSDictionary *sectionsByName;
@property (nonatomic, strong, readwrite) NSArray *sectionIndexTitlesSections;
@property (nonatomic, assign, readwrite) BOOL notifyDidChangeObject;
@property (nonatomic, assign, readwrite) BOOL notifyDidChangeSection;
@property (nonatomic, assign, readwrite) BOOL notifyWillChangeContent;
@property (nonatomic, assign, readwrite) BOOL notifyDidChangeContent;
@property (nonatomic, assign, readwrite) BOOL notifyDidChangeSectionsAndObjects;
@property (nonatomic, assign, readwrite) BOOL notifySectionIndexTitle;
@property (nonatomic, strong, readwrite) id<NSObject> observer;
@property (nonatomic, strong, readwrite) NSMutableSet *insertedObjects;
@property (nonatomic, strong, readwrite) NSMutableSet *updatedObjects;
@property (nonatomic, strong, readwrite) NSMutableSet *deletedObjects;
@end


@implementation MRFetchedResultsController

+ (void)initialize
{
    __cache = [[NSCache alloc] init];
}

+ (void)deleteCacheWithName:(NSString *const)name
{
    if (name) {
        [__cache removeObjectForKey:name];
    } else {
        [__cache removeAllObjects];
    }
}

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest
      managedObjectContext:(NSManagedObjectContext *const)context
        sectionNameKeyPath:(NSString *const)sectionNameKeyPath
                 cacheName:(NSString *const)cacheName
{
    NSParameterAssert(fetchRequest);
    NSParameterAssert(fetchRequest.sortDescriptors.count > 0);
    NSParameterAssert(sectionNameKeyPath == nil || [[fetchRequest.sortDescriptors.firstObject key] isEqualToString:sectionNameKeyPath]);
    NSArray *const sortDescriptors = fetchRequest.sortDescriptors;
    if (sortDescriptors.count == 0) {
        if (sectionNameKeyPath) {
            fetchRequest = fetchRequest.copy;
            fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:sectionNameKeyPath ascending:YES] ];
        }
    } else if (sectionNameKeyPath) {
        NSSortDescriptor *const firstSortDescriptor = sortDescriptors.firstObject;
        if (![firstSortDescriptor.key isEqual:sectionNameKeyPath]) {
            NSSortDescriptor *const sectionSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sectionNameKeyPath ascending:YES];
            fetchRequest = fetchRequest.copy;
            fetchRequest.sortDescriptors = [sortDescriptors arrayByAddingObject:sectionSortDescriptor];
        }
    }
    NSParameterAssert(context);
    if ((self = [self init])) {
        _fetchRequest = fetchRequest;
        _managedObjectContext = context;
        _sectionNameKeyPath = sectionNameKeyPath;
        _cacheName = cacheName;
    }
    return self;
}

- (BOOL)performFetch:(NSError **const)errorPtr
{
    [self mr_stopMonitoringChanges];
    if (!self.applyFetchedObjectsChanges) {
        self.insertedObjects = NSMutableSet.set;
        self.updatedObjects = NSMutableSet.set;
        self.deletedObjects = NSMutableSet.set;
    }
    NSString *const cacheName = self.cacheName;
    if (cacheName) {
        NSCache *const cache = self.cache;
        NSMutableDictionary *const cacheDictionary = [cache objectForKey:cacheName];
        NSFetchRequest *const fetchRequest = self.fetchRequest;
        NSUInteger const fetchRequestHash = [self mr_customHashForFetchRequest:fetchRequest];
        NSString *const fetchedObjectsKey =
        [NSString stringWithFormat:@"fetchedObjects-%ld", (long)fetchRequestHash];
        NSArray *const fetchedObjects = cacheDictionary[fetchedObjectsKey];
        NSString *const sectionsKey =
        [NSString stringWithFormat:@"sections-%ld", (unsigned long)fetchRequestHash];
        NSArray *const sections = cacheDictionary[sectionsKey];
        if (fetchedObjects || sections) {
            self.fetchedObjects = fetchedObjects;
            self.sections = sections;
            NSString *const sectionsByNameKey =
            [NSString stringWithFormat:@"sectionsByName-%ld", (unsigned long)fetchRequestHash];
            self.sectionsByName = cacheDictionary[sectionsByNameKey];
            NSString *const sectionIndexTitlesKey =
            [NSString stringWithFormat:@"sectionIndexTitles-%ld", (unsigned long)fetchRequestHash];
            self.sectionIndexTitles = cacheDictionary[sectionIndexTitlesKey];
            NSString *const indexTitlesSectionsKey =
            [NSString stringWithFormat:@"indexTitlesSections-%ld", (unsigned long)fetchRequestHash];
            self.sectionIndexTitlesSections = cacheDictionary[indexTitlesSectionsKey];
            self.didPerformFetch = YES;
            return YES;
        }
    }
    NSManagedObjectContext *const managedObjectContext = self.managedObjectContext;
    NSFetchRequest *const fetchRequest = self.fetchRequest;
    NSString *const entityName = fetchRequest.entityName;
    fetchRequest.entity = [NSEntityDescription entityForName:entityName
                                      inManagedObjectContext:managedObjectContext];
    NSString *const sectionNameKeyPath = self.sectionNameKeyPath;
    BOOL const success = [self mr_performRequest:fetchRequest
                                       inContext:managedObjectContext
                              sectionNameKeyPath:sectionNameKeyPath
                                           error:errorPtr];
    if (success) {
        [self mr_startMonitoringChanges];
    }
    return success;
}

- (id)objectAtIndexPath:(NSIndexPath *const)fetchedIndexPath
{
    NSParameterAssert(fetchedIndexPath);
    NSUInteger const section = [fetchedIndexPath indexAtPosition:0];
    NSUInteger const row = [fetchedIndexPath indexAtPosition:1];
    id<MRFetchedResultsSectionInfo> const sectionInfo = self.sections[section];
    NSObject *const object = [sectionInfo.objects objectAtIndex:row];
    return object;
}

- (NSIndexPath *)indexPathForObject:(id const)object
{
    NSParameterAssert(object);
    NSArray *const fetchedObjects = self.fetchedObjects;
    NSUInteger objectIndex = [fetchedObjects indexOfObject:object];
    NSIndexPath *indexPath;
    if (objectIndex != NSNotFound) {
        NSArray *const sections = self.sections;
        __block NSUInteger section = NSNotFound;
        __block id<MRFetchedResultsSectionInfo> sectionInfo;
        [sections enumerateObjectsUsingBlock:
         ^(MRFetchedResultsSectionInfo *const obj, NSUInteger const idx, BOOL *const stop) {
             NSRange const range = obj.range;
             if (range.location <= objectIndex && objectIndex < (range.location + range.length)) {
                 section = idx;
                 sectionInfo = obj;
                 *stop = YES;
             }
         }];
        NSAssert(NSNotFound != section, @"section not found");
        if (section != NSNotFound) {
            NSArray *const sectionObjects = sectionInfo.objects;
            NSUInteger const row = [sectionObjects indexOfObject:object];
            NSAssert(NSNotFound != row, @"row not found");
            if (row != NSNotFound) {
                NSUInteger indexes[] = {section, row};
                NSUInteger const length = sizeof(indexes)/sizeof(typeof(NSUInteger));
                NSAssert(length == 2, @"indexes must contain section and row");
                indexPath = [NSIndexPath indexPathWithIndexes:indexes length:length];
            }
        }
    }
    return indexPath;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *const)sectionName
{
    NSString *indexTitle;
    if (sectionName.length == 0) {
        indexTitle = sectionName;
    } else if (sectionName.length == 1) {
        indexTitle = sectionName.uppercaseString;
    } else {
        indexTitle = [sectionName substringToIndex:1].uppercaseString;
    }
    return indexTitle;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *const)title atIndex:(NSInteger const)index;
{
    NSArray *const sectionIndexTitles = self.sectionIndexTitles;
    NSInteger const count = sectionIndexTitles.count;
    NSNumber *sectionIndexTitlesSection;
    NSAssert(count > index, @"invalid Section Index offset %ld", (long)index);
    if (count > index) {
        NSString *const sectionIndexTitle = sectionIndexTitles[index];
        NSAssert([sectionIndexTitle isEqual:title], @"Index title at %ld is not equal to '%@''", (long)index, title);
        if ([sectionIndexTitle isEqual:title]) {
            NSArray *const sectionIndexTitlesSections = self.sectionIndexTitlesSections;
            sectionIndexTitlesSection = sectionIndexTitlesSections[index];
        }
    }
    NSInteger section;
    if (sectionIndexTitlesSection) {
        section = sectionIndexTitlesSection.integerValue;
    } else {
        section = NSNotFound;
    }
    return section;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *const)title
{
    NSArray *const sectionIndexTitles = self.sectionIndexTitles;
    ;
    NSInteger const controllerIndex = [sectionIndexTitles indexOfObject:title];
    NSInteger section;
    if (controllerIndex != NSNotFound) {
        NSArray *const sectionIndexTitlesSections = self.sectionIndexTitlesSections;
        NSNumber *const sectionIndexTitlesSection = sectionIndexTitlesSections[controllerIndex];
        section = sectionIndexTitlesSection.integerValue;
    } else {
        section = NSNotFound;
    }
    return section;
}

#pragma mark Accessors

- (void)setDelegate:(id<MRFetchedResultsControllerDelegate> const)delegate
{
    [self willChangeValueForKey:@"delegate"];
    _delegate = delegate;
    [self mr_updateDelegateFlags:delegate];
    [self didChangeValueForKey:@"delegate"];
}

- (NSArray *)fetchedObjects
{
    NSUInteger const numberOfObjects = self.numberOfObjects;
    if (_fetchedObjects == nil && numberOfObjects > 0) {
        NSMutableArray *const objects = [NSMutableArray arrayWithCapacity:numberOfObjects];
        NSArray *const sections = self.sections;
        for (id<MRFetchedResultsSectionInfo> const sectionInfo in sections) {
            NSArray *const sectionObjects = sectionInfo.objects;
            [objects addObject:sectionObjects];
        }
        _fetchedObjects = objects;
    }
    return _fetchedObjects;
}

- (void)setApplyFetchedObjectsChanges:(BOOL const)applyFetchedObjectsChanges
{
    [self willChangeValueForKey:@"applyFetchedObjectsChanges"];
    if (applyFetchedObjectsChanges && !_applyFetchedObjectsChanges) {
        [self mr_applyChangesWithDeletedObjects:self.deletedObjects
                                insertedObjects:self.insertedObjects
                                 updatedObjects:self.updatedObjects];
    } else if (!applyFetchedObjectsChanges && _applyFetchedObjectsChanges){
        self.insertedObjects = NSMutableSet.set;
        self.updatedObjects = NSMutableSet.set;
        self.deletedObjects = NSMutableSet.set;
    }
    _applyFetchedObjectsChanges = applyFetchedObjectsChanges;
    [self didChangeValueForKey:@"applyFetchedObjectsChanges"];
}

- (void)setChangesAppliedOnSave:(BOOL const)changesAppliedOnSave
{
    [self willChangeValueForKey:@"changesAppliedOnSave"];
    BOOL const wasMonitoringChanges = [self mr_stopMonitoringChanges];
    _changesAppliedOnSave = changesAppliedOnSave;
    if (wasMonitoringChanges) {
        [self mr_startMonitoringChanges];
    }
    [self didChangeValueForKey:@"changesAppliedOnSave"];
}

#pragma mark Private

- (void)mr_updateDelegateFlags:(id<MRFetchedResultsControllerDelegate> const)delegate
{
    self.notifyDidChangeObject = [delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)];
    self.notifyDidChangeSection = [delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)];
    self.notifyWillChangeContent = [delegate respondsToSelector:@selector(controllerWillChangeContent:)];
    self.notifyDidChangeContent = [delegate respondsToSelector:@selector(controllerDidChangeContent:)];
    self.notifyDidChangeSectionsAndObjects = [delegate respondsToSelector:@selector(controller:didChangeSections:andObjects:)];
    self.notifySectionIndexTitle = [delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)];
}

- (BOOL)mr_performRequest:(NSFetchRequest *const)fetchRequest
                inContext:(NSManagedObjectContext *const)context
       sectionNameKeyPath:(NSString *const)sectionNameKeyPath
                    error:(NSError **const)errorPtr
{
    NSParameterAssert(fetchRequest);
    NSParameterAssert(context);
    NSArray *const fetchedObjects = [context executeFetchRequest:fetchRequest error:errorPtr];
    [self mr_buildSectionsWithKeyPath:sectionNameKeyPath andObjects:fetchedObjects inContext:context];
    [self mr_cacheResults:fetchedObjects];
    self.numberOfObjects = fetchedObjects.count;
    if (context == self.managedObjectContext) {
        self.fetchedObjects = fetchedObjects;
    } else {
        self.fetchedObjects = nil;
    }
    BOOL const success = (fetchedObjects ? YES : NO);
    self.didPerformFetch = success;
    return success;
}

- (void)mr_buildSectionsWithKeyPath:(NSString *const)keyPath
                         andObjects:(NSArray *const)objects
                          inContext:(NSManagedObjectContext *const)context
{
    BOOL isUsingObjectIDs = (context != self.managedObjectContext);
    if (keyPath == nil) {
        NSRange const range = NSMakeRange(0, objects.count);
        id<MRFetchedResultsSectionInfo> sectionInfo;
        if (isUsingObjectIDs) {
            sectionInfo =
            [[MRFetchedResultsSectionInfo alloc] initWithName:nil
                                                   indexTitle:nil
                                                        range:range
                                              sourceObjectIDs:objects
                                         managedObjectContext:context];
        } else {
            sectionInfo =
            [[MRFetchedResultsSectionInfo alloc] initWithName:nil
                                                   indexTitle:nil
                                                        range:range
                                                sourceObjects:objects];
        }
        self.sections = @[ sectionInfo ];
        self.sectionsByName = @{ NSNull.null: sectionInfo };
        return;
    }
    // iterate objects for finding sections
    NSManagedObject *const firstObject = objects.firstObject;
    NSString *currentName = [firstObject valueForKeyPath:keyPath];
    if (currentName == nil) {
        NSLog(@"CoreData: error: (MRFetchedResultsController) "
              @"object %@ returned nil value for section name key path '%@'. "
              @"Object will be placed in unnamed section"
              , firstObject
              , keyPath);
        currentName = @"";
    }
    NSAssert([currentName isKindOfClass:NSString.class]
             , @"section name should be a string");
    NSUInteger currentLocation = 0;
    NSUInteger currentLength = 0;
    NSMutableArray *const sections = NSMutableArray.array;
    NSMutableDictionary *const sectionsByName = NSMutableDictionary.dictionary;
    for (NSManagedObject *const object in objects) {
        NSString *objectSectionName = [object valueForKeyPath:keyPath];
        if (objectSectionName == nil) {
            NSLog(@"CoreData: error: (MRFetchedResultsController) "
                  @"object %@ returned nil value for section name key path '%@'. "
                  @"Object will be placed in unnamed section"
                  , firstObject
                  , keyPath);
            objectSectionName = @"";
        }
        NSAssert([objectSectionName isKindOfClass:NSString.class]
                 , @"section name should be a string");
        if ([objectSectionName isEqual:currentName]) {
            currentLength += 1;
        } else {
            NSString *const sectionIndexTitle = [self mr_sectionIndexTitleForSectionName:currentName];
            NSRange const range = NSMakeRange(currentLocation, currentLength);
            id<MRFetchedResultsSectionInfo> sectionInfo;
            if (isUsingObjectIDs) {
                sectionInfo =
                [[MRFetchedResultsSectionInfo alloc] initWithName:currentName
                                                       indexTitle:sectionIndexTitle
                                                            range:range
                                                  sourceObjectIDs:objects
                                             managedObjectContext:context];
            } else {
                sectionInfo =
                [[MRFetchedResultsSectionInfo alloc] initWithName:currentName
                                                       indexTitle:sectionIndexTitle
                                                            range:range
                                                    sourceObjects:objects];
            }
            [sections addObject:sectionInfo];
            sectionsByName[currentName] = sectionInfo;
            currentName = objectSectionName;
            NSAssert(![sectionsByName.allKeys containsObject:objectSectionName]
                     , @"fetched objects must be sorted by section name");
            currentLocation = currentLocation + currentLength;
            currentLength = 1;
        }
    }
    // last section
    if (objects.count > 0) {
        NSString *const sectionIndexTitle = [self mr_sectionIndexTitleForSectionName:currentName];
        NSRange const range = NSMakeRange(currentLocation, currentLength);
        id<MRFetchedResultsSectionInfo> sectionInfo;
        if (isUsingObjectIDs) {
            sectionInfo =
            [[MRFetchedResultsSectionInfo alloc] initWithName:currentName
                                                   indexTitle:sectionIndexTitle
                                                        range:range
                                              sourceObjectIDs:objects
                                         managedObjectContext:context];
        } else {
            sectionInfo =
            [[MRFetchedResultsSectionInfo alloc] initWithName:currentName
                                                   indexTitle:sectionIndexTitle
                                                        range:range
                                                sourceObjects:objects];
        }
        [sections addObject:sectionInfo];
        sectionsByName[currentName] = sectionInfo;
    }
    // finish
    self.sections = sections;
    self.sectionsByName = sectionsByName;
    [self mr_setSectionIndexTitles];
}

- (NSString *)mr_sectionIndexTitleForSectionName:(NSString *const)sectionName
{
    NSString *indexTitle;
    if (self.notifySectionIndexTitle) {
        indexTitle = [self.delegate controller:self sectionIndexTitleForSectionName:sectionName];
    } else {
        indexTitle = [self sectionIndexTitleForSectionName:sectionName];
    }
    return indexTitle;
}

- (void)mr_setSectionIndexTitles
{
    NSArray *const sections = self.sections;
    NSUInteger const count = sections.count;
    NSMutableArray *const sectionIndexTitles = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray *const sectionIndexTitlesSections = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray *const names = [NSMutableArray arrayWithCapacity:sections.count];
    for (id<MRFetchedResultsSectionInfo> const section in sections) {
        NSString *const name = section.name;
        [names addObject:(name ?: NSNull.null)];
    }
    [names enumerateObjectsUsingBlock:
     ^(NSString *const candidate, NSUInteger const index, BOOL *const stop) {
         if (NSNull.null != (id)candidate) {
             NSString *const indexTitle =
             [self mr_sectionIndexTitleForSectionName:candidate];
             if (indexTitle) {
                 [sectionIndexTitles addObject:indexTitle];
                 [sectionIndexTitlesSections addObject:@(index)];
             }
         }
     }];
    self.sectionIndexTitles = sectionIndexTitles;
    self.sectionIndexTitlesSections = sectionIndexTitlesSections;
}

- (NSUInteger)mr_customHashForFetchRequest:(NSFetchRequest *const)fetchRequest
{
    NSString *const entityName = fetchRequest.entityName;
    NSUInteger hash = entityName.hash;
    NSPredicate *const predicate = fetchRequest.predicate;
    NSInteger const predicateHash = predicate.hash;
    hash ^= predicateHash;
    NSArray *const sortDescriptors = fetchRequest.sortDescriptors;
    for (NSSortDescriptor *const sortDescriptor in sortDescriptors) {
        NSInteger const sortDescriptorHash = sortDescriptor.hash;
        hash ^= sortDescriptorHash;
    }
    return hash;
}

- (void)mr_cacheResults:(NSArray *const)fetchedObjects
{
    NSString *const cacheName = self.cacheName;
    if (cacheName) {
        NSCache *const cache = self.cache;
        NSMutableDictionary *const cacheDictionary = ([cache objectForKey:cacheName] ?: NSMutableDictionary.dictionary);
        NSFetchRequest *const fetchRequest = self.fetchRequest;
        NSUInteger const fetchRequestHash = [self mr_customHashForFetchRequest:fetchRequest];
        if (fetchedObjects) {
            NSString *const fetchedObjectsKey =
            [NSString stringWithFormat:@"fetchedObjects-%ld", (long)fetchRequestHash];
            [cacheDictionary setObject:fetchedObjects forKey:fetchedObjectsKey];
        }
        if (_sections) {
            NSString *const sectionsKey =
            [NSString stringWithFormat:@"sections-%ld", (unsigned long)fetchRequestHash];
            [cacheDictionary setObject:_sections forKey:sectionsKey];
        }
        if (_sectionsByName) {
            NSString *const sectionsByNameKey =
            [NSString stringWithFormat:@"sectionsByName-%ld", (unsigned long)fetchRequestHash];
            [cacheDictionary setObject:_sectionsByName forKey:sectionsByNameKey];
        }
        if (_sectionIndexTitles) {
            NSString *const sectionIndexTitlesKey =
            [NSString stringWithFormat:@"sectionIndexTitles-%ld", (unsigned long)fetchRequestHash];
            [cacheDictionary setObject:_sectionIndexTitles forKey:sectionIndexTitlesKey];
        }
        if (_sectionIndexTitlesSections) {
            NSString *const indexTitlesSectionsKey =
            [NSString stringWithFormat:@"indexTitlesSections-%ld", (unsigned long)fetchRequestHash];
            [cacheDictionary setObject:_sectionIndexTitlesSections forKey:indexTitlesSectionsKey];
        }
        [cache setObject:cacheDictionary forKey:cacheName];
    }
}

- (NSPredicate *)mr_buildEntityPredicateForFetchRequest:(NSFetchRequest *const)fetchRequest
{
    NSString *const entityName = fetchRequest.entityName;
    NSPredicate *const entityPredicate =
    [NSPredicate predicateWithBlock:^BOOL(NSManagedObject *const o, NSDictionary *const b) {
        return [o.entity.name isEqual:entityName];
    }];
    return entityPredicate;
}

- (void)mr_updateContent:(NSDictionary *const)userInfo
{
    // gather saved objects
    NSFetchRequest *const fetchRequest = self.fetchRequest;
    NSPredicate *const entityPredicate = [self mr_buildEntityPredicateForFetchRequest:fetchRequest];
    NSSet *const deletedObjects = [userInfo[NSDeletedObjectsKey] filteredSetUsingPredicate:entityPredicate];
    NSSet *const insertedObjects = [userInfo[NSInsertedObjectsKey] filteredSetUsingPredicate:entityPredicate];
    NSSet *const updatedObjects = [userInfo[NSUpdatedObjectsKey] filteredSetUsingPredicate:entityPredicate];
    if (self.applyFetchedObjectsChanges) {
        [self mr_applyChangesWithDeletedObjects:deletedObjects
                                insertedObjects:insertedObjects
                                 updatedObjects:updatedObjects];
    } else {
        [self.insertedObjects addObjectsFromArray:insertedObjects.allObjects];
        NSSet *const updated = [updatedObjects filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return ![self.insertedObjects containsObject:evaluatedObject];
        }]];
        [self.updatedObjects addObjectsFromArray:updated.allObjects];
        for (NSManagedObject *const deletedObject in deletedObjects) {
            [self.insertedObjects removeObject:deletedObject];
            [self.updatedObjects removeObject:deletedObject];
        }
        [self.deletedObjects addObjectsFromArray:deletedObjects.allObjects];
    }
}

- (void)mr_applyChangesWithDeletedObjects:(NSSet *const)deletedObjects
                          insertedObjects:(NSSet *const)insertedObjects
                           updatedObjects:(NSSet *const)updatedObjects
{
    NSFetchRequest *const fetchRequest = self.fetchRequest;
    NSPredicate *const predicate = fetchRequest.predicate;
    NSPredicate *const noPredicate = (predicate ? [NSCompoundPredicate notPredicateWithSubpredicate:predicate] : nil);
    // prepare old index paths dictionary
    NSMutableDictionary *const oldIndexPaths = (self.notifyDidChangeObject ? NSMutableDictionary.dictionary : nil);
    // find new and old objects
    NSMutableSet *const oldObjects = NSMutableSet.set;
    NSMutableSet *const newObjects = NSMutableSet.set;
    NSArray *const fetchedObjects = self.fetchedObjects;
    for (NSManagedObject *const object in updatedObjects) {
        if ([fetchedObjects containsObject:object]) {
            [oldObjects addObject:object];
            oldIndexPaths[object.objectID] = [self indexPathForObject:object];
        } else {
            [newObjects addObject:object];
        }
    }
    if (insertedObjects) {
        [newObjects addObjectsFromArray:insertedObjects.allObjects];
    }
    // find new matches
    NSSet *const newMatches = (predicate ? [newObjects filteredSetUsingPredicate:predicate] : newObjects);
    // find old matches
    NSSet *const oldMatches = (predicate ? [oldObjects filteredSetUsingPredicate:predicate] : oldObjects);
    // find gone matches
    NSMutableSet *const goneMatches = NSMutableSet.set;
    for (NSManagedObject *const object in deletedObjects) {
        if ([fetchedObjects containsObject:object]) {
            [goneMatches addObject:object];
            oldIndexPaths[object.objectID] = [self indexPathForObject:object];
        }
    }
    NSSet *const lostMatches = (noPredicate ? [oldObjects filteredSetUsingPredicate:noPredicate] : nil);
    if (lostMatches) {
        for (NSManagedObject *const object in lostMatches) {
            oldIndexPaths[object.objectID] = [self indexPathForObject:object];
        }
        [goneMatches addObjectsFromArray:lostMatches.allObjects];
    }
    // finish if content won't change
    if (newMatches.count == 0 && oldMatches.count == 0 && goneMatches.count == 0) {
        return;
    }
    // apply changes
    NSMutableSet *const objectsSet = [NSMutableSet setWithArray:self.fetchedObjects];
    // add new matches
    [objectsSet addObjectsFromArray:newMatches.allObjects];
    // remove gone matches
    for (NSManagedObject *const goneObject in goneMatches) {
        [objectsSet removeObject:goneObject];
    }
    // build objects array
    NSArray *const sortDescriptors = fetchRequest.sortDescriptors;
    NSArray *const objectsArray = [objectsSet sortedArrayUsingDescriptors:sortDescriptors];
    // reset data
    NSString *const sectionNameKeyPath = self.sectionNameKeyPath;
    NSManagedObjectContext *const moc = self.managedObjectContext;
    NSArray *const oldSections = (self.notifyDidChangeSection ? self.sections : nil);
    [self mr_buildSectionsWithKeyPath:sectionNameKeyPath andObjects:objectsArray inContext:moc];
    [self mr_cacheResults:objectsArray];
    self.numberOfObjects = objectsArray.count;
    self.fetchedObjects = objectsArray;
    // notify changes
    dispatch_async(dispatch_get_main_queue(), ^{
        [self mr_notifyChangesInSections:oldSections
                              indexPaths:oldIndexPaths
                                 objects:oldMatches
                           andNewObjects:newMatches
                          andGoneObjects:goneMatches];
    });
}

- (id<MRFetchedResultsSectionChangeInfo>)mr_changeInfoWithType:(MRFetchedResultsChangeType const)type
                                                     atSection:(NSUInteger const)index
                                                    newSection:(NSUInteger const)newIndex
{
    MRFetchedResultsChangeInfo *const changeInfo = [[MRFetchedResultsChangeInfo alloc] init];
    changeInfo.isSectionChange = YES;
    changeInfo.changeType = type;
    switch (type) {
        case MRFetchedResultsChangeInsert:
            NSParameterAssert(index == NSNotFound);
            NSParameterAssert(newIndex != NSNotFound);
            changeInfo.sectionIndex = NSNotFound;
            changeInfo.sectionNewIndex = newIndex;
            break;
        case MRFetchedResultsChangeDelete:
            NSParameterAssert(index != NSNotFound);
            NSParameterAssert(newIndex == NSNotFound);
            changeInfo.sectionIndex = index;
            changeInfo.sectionNewIndex = NSNotFound;
            break;
        case MRFetchedResultsChangeMove:
            NSParameterAssert(index != NSNotFound);
            NSParameterAssert(newIndex != NSNotFound);
            changeInfo.sectionIndex = index;
            changeInfo.sectionNewIndex = newIndex;
            break;
        case MRFetchedResultsChangeUpdate:
            NSParameterAssert(index != NSNotFound);
            NSParameterAssert(newIndex == NSNotFound);
            changeInfo.sectionIndex = index;
            changeInfo.sectionNewIndex = NSNotFound;
            break;
    }
    return changeInfo;
}

- (id<MRFetchedResultsObjectChangeInfo>)mr_changeInfoWithType:(MRFetchedResultsChangeType const)type
                                            atIndexPath:(NSIndexPath *const)indexPath
                                           newIndexPath:(NSIndexPath *const)newIndexPath
{
    MRFetchedResultsChangeInfo *const changeInfo = [[MRFetchedResultsChangeInfo alloc] init];
    changeInfo.changeType = type;
    switch (type) {
        case MRFetchedResultsChangeInsert:
            NSParameterAssert(indexPath == nil);
            NSParameterAssert(newIndexPath);
            changeInfo.objectIndexPath = nil;
            changeInfo.objectNewIndexPath = newIndexPath;
            break;
        case MRFetchedResultsChangeDelete:
            NSParameterAssert(indexPath);
            NSParameterAssert(newIndexPath == nil);
            changeInfo.objectIndexPath = indexPath;
            changeInfo.objectNewIndexPath = nil;
            break;
        case MRFetchedResultsChangeMove:
            NSParameterAssert(indexPath);
            NSParameterAssert(newIndexPath);
            changeInfo.objectIndexPath = indexPath;
            changeInfo.objectNewIndexPath = newIndexPath;
            break;
        case MRFetchedResultsChangeUpdate:
            NSParameterAssert(indexPath);
            NSParameterAssert(newIndexPath == nil);
            changeInfo.objectIndexPath = indexPath;
            changeInfo.objectNewIndexPath = nil;
            break;
    }
    return changeInfo;
}

- (void)mr_notifyChangesInSections:(NSArray *const)oldSections
                        indexPaths:(NSDictionary *const)oldIndexPaths
                           objects:(NSSet *const)oldMatches
                     andNewObjects:(NSSet *const)newMatches
                    andGoneObjects:(NSSet *const)goneMatches
{
    // notify future changes
    id<MRFetchedResultsControllerDelegate> const delegate = self.delegate;
    if (self.notifyWillChangeContent) {
        [delegate controllerWillChangeContent:self];
    }
    NSMutableArray *sectionChanges;
    NSMutableArray *objectChanges;
    BOOL const notifyDidChangeSectionsAndObjects = self.notifyDidChangeSectionsAndObjects;
    if (notifyDidChangeSectionsAndObjects) {
        sectionChanges = NSMutableArray.array;
        objectChanges = NSMutableArray.array;
    }
    // notify section changes
    BOOL const notifyDidChangeSection = self.notifyDidChangeSection;
    if (notifyDidChangeSection || notifyDidChangeSectionsAndObjects) {
        NSArray *const sections = self.sections;
        NSMutableArray *const newSections = sections.mutableCopy;
        [oldSections enumerateObjectsUsingBlock:
         ^(id<MRFetchedResultsSectionInfo> const oldSectionInfo, NSUInteger const oldIndex, BOOL *const stop) {
             NSString *const oldName = oldSectionInfo.name;
             BOOL found = NO;
             for (id<MRFetchedResultsSectionInfo> const sectionInfo in sections) {
                 NSString *const name = sectionInfo.name;
                 if ([name isEqual:oldName] || name == oldName) {
                     [newSections removeObject:sectionInfo];
                     found = YES;
                     NSUInteger const index = [sections indexOfObject:sectionInfo];
                     NSAssert(NSNotFound != index, @"section not found");
                     if (oldIndex != index) {
                         [sectionChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeDelete atSection:oldIndex newSection:NSNotFound]];
                         [sectionChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeInsert atSection:NSNotFound newSection:index]];
                         if (notifyDidChangeSection) {
                             [delegate controller:self
                                 didChangeSection:oldSectionInfo
                                          atIndex:oldIndex
                                    forChangeType:MRFetchedResultsChangeDelete];
                             [delegate controller:self
                                 didChangeSection:sectionInfo
                                          atIndex:index
                                    forChangeType:MRFetchedResultsChangeInsert];
                         }
                     }
                     break;
                 }
             }
             if (!found) {
                 [sectionChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeDelete atSection:oldIndex newSection:NSNotFound]];
                 if (notifyDidChangeSection) {
                     [delegate controller:self
                         didChangeSection:oldSectionInfo
                                  atIndex:oldIndex
                            forChangeType:MRFetchedResultsChangeDelete];
                 }
             }
         }];
        [newSections enumerateObjectsUsingBlock:
         ^(id<MRFetchedResultsSectionInfo> const newSectionInfo, NSUInteger const newIndex, BOOL *const stop) {
             NSUInteger const index = [sections indexOfObject:newSectionInfo];
             NSAssert(NSNotFound != index, @"section not found");
             [sectionChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeInsert atSection:NSNotFound newSection:index]];
             if (notifyDidChangeSection) {
                 [delegate controller:self
                     didChangeSection:newSectionInfo
                              atIndex:index
                        forChangeType:MRFetchedResultsChangeInsert];
             }
         }];
    }
    // notify object changes
    BOOL const notifyDidChangeObject = self.notifyDidChangeObject;
    if (notifyDidChangeObject || notifyDidChangeSectionsAndObjects) {
        for (NSManagedObject *const object in newMatches) {
            NSIndexPath *const newIndexPath = [self indexPathForObject:object];
            [objectChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeInsert atIndexPath:nil newIndexPath:newIndexPath]];
            if (notifyDidChangeObject) {
                [delegate controller:self
                     didChangeObject:object
                         atIndexPath:nil
                       forChangeType:MRFetchedResultsChangeInsert
                        newIndexPath:newIndexPath];
            }
        }
        for (NSManagedObject *const object in goneMatches) {
            NSIndexPath *const oldIndexPath = oldIndexPaths[object.objectID];
            [objectChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeDelete atIndexPath:oldIndexPath newIndexPath:nil]];
            if (notifyDidChangeObject) {
                [delegate controller:self
                     didChangeObject:object
                         atIndexPath:oldIndexPath
                       forChangeType:MRFetchedResultsChangeDelete
                        newIndexPath:nil];
            }
        }
        for (NSManagedObject *const object in oldMatches) {
            NSIndexPath *const oldIndexPath = oldIndexPaths[object.objectID];
            NSIndexPath *const newIndexPath = [self indexPathForObject:object];
            if ([oldIndexPath isEqual:newIndexPath]) {
                [objectChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeUpdate atIndexPath:oldIndexPath newIndexPath:nil]];
                if (notifyDidChangeObject) {
                    [delegate controller:self
                         didChangeObject:object
                             atIndexPath:oldIndexPath
                           forChangeType:MRFetchedResultsChangeUpdate
                            newIndexPath:newIndexPath];
                }
            } else {
                [objectChanges addObject:[self mr_changeInfoWithType:MRFetchedResultsChangeMove atIndexPath:oldIndexPath newIndexPath:newIndexPath]];
                if (notifyDidChangeObject) {
                    [delegate controller:self
                         didChangeObject:object
                             atIndexPath:oldIndexPath
                           forChangeType:MRFetchedResultsChangeMove
                            newIndexPath:newIndexPath];
                }
            }
        }
    }
    // notify changes completed
    if (notifyDidChangeSectionsAndObjects) {
        [delegate controller:self didChangeSections:sectionChanges andObjects:objectChanges];
    }
    if (self.notifyDidChangeContent) {
        [delegate controllerDidChangeContent:self];
    }
}

- (NSString *)mr_managedObjectContextNotificationName
{
    NSString *name;
    if (self.changesAppliedOnSave) {
        name = NSManagedObjectContextDidSaveNotification;
    } else {
        name = NSManagedObjectContextObjectsDidChangeNotification;
    }
    return name;
}

- (void)mr_startMonitoringChanges
{
    if (self.observer == nil) {
        NSManagedObjectContext *const moc = self.managedObjectContext;
        NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
        __weak typeof(self) const weakSelf = self;
        NSString *const name = self.mr_managedObjectContextNotificationName;
        self.observer =
        [defaultCenter addObserverForName:name
                                   object:moc
                                    queue:nil
                               usingBlock:^(NSNotification *const note) {
                                   NSDictionary *const userInfo = note.userInfo;
                                   [weakSelf mr_updateContent:userInfo];
                               }];
    }
}

- (BOOL)mr_stopMonitoringChanges
{
    id<NSObject> const observer = self.observer;
    if (observer) {
        self.observer = nil;
        NSManagedObjectContext *const moc = self.managedObjectContext;
        NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
        NSString *const name = self.mr_managedObjectContextNotificationName;
        [defaultCenter removeObserver:observer
                                 name:name
                               object:moc];
        return YES;
    }
    return NO;
}

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = __cache;
        _applyFetchedObjectsChanges = YES;
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [self mr_stopMonitoringChanges];
}

@end
