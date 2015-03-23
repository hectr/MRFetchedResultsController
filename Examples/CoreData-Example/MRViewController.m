// MRViewController.m
//
// Copyright (c) 2013 Héctor Marqués
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

#import "MRViewController.h"
#import "MRAppDelegate.h"


// -----------------------------------------------------------------------------

// http://www.lifesmith.com/comnames.html

static NSString *const __surnames[] =
    { @"Smith",    @"Johnson",  @"Williams", @"Jones",    @"Brown"
    , @"Davis",    @"Miller",   @"Wilson",   @"Moore",    @"Taylor"
    , @"Anderson", @"Thomas",   @"Jackson",  @"White",    @"Harris"
    , @"Martin",   @"Thompson", @"Garcia",   @"Martinez", @"Robinson" };

static NSString *const __names[] =
    { @"Mary",   @"John",     @"Robert",  @"Patricia", @"Michael"
    , @"Linda",  @"James",    @"Barbara", @"William",  @"Elisabeth"
    , @"David",  @"Jennifer", @"Richard", @"Maria",    @"Charles"
    , @"Joseph", @"Susan",    @"Thomas",  @"Margaret", @"Dorothy" };

static NSString *const __letters[] =
    { @"A", @"B", @"C", @"D", @"E"
    , @"F", @"G", @"H", @"I", @"J"
    , @"K", @"L", @"M", @"N", @"O"
    , @"P", @"Q", @"R", @"S", @"T"
    , @"U", @"V", @"W", @"X", @"Y"
    , @"Z" };

// -----------------------------------------------------------------------------


@implementation MRViewController

// Returns the managed object context stored in _managedObjectContext.
// If there isn't any stored moc, this method gets a new one.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        self.resultsController.delegate = nil;
        self.resultsController = nil;
        MRAppDelegate *const appDelegate = UIApplication.sharedApplication.delegate;
        NSError *error = nil;
        _managedObjectContext = [appDelegate managedObjectContextWithError:&error];
        [self presentError:error];
    }
    return _managedObjectContext;
}

// This method sets up the fetched results controller and reloads the table view.
- (void)fillData
{
    if (self.managedObjectContext) {
        NSFetchRequest *const request = [NSFetchRequest fetchRequestWithEntityName:@"Employee"];
        NSSortDescriptor *const sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastNameInitial" ascending:YES];
        NSSortDescriptor *const descriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
        [request setSortDescriptors:@[ sectionDescriptor, descriptor ]];
        self.resultsController = [[MRFetchedResultsController alloc] initWithFetchRequest:request
                                                                     managedObjectContext:self.managedObjectContext
                                                                       sectionNameKeyPath:@"lastNameInitial"
                                                                                cacheName:nil];
        self.resultsController.delegate = self;
        NSError *error = nil;
        [self.resultsController performFetch:&error];
        [self presentError:error];
    }
    [self.tableView reloadData];
    self.applyChangesSwitch.on = self.resultsController.applyFetchedObjectsChanges;
    self.onSaveSwitch.on = self.resultsController.changesAppliedOnSave;
}

#pragma mark Notifications

// Notification received when the persistent store coordinator of the Core Data stack has been unset.
- (void)didUnsetPersistentStoreCoordinator:(NSNotification *const)n
{
    _managedObjectContext = nil;
    [self fillData];
}

#pragma mark - IBAction methods

// Removes the persistent store in use by the Core Data stack.
- (IBAction)removePersistentStoreAction:(id const)sender
{
    MRAppDelegate *const appDelegate = UIApplication.sharedApplication.delegate;
    NSError *error = nil;
    NSFileManager *const defaultManager = NSFileManager.defaultManager;
    NSURL *const storeURL = appDelegate.storeURL;
    [defaultManager removeItemAtURL:storeURL error:&error];
    [self presentError:error];
}

// Shows the action sheet.
- (IBAction)changeStoreAction:(id)sender
{
    UIActionSheet *const actionSheet =
    [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select which persistent store do you want to use:", nil)
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                  destructiveButtonTitle:NSLocalizedString(@"Unset persistent store URL", nil)
                       otherButtonTitles:NSLocalizedString(@"Compatible store", nil)
                                       , NSLocalizedString(@"Incompatible store", nil)
                                       , nil];
    [actionSheet showInView:self.view];
}

