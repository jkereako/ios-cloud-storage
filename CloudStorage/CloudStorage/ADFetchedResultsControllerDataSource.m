//
//  ADFetchedResultsControllerDataSource.m
//  CloudStorage
//
//  Created by Jeffrey Kereakoglow on 8/5/15.
//  Copyright (c) 2015 Alexis Digital. All rights reserved.
//

#import "ADFetchedResultsControllerDataSource.h"

@interface ADFetchedResultsControllerDataSource ()

@property (nonatomic, readwrite) UITableView* tableView;

@end

@implementation ADFetchedResultsControllerDataSource

- (instancetype)initWithTableView:(UITableView *)tableView {
  NSParameterAssert(tableView);

  self = [super init];

  if (self) {
    _tableView = tableView;
    _tableView.dataSource = self;
  }
  return self;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(__unused UITableView*)tableView {
  return (NSInteger)self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(__unused UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
  id<NSFetchedResultsSectionInfo> section = self.fetchedResultsController.sections[(NSUInteger)sectionIndex];
  return (NSInteger)section.numberOfObjects;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  id<ADFetchedResultsControllerDataSourceDelegate> strongDelegate = self.delegate;
  id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
  id cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier
                                            forIndexPath:indexPath];
  [strongDelegate configureCell:cell withObject:object];
  return cell;
}

#pragma mark - Table view delegate
- (BOOL)tableView:(__unused UITableView*)tableView canEditRowAtIndexPath:(__unused NSIndexPath*)indexPath {
  return YES;
}

- (void)tableView:(__unused UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  id<ADFetchedResultsControllerDataSourceDelegate> strongDelegate = self.delegate;
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [strongDelegate deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
  }
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(__unused NSFetchedResultsController*)controller {
  [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(__unused NSFetchedResultsController*)controller {
  [self.tableView endUpdates];
}

- (void)controller:(__unused NSFetchedResultsController*)controller didChangeObject:(__unused id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath {
  id<ADFetchedResultsControllerDataSourceDelegate> strongDelegate = self.delegate;

  switch (type) {
    case NSFetchedResultsChangeInsert:
      [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
      break;

    case NSFetchedResultsChangeUpdate:
      [strongDelegate configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
                         withObject:anObject];
      break;

    case NSFetchedResultsChangeMove:
      [self.tableView moveRowAtIndexPath:indexPath
                             toIndexPath:newIndexPath];
      break;
    case NSFetchedResultsChangeDelete:
      [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    default:
      NSAssert(NO, @"\n\n  UNEXPECTED BEHAVIOR in %s\n\n", __PRETTY_FUNCTION__);
      break;
  }
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
  NSParameterAssert(fetchedResultsController);
  NSAssert(_fetchedResultsController == nil,
           @"\n\n ERROR in %s: Cannot redefine the property \"_fetchedResultsController\"",
           __PRETTY_FUNCTION__);
  _fetchedResultsController = fetchedResultsController;
  fetchedResultsController.delegate = self;
  [fetchedResultsController performFetch:NULL];
}


- (id)selectedItem {
  NSIndexPath* path = self.tableView.indexPathForSelectedRow;
  return path ? [self.fetchedResultsController objectAtIndexPath:path] : nil;
}


- (void)setPaused:(BOOL)paused {
  _paused = paused;
  if (paused) {
    self.fetchedResultsController.delegate = nil;
  }
  else {
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:NULL];
    [self.tableView reloadData];
  }
}


@end
