// MRFetchedResultsControllerTest.m
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

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import "MRFetchedResultsController.h"


#pragma mark - _MRFetchedResultsControllerDelegate -


/**
 Mock up of a `MRFetchedResultsControllerDelegate`.
 */
@interface _MRFetchedResultsControllerDelegate : NSObject <MRFetchedResultsControllerDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, copy) void(^changeObject)(NSIndexPath *, MRFetchedResultsChangeType, NSIndexPath *);
@property (nonatomic, copy) void(^changeSection)(id <MRFetchedResultsSectionInfo>, NSUInteger, MRFetchedResultsChangeType);
@property (nonatomic, copy) void(^willChangeContent)();
@property (nonatomic, copy) void(^changes)(NSArray *, NSArray *);
@property (nonatomic, copy) void(^didChangeContent)();
@property (nonatomic, copy) NSString *(^sectionIndexTitle)(NSString *);
@end


@implementation _MRFetchedResultsControllerDelegate

- (void)controller:(MRFetchedResultsController *)controller didChangeObject:(id )anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(MRFetchedResultsChangeType )type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (self.changeObject) self.changeObject(indexPath, type, newIndexPath);
}

- (void)controller:(MRFetchedResultsController *)controller didChangeSection:(id <MRFetchedResultsSectionInfo> )sectionInfo atIndex:(NSUInteger )sectionIndex forChangeType:(MRFetchedResultsChangeType )type
{
    if (self.changeSection) self.changeSection(sectionInfo, sectionIndex, type);
}

- (void)controllerWillChangeContent:(MRFetchedResultsController *)controller
{
    if (self.willChangeContent) self.willChangeContent();
}

- (void)controller:(MRFetchedResultsController *)controller didChangeSections:(NSArray *)sectionChanges andObjects:(NSArray *)objectChanges
{
    if (self.changes) self.changes(sectionChanges, objectChanges);
}

- (void)controllerDidChangeContent:(MRFetchedResultsController *)controller
{
    if (self.didChangeContent) self.didChangeContent();
}

- (NSString *)controller:(MRFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    if (self.sectionIndexTitle) return self.sectionIndexTitle(sectionName);
    else return nil;
}

@end


#pragma mark - MRFetchedResultsControllerTest -


/**
 Test cases for `MRFetchedResultsController`.
 */
@interface MRFetchedResultsControllerTest : XCTestCase
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) MRFetchedResultsController *resultsController;
@property (nonatomic, strong) NSFetchedResultsController *ns_resultsController;

@end


@implementation MRFetchedResultsControllerTest

- (void)mt_setManagedObjectContext
{
    NSBundle * bundle = [NSBundle bundleForClass:self.class];
    NSURL * modelURL = [bundle URLForResource:@"CoreData_Example" withExtension:@"momd"];
    NSManagedObjectModel * managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator * coordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType
                              configuration:nil
                                        URL:nil
                                    options:nil
                                      error:NULL];
    if (coordinator) {
        NSManagedObjectContext * managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
        self.moc = managedObjectContext;
    }
}

- (NSManagedObject *)mt_addEmployee:(NSString *)prefix save:(BOOL)save
{
    NSManagedObjectContext * moc = self.moc;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Company" inManagedObjectContext:moc];
    NSManagedObject * company = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [company setValue:[NSString stringWithFormat:@"%@-company", prefix] forKey:@"name"];
    entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:moc];
    NSManagedObject * project = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [project setValue:[NSString stringWithFormat:@"%@-project", prefix] forKey:@"name"];
    [project setValue:company forKey:@"company"];
    entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:moc];
    NSManagedObject * employee = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [employee setValue:[NSString stringWithFormat:@"%@-first-name", prefix] forKey:@"firstName"];
    [employee setValue:[NSString stringWithFormat:@"%@-last-name", prefix] forKey:@"lastName"];
    [employee setValue:[prefix substringToIndex:1] forKey:@"lastNameInitial"];
    [employee setValue:@(1000) forKey:@"salary"];
    [employee setValue:company forKey:@"company"];
    [employee setValue:@(99) forKey:@"extension"];
    if (save) {
        [moc save:NULL];
    }
    return employee;
}

- (void)setUp
{
    [super setUp];
    [self mt_setManagedObjectContext];
    [self mt_addEmployee:@"Test" save:YES];
}

- (void)tearDown
{
    _moc = nil;
    _resultsController.delegate = nil;
    _resultsController = nil;
    _ns_resultsController.delegate = nil;
    _ns_resultsController = nil;
    [super tearDown];
}