// Adds a new Employee object. 
- (IBAction)addEmployeeAction:(id const)sender
{
    self.onSaveSwitch.enabled = NO;
    NSManagedObjectContext *const moc = self.managedObjectContext;
    if (moc == nil) {
        NSLog(@"nil context");
        return;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Company" inManagedObjectContext:moc];
    NSManagedObject *const company = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [company setValue:[NSString stringWithFormat:@"%@.%@."
                                                , __letters[arc4random() % sizeof(__letters)/sizeof(NSInteger)]
                                                , __letters[arc4random() % sizeof(__letters)/sizeof(NSInteger)]]
                                          forKey:@"name"];
    entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:moc];
    NSManagedObject *const project = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [project setValue:[NSString stringWithFormat:@"%@%d"
                                                , __letters[arc4random() % sizeof(__letters)/sizeof(NSInteger)]
                                                , arc4random()%10]
                                          forKey:@"name"];
    [project setValue:company forKey:@"company"];
    entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:moc];
    NSManagedObject *const employee = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
    [employee setValue:__names[arc4random()%sizeof(__names)/sizeof(NSInteger)] forKey:@"firstName"];
    NSString *const lastName = __surnames[arc4random()%sizeof(__surnames)/sizeof(NSInteger)];
    [employee setValue:lastName forKey:@"lastName"];
    [employee setValue:[lastName substringToIndex:1] forKey:@"lastNameInitial"];
    [employee setValue:@(10000 + arc4random() % 490001) forKey:@"salary"];
    [employee setValue:company forKey:@"company"];
    [employee setValue:@(arc4random()%999) forKey:@"extension"];
}

// Deletes from the context the object that corresponds to the selected cell.
- (IBAction)deleteSelectedObjectAction:(id const)sender
{
    self.onSaveSwitch.enabled = NO;
    UITableView *const tableView = self.tableView;
    NSIndexPath *const indexPath = tableView.indexPathForSelectedRow;
    if (indexPath) {
        NSManagedObject *const object = [self.resultsController objectAtIndexPath:indexPath];
        if (object) {
            [self.managedObjectContext deleteObject:object];
        } else {
            NSLog(@"nil object");
        }
    } else {
        NSLog(@"no index path selected");
    }
}

// This method only re-enables onSaveSwitch. The context is saved by -[MRAppDelegate saveContexAction:].
- (IBAction)saveButtonAction:(id)sender
{
    self.onSaveSwitch.enabled = YES;
}

// Changes value of results controller applyFetchedObjectsChanges property.
- (IBAction)applyChangesSwitchAction:(id)sender
{
    self.resultsController.applyFetchedObjectsChanges = self.applyChangesSwitch.on;
}

// Changes value of results controller changesAppliedOnSave property.
- (IBAction)onSaveSwitchAction:(id)sender
{
    self.resultsController.changesAppliedOnSave = self.onSaveSwitch.on;
}

#pragma mark - UIActionSheetDelegate methods

// Delegate method of the action sheet presented by the 'Change persistent store' button.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIApplication *const sharedApplication = UIApplication.sharedApplication;
    MRAppDelegate *const appDelegate = sharedApplication.delegate;
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        return;
    } else if (actionSheet.destructiveButtonIndex == buttonIndex) {
        appDelegate.storeURL = nil;
        [appDelegate unsetPersistentStoreCoordinator];
    } else if (actionSheet.destructiveButtonIndex + 1 == buttonIndex) {
        appDelegate.automaticStoreMigration = NO;
        NSBundle *const mainBundle = NSBundle.mainBundle;
        NSURL *const src = [mainBundle URLForResource:@"CoreData-Example_v02" withExtension:@"sqlite"];
        NSFileManager *const defaultManager = NSFileManager.defaultManager;
        NSURL *const storeURL = appDelegate.storeURL;
        [defaultManager removeItemAtURL:storeURL error:nil];
        NSError *error = nil;
        [defaultManager copyItemAtURL:src toURL:storeURL error:&error];
        if (error) {
            [self presentError:error];
        } else {
            [appDelegate unsetPersistentStoreCoordinator];
        }
    } else if (actionSheet.destructiveButtonIndex + 2 == buttonIndex) {
        NSBundle *const mainBundle = NSBundle.mainBundle;
        NSURL *const src = [mainBundle URLForResource:@"CoreData-Example_v01" withExtension:@"sqlite"];
        NSFileManager *const defaultManager = NSFileManager.defaultManager;
        NSURL *const storeURL = appDelegate.storeURL;
        [defaultManager removeItemAtURL:storeURL error:nil];
        NSError *error = nil;
        [defaultManager copyItemAtURL:src toURL:storeURL error:&error];
        if (error) {
            [self presentError:error];
        } else {
            [appDelegate unsetPersistentStoreCoordinator];
        }
    }
}

