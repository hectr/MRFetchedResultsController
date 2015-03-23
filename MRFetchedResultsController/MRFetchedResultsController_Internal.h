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


@interface MRFetchedResultsController (Internal)

@property (nonatomic, strong) NSCache *cache;

@property (nonatomic, assign) BOOL didPerformFetch;
@property (nonatomic, assign) NSUInteger numberOfObjects;

@property (nonatomic, strong) NSDictionary *sectionsByName;
@property (nonatomic, strong) NSArray *sectionIndexTitlesSections;

@property (nonatomic, assign) BOOL notifyDidChangeObject;
@property (nonatomic, assign) BOOL notifyDidChangeSection;
@property (nonatomic, assign) BOOL notifyWillChangeContent;
@property (nonatomic, assign) BOOL notifyDidChangeContent;
@property (nonatomic, assign) BOOL notifySectionIndexTitle;

@property (nonatomic, strong) id<NSObject> observer;

@property (nonatomic, strong) NSMutableSet *insertedObjects;
@property (nonatomic, strong) NSMutableSet *updatedObjects;
@property (nonatomic, strong) NSMutableSet *deletedObjects;

- (void)mr_updateDelegateFlags:(id<MRFetchedResultsControllerDelegate>)delegate;

- (BOOL)mr_performRequest:(NSFetchRequest *)fetchRequest
                inContext:(NSManagedObjectContext *)context
       sectionNameKeyPath:(NSString *)sectionNameKeyPath
                    error:(NSError **)errorPtr;

- (void)mr_buildSectionsWithKeyPath:(NSString *)keyPath
                         andObjects:(NSArray *)objects
                          inContext:(NSManagedObjectContext *)context;

- (void)mr_setSectionIndexTitles;

- (NSUInteger)mr_customHashForFetchRequest:(NSFetchRequest *)fetchRequest;

- (void)mr_cacheResults:(NSArray *)fetchedObjects;

- (NSPredicate *)mr_buildEntityPredicateForFetchRequest:(NSFetchRequest *)fetchRequest;

- (void)mr_updateContent:(NSDictionary *)userInfo;

- (void)mr_applyChangesWithDeletedObjects:(NSSet *)deletedObjects
                          insertedObjects:(NSSet *)insertedObjects
                           updatedObjects:(NSSet *)updatedObjects;

- (void)mr_notifyChangesInSections:(NSArray *)oldSections
                        indexPaths:(NSMutableDictionary *)oldIndexPaths
                           objects:(NSSet *)oldMatches
                     andNewObjects:(NSSet *)newMatches
                    andGoneObjects:(NSMutableSet *)goneMatches;

- (NSString *)mr_managedObjectContextNotificationName;

- (void)mr_startMonitoringChanges;

- (BOOL)mr_stopMonitoringChanges;

@end