- (void)testThatFetchedResultsControllerIsCreated
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    XCTAssertNotNil(self.resultsController);
}

- (void)testThatFetchRequestIsSet
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    XCTAssertEqualObjects(fetchRequest, self.resultsController.fetchRequest);
}

- (void)testThatContextIsSet
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    XCTAssertEqualObjects(self.moc, self.resultsController.managedObjectContext);
}

- (void)testThatSectionNameKeyPathIsSet
{
    NSString * sectionNameKeyPath = @"name";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:sectionNameKeyPath
                                                                cacheName:nil];
    XCTAssertEqualObjects(sectionNameKeyPath, self.resultsController.sectionNameKeyPath);
}

- (void)testThatCacheNameIsSet
{
    NSString * cacheName = @"test";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:cacheName];
    XCTAssertEqualObjects(cacheName, self.resultsController.cacheName);
}

- (void)testThatDeleteCacheWithNameDoesNotFail
{
    NSString * cacheName = @"test";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                                 managedObjectContext:nil
                                                                   sectionNameKeyPath:nil
                                                                            cacheName:cacheName];
    XCTAssertNoThrow([MRFetchedResultsController deleteCacheWithName:cacheName]);
}

- (void)testThatDeleteCacheWithoutNameDoesNotFail
{
    NSString * cacheName = @"test";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                                 managedObjectContext:nil
                                                                   sectionNameKeyPath:nil
                                                                            cacheName:cacheName];
    XCTAssertNoThrow([MRFetchedResultsController deleteCacheWithName:nil]);
}

- (void)testThatDelegateIsSet
{
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    self.resultsController.delegate = delegate;
    XCTAssertEqualObjects(delegate, self.resultsController.delegate);
}

- (void)testThatPerformFetchReturnsYES
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    BOOL  success = [self.resultsController performFetch:NULL];
    XCTAssertTrue(success);
}

- (void)testThatObjectsAreFetched
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertTrue(self.resultsController.fetchedObjects.count > 0);
}

- (void)testThatPredicateIsUsed
{
    [self mt_addEmployee:@"A" save:NO];
    [self mt_addEmployee:@"B" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"A-company"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertTrue(self.resultsController.fetchedObjects.count == 1);
}

- (void)testThatSectionNameKeyPathIsWorking
{
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:NO];
    [self mt_addEmployee:@"B1" save:NO];
    [self mt_addEmployee:@"B2" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:@"lastNameInitial"
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertTrue(self.resultsController.sections.count == 3);
}

- (void)testThatSectionForSectionIndexTitleAtIndex
{
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:NO];
    [self mt_addEmployee:@"B1" save:NO];
    [self mt_addEmployee:@"B2" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:@"lastNameInitial"
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertEqual(2, [self.resultsController sectionForSectionIndexTitle:@"T" atIndex:2]);
}

- (void)testThatSectionForSectionIndexTitle
{
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:NO];
    [self mt_addEmployee:@"B1" save:NO];
    [self mt_addEmployee:@"B2" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:@"lastNameInitial"
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertEqual(2, [self.resultsController sectionForSectionIndexTitle:@"T"]);
}

- (void)testThatObjectAtIndexReturnsAnObject
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger indexes[2] = {0, 0};
    XCTAssertNotNil([self.resultsController objectAtIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]]);
}

- (void)testThatObjectAtIndexReturnsExpectedObject
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:NO] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    self.ns_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.moc
                                                                      sectionNameKeyPath:@"lastNameInitial"
                                                                               cacheName:nil];
    [self.resultsController performFetch:NULL];
    [self.ns_resultsController performFetch:NULL];
    NSUInteger indexes[2] = {0, 0};
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    XCTAssertEqualObjects([self.resultsController objectAtIndexPath:indexPath],
                          [self.resultsController objectAtIndexPath:indexPath]);
}

- (void)testThatIndexPathForObjectReturnsTheIndexPath
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSManagedObject * employee = self.resultsController.fetchedObjects.firstObject;
    NSUInteger indexes[2] = {0, 0};
    XCTAssertEqualObjects([self.resultsController indexPathForObject:employee], [NSIndexPath indexPathWithIndexes:indexes length:2]);
}

- (void)testThatSortDescriptorTakesEffect
{
    NSManagedObject * employee = [self mt_addEmployee:@"A" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:nil
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger indexes[2] = {0, 1};
    XCTAssertNotEqualObjects([self.resultsController objectAtIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]], employee);
}