#pragma mark - UITableViewDataSource methods

// Returns the number of sections fetched by the results controller.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    MRFetchedResultsController *const resultsController = self.resultsController;
    NSArray *const sections = resultsController.sections;
    NSUInteger const numberOfSections = sections.count;
    return numberOfSections;
}

// Returns the number of objects fetched by the results controller.
- (NSInteger)tableView:(UITableView *const)tableView numberOfRowsInSection:(NSInteger const)section
{
    MRFetchedResultsController *const resultsController = self.resultsController;
    NSArray *const sections = resultsController.sections;
    id<MRFetchedResultsSectionInfo> const sectionInfo = [sections objectAtIndex:section];
    NSUInteger const numberOfObjects = sectionInfo.numberOfObjects;
    return numberOfObjects;
}

// Returns a cell for the given index path.
- (UITableViewCell *)tableView:(UITableView *const)tableView cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
    static NSString *const cellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSManagedObject *const object = [self.resultsController objectAtIndexPath:indexPath];
    NSString *const firstName = [object valueForKey:@"firstName"];
    NSString *const lastName = [object valueForKey:@"lastName"];
    NSString *const fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    cell.textLabel.text = fullName;
    return cell;
}

// Returns all index titles.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *const)tableView
{
    UILocalizedIndexedCollation *const currentCollation = UILocalizedIndexedCollation.currentCollation;
    return currentCollation.sectionIndexTitles;
}

// Returns the section that corresponds to an index title.
- (NSInteger)tableView:(UITableView *const)tableView sectionForSectionIndexTitle:(NSString *const)title atIndex:(NSInteger const)index
{
    return [self.resultsController sectionForSectionIndexTitle:title];
}

#pragma mark - MRFetchedResultsControllerDelegate methods

// Prepares the table view for the updates.
- (void)controllerWillChangeContent:(MRFetchedResultsController *const)controller
{
    UITableView *const tableView = self.tableView;
    [tableView beginUpdates];
}

// Updates the table view content.
- (void)controller:(MRFetchedResultsController *const)controller didChangeObject:(id const)anObject atIndexPath:(NSIndexPath *const)indexPath forChangeType:(MRFetchedResultsChangeType const)type newIndexPath:(NSIndexPath *const)newIndexPath
{
    switch(type) {
        case MRFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case MRFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[  indexPath ] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case MRFetchedResultsChangeUpdate: {
            UITableViewCell *const cell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSManagedObject *const object = [self.resultsController objectAtIndexPath:indexPath];
            NSString *const firstName = [object valueForKey:@"firstName"];
            NSString *const lastName = [object valueForKey:@"lastName"];
            NSString *const fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            cell.textLabel.text = fullName;
        } break;
        case MRFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

// Updates the table view content.
- (void)controller:(MRFetchedResultsController *const)controller didChangeSection:(id const)sectionInfo atIndex:(NSUInteger const)sectionIndex forChangeType:(MRFetchedResultsChangeType const)type
{
    switch(type) {
        case MRFetchedResultsChangeInsert: {
            NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        } break;
        case MRFetchedResultsChangeDelete: {
            NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        } break;
        case MRFetchedResultsChangeMove:
        case MRFetchedResultsChangeUpdate:
            NSAssert(NO, @"unhandled change type");
    }
}

// Finishes the updates.
- (void)controllerDidChangeContent:(MRFetchedResultsController *const)controller
{
    UITableView *const tableView = self.tableView;
    [tableView endUpdates];
}

#pragma mark - UIViewController methods

// Prepares the view.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUnsetPersistentStoreCoordinator:)
                                               name:@"DidUnsetPersistentStoreCoordinator"
                                             object:UIApplication.sharedApplication.delegate];
    [self fillData];
}

// Cleanup.
- (void)viewDidUnload
{
    [super viewDidUnload];
    self.resultsController.delegate = nil;
    self.resultsController = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:@"DidUnsetPersistentStoreCoordinator"
                                                object:UIApplication.sharedApplication.delegate];
}

#pragma mark - UIResponder methods

// Presents the given error (if any).
- (BOOL)presentError:(NSError *const)error
{
    if (error == nil) {
        return NO;
    }
    UIAlertView *const alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                          message:error.localizedFailureReason
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
    [alert show];
    return YES;
}

#pragma mark NSObject methods

// Cleanup.
- (void)dealloc
{
    NSNotificationCenter *const defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter removeObserver:self
                             name:@"DidUnsetPersistentStoreCoordinator"
                           object:UIApplication.sharedApplication.delegate];
}

@end
