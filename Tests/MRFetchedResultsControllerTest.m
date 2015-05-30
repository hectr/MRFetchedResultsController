//
//  MRFetchedResultsControllerTest.m
//  CoreData-Example
//
//  Created by NA on 30/05/15.
//
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import "MRFetchedResultsController.h"


#pragma mark - _MRFetchedResultsControllerDelegate -


/**
 Mock up of a `MRFetchedResultsControllerDelegate`.
 */
@interface _MRFetchedResultsControllerDelegate : NSObject <MRFetchedResultsControllerDelegate>
@property (nonatomic, copy) void(^changeObject)(NSIndexPath *, MRFetchedResultsChangeType, NSIndexPath *);
@property (nonatomic, copy) void(^changeSection)(id <MRFetchedResultsSectionInfo>, NSUInteger, MRFetchedResultsChangeType);
@property (nonatomic, copy) void(^willChangeContent)();
@property (nonatomic, copy) void(^changes)(NSArray *, NSArray *);
@property (nonatomic, copy) void(^didChangeContent)();
@property (nonatomic, copy) NSString *(^sectionIndexTitle)(NSString *);
@end


@implementation _MRFetchedResultsControllerDelegate

- (void)controller:(MRFetchedResultsController *const)controller didChangeObject:(id const)anObject atIndexPath:(NSIndexPath *const)indexPath forChangeType:(MRFetchedResultsChangeType const)type newIndexPath:(NSIndexPath *const)newIndexPath
{
    if (self.changeObject) self.changeObject(indexPath, type, newIndexPath);
}

- (void)controller:(MRFetchedResultsController *const)controller didChangeSection:(id <MRFetchedResultsSectionInfo> const)sectionInfo atIndex:(NSUInteger const)sectionIndex forChangeType:(MRFetchedResultsChangeType const)type
{
    if (self.changeSection) self.changeSection(sectionInfo, sectionIndex, type);
}

- (void)controllerWillChangeContent:(MRFetchedResultsController *const)controller
{
    if (self.willChangeContent) self.willChangeContent();
}

- (void)controller:(MRFetchedResultsController *const)controller didChangeSections:(NSArray *const)sectionChanges andObjects:(NSArray *const)objectChanges
{
    if (self.changes) self.changes(sectionChanges, objectChanges);
}

- (void)controllerDidChangeContent:(MRFetchedResultsController *const)controller
{
    if (self.didChangeContent) self.didChangeContent();
}

- (NSString *)controller:(MRFetchedResultsController *const)controller sectionIndexTitleForSectionName:(NSString *const)sectionName
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
@end


@implementation MRFetchedResultsControllerTest

- (void)mt_setManagedObjectContext
{
    NSBundle *const bundle = [NSBundle bundleForClass:self.class];
    NSURL *const modelURL = [bundle URLForResource:@"CoreData_Example" withExtension:@"momd"];
    NSManagedObjectModel *const managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *const coordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType
                              configuration:nil
                                        URL:nil
                                    options:nil
                                      error:NULL];
    if (coordinator) {
        NSManagedObjectContext *const managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
        self.moc = managedObjectContext;
    }
}

- (NSManagedObject *)mt_addEmployee:(NSString *)prefix save:(BOOL)save
{
    NSManagedObjectContext *const moc = self.moc;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Company" inManagedObjectContext:moc];
    NSManagedObject *const company = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [company setValue:[NSString stringWithFormat:@"%@-company", prefix] forKey:@"name"];
    entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:moc];
    NSManagedObject *const project = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [project setValue:[NSString stringWithFormat:@"%@-project", prefix] forKey:@"name"];
    [project setValue:company forKey:@"company"];
    entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:moc];
    NSManagedObject *const employee = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
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
    NSString *const sectionNameKeyPath = @"name";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:sectionNameKeyPath
                                                                cacheName:nil];
    XCTAssertEqualObjects(sectionNameKeyPath, self.resultsController.sectionNameKeyPath);
}

- (void)testThatCacheNameIsSet
{
    NSString *const cacheName = @"test";
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:cacheName];
    XCTAssertEqualObjects(cacheName, self.resultsController.cacheName);
}

- (void)testThatDelegateIsSet
{
    id<MRFetchedResultsControllerDelegate> const delegate = _MRFetchedResultsControllerDelegate.new;
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:nil
                                                     managedObjectContext:nil
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    self.resultsController.delegate = delegate;
    XCTAssertEqualObjects(delegate, self.resultsController.delegate);
}

- (void)testThatPerformFetchReturnsYES
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:nil
                                                                cacheName:nil];
    BOOL const success = [self.resultsController performFetch:NULL];
    XCTAssertTrue(success);
}

- (void)testThatObjectsAreFetched
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Company"];
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                     managedObjectContext:self.moc
                                                       sectionNameKeyPath:@"lastNameInitial"
                                                                cacheName:nil];
    [self.resultsController performFetch:NULL];
    XCTAssertEqual(2, [self.resultsController sectionForSectionIndexTitle:@"T"]);
}

- (void)testThatObjectAtIndexReturnsAnObject
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger const indexes[2] = {0, 0};
    XCTAssertNotNil([self.resultsController objectAtIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]]);
}

- (void)testThatIndexPathForObjectReturnsTheIndexPath
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSManagedObject *const employee = self.resultsController.fetchedObjects.firstObject;
    NSUInteger const indexes[2] = {0, 0};
    XCTAssertEqualObjects([self.resultsController indexPathForObject:employee], [NSIndexPath indexPathWithIndexes:indexes length:2]);
}

- (void)testThatSortDescriptorTakesEffect
{
    NSManagedObject *const employee = [self mt_addEmployee:@"A" save:YES];
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:nil
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger const indexes[2] = {0, 1};
    XCTAssertNotEqualObjects([self.resultsController objectAtIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]], employee);
}

- (void)testThatSectionsAreCreated
{
    NSManagedObject *const employee = [self mt_addEmployee:@"A1" save:NO];
    [self mt_addEmployee:@"A2" save:YES];
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastNameInitial" ascending:NO],
                                      [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] ];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    [self.resultsController performFetch:NULL];
    NSUInteger const indexes[2] = {1, 0};
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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

- (void)testThatDelegateReceivesDidChangeSection
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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

- (void)testThatDelegateReceivesDidChanges
{
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
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
    NSFetchRequest *const fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
    self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.moc
                                                                   sectionNameKeyPath:@"lastNameInitial"
                                                                            cacheName:nil];
    _MRFetchedResultsControllerDelegate <MRFetchedResultsControllerDelegate> *const delegate = _MRFetchedResultsControllerDelegate.new;
    delegate.sectionIndexTitle = ^(NSString *sn) {
        return @"X";
    };
    self.resultsController.delegate = delegate;
    [self.resultsController performFetch:NULL];
    XCTAssertEqualObjects([self.resultsController sectionIndexTitleForSectionName:@"T"], @"X");
}

@end