- (void)testThatSectionsAreCreated
{
    NSManagedObject * employee = [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:YES];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:NO],
                                      [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger indexes[2] = {1, 0};
    XCTAssertEqualObjects([self.resultsController objectAtIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]], employee);
}

- (void)testThatApplyFetchedObjectsChangesDefaultValueIsYES
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    XCTAssertTrue(self.resultsController.applyFetchedObjectsChanges);
}

- (void)testThatApplyFetchedObjectsChangesIsSet
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    self.resultsController.applyFetchedObjectsChanges = NO;
    XCTAssertFalse(self.resultsController.applyFetchedObjectsChanges);
}

- (void)testThatChangesAppliedOnSaveDefaultValueIsNO
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    XCTAssertFalse(self.resultsController.changesAppliedOnSave);
}

- (void)testThatChangesAppliedOnSaveIsSet
{
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    self.resultsController.changesAppliedOnSave = YES;
    XCTAssertTrue(self.resultsController.changesAppliedOnSave);
}

- (void)testThatDelegateReceivesWillChangeContent
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger willChangeContent = 0;
    delegate.willChangeContent = ^{
        willChangeContent += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(1, willChangeContent);
}

- (void)testThatApplyFetchedObjectsChangesWorks
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger willChangeContent = 0;
    delegate.willChangeContent = ^{
        willChangeContent += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    self.resultsController.applyFetchedObjectsChanges = NO;
    [self mt_addEmployee:@"A1" save:NO];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(0, willChangeContent);
    XCTAssertEqual(1, self.resultsController.fetchedObjects.count);
    [self mt_addEmployee:@"A1" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(0, willChangeContent);
    XCTAssertEqual(1, self.resultsController.fetchedObjects.count);
    self.resultsController.applyFetchedObjectsChanges = YES;
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(1, willChangeContent);
    XCTAssertEqual(3, self.resultsController.fetchedObjects.count);
}

- (void)testThatChangesAppliedOnSaveWorks
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger willChangeContent = 0;
    delegate.willChangeContent = ^{
        willChangeContent += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    self.resultsController.changesAppliedOnSave = YES;
    [self mt_addEmployee:@"A1" save:NO];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(0, willChangeContent);
    XCTAssertEqual(1, self.resultsController.fetchedObjects.count);
    [self mt_addEmployee:@"A1" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(1, willChangeContent);
    XCTAssertEqual(3, self.resultsController.fetchedObjects.count);
}

- (void)testThatDelegateReceivesDidChangeContent
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger didChangeContent = 0;
    delegate.didChangeContent = ^{
        didChangeContent += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(1, didChangeContent);
}

- (void)testThatDelegateReceivesDidChangeObject
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger changeObject = 0;
    delegate.changeObject = ^(NSIndexPath *ip, MRFetchedResultsChangeType t, NSIndexPath *nip) {
        changeObject += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [self mt_addEmployee:@"A2" save:YES];
    [self mt_addEmployee:@"A3" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(3, changeObject);
}

- (void)testThatDidChangeObjectReceivesTypesParameters
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    self.ns_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.moc
                                                                      sectionNameKeyPath:@"lastNameInitial"
                                                                               cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    NSMutableArray *changes = NSMutableArray.array;
    delegate.changeObject = ^(NSIndexPath *ip, MRFetchedResultsChangeType t, NSIndexPath *nip) {
        [changes addObject:@(t)];
    };
    _MRFetchedResultsControllerDelegate *ns_delegate = _MRFetchedResultsControllerDelegate.new;
    NSMutableArray *ns_changes = NSMutableArray.array;
    ns_delegate.changeObject = ^(NSIndexPath *ip, MRFetchedResultsChangeType t, NSIndexPath *nip) {
        [ns_changes addObject:@(t)];
    };
    self.resultsController.delegate = delegate;
    self.ns_resultsController.delegate = ns_delegate;
    [self.resultsController performFetch:NULL];
    [self.ns_resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [self mt_addEmployee:@"A2" save:YES];
    [self mt_addEmployee:@"A3" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqualObjects(changes, ns_changes);
}

- (void)testThatDelegateReceivesDidChangeSection
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger changeSection = 0;
    delegate.changeSection = ^(id <MRFetchedResultsSectionInfo> si, NSUInteger i, MRFetchedResultsChangeType t) {
        changeSection += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [self mt_addEmployee:@"A2" save:YES];
    [self mt_addEmployee:@"A3" save:YES];
    [self mt_addEmployee:@"A4" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(3, changeSection);
}

- (void)testThatDidChangeSectionInvocationsReflectNewSections
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    NSMutableArray *inserts = NSMutableArray.array;
    NSMutableArray *deletes = NSMutableArray.array;
    delegate.changeSection = ^(id <MRFetchedResultsSectionInfo> si, NSUInteger i, MRFetchedResultsChangeType t) {
        if (t == MRFetchedResultsChangeInsert) {
            // You need some extra logic for identifying new sections because, after inserting a section,
            // MRFetchedResultsController notifies changes for all sections whose index is changed;
            // while NSFetchedResultsController only notifies the change for the inserted one.
            if ([deletes containsObject:si.name]) {
                [deletes removeObject:si.name];
            } else {
                [inserts addObject:si.name];
            }
        } else if (t == MRFetchedResultsChangeDelete) {
            [deletes addObject:si.name];
        } else {
            XCTFail(@"inhandled change type");
        }
    };
    self.ns_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate * ns_delegate = _MRFetchedResultsControllerDelegate.new;
    NSMutableArray *ns_inserts = NSMutableArray.array;
    NSMutableArray *ns_deletes = NSMutableArray.array;
    ns_delegate.changeSection = ^(id <MRFetchedResultsSectionInfo> si, NSUInteger i, MRFetchedResultsChangeType t) {
        if (t == MRFetchedResultsChangeInsert) {
            [ns_inserts addObject:si.name];
        } else if (t == MRFetchedResultsChangeDelete) {
            [ns_deletes addObject:si.name];
        } else {
            XCTFail(@"inhandled change type");
        }
    };
    self.resultsController.delegate = delegate;
    self.ns_resultsController.delegate = ns_delegate;
    [self.resultsController performFetch:NULL];
    [self.ns_resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:YES];
    [self mt_addEmployee:@"A2" save:YES];
    [self mt_addEmployee:@"A3" save:YES];
    [self mt_addEmployee:@"A4" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    NSArray *changes = [deletes arrayByAddingObjectsFromArray:inserts];
    NSArray *ns_changes = [ns_deletes arrayByAddingObjectsFromArray:ns_inserts];
    XCTAssertEqualObjects(changes, ns_changes);
}

- (void)testThatDelegateReceivesDidChanges
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    __block NSInteger changes = 0;
    delegate.changes = ^(NSArray *s, NSArray *o) {
        changes += 1;
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:NO];
    [self mt_addEmployee:@"A3" save:NO];
    [self mt_addEmployee:@"A4" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(1, changes);
}

- (void)testThatDelegateReceivesDidChangesNotifiesObjects
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    delegate.changes = ^(NSArray *s, NSArray *o) {
        XCTAssertEqual(2, o.count);
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:YES];
    [self mt_addEmployee:@"A3" save:NO];
    [self mt_addEmployee:@"A4" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (void)testThatDelegateReceivesDidChangesNotifiesSections
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    delegate.changes = ^(NSArray *s, NSArray *o) {
        XCTAssertEqual(3, s.count);
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:NO];
    [self mt_addEmployee:@"A3" save:NO];
    [self mt_addEmployee:@"A4" save:YES];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (void)testThatDelegateReceivesSectionIndexTitle
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    delegate.sectionIndexTitle = ^(NSString *sn) {
        return @"X";
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    XCTAssertEqualObjects(self.resultsController.sectionIndexTitles.firstObject, @"X");
}

- (void)testThatSectionIndexTitleMatchesNSFetchedResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastName"
                                                                            cacheName:nil];
    NSFetchRequest *ns_fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    ns_fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.ns_resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:ns_fetchRequest
                                                                    managedObjectContext:self.moc
                                                                      sectionNameKeyPath:@"lastName"
                                                                               cacheName:nil];
    _MRFetchedResultsControllerDelegate *delegate = _MRFetchedResultsControllerDelegate.new;
    delegate.sectionIndexTitle = ^(NSString *sn) {
        return @"X";
    };
    self.resultsController.delegate = delegate;
    self.ns_resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    [self.ns_resultsController performFetch:NULL];
    XCTAssertEqualObjects([self.resultsController sectionIndexTitleForSectionName:@"Test-last-name"],
                          [self.ns_resultsController sectionIndexTitleForSectionName:@"Test-last-name"]);
}

@end
