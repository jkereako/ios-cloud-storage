//
//  ADFileListTableViewController.m
//  CloudStorage
//
//  Created by Jeffrey Kereakoglow on 8/13/15.
//  Copyright © 2015 Alexis Digital. All rights reserved.
//

@import MobileCoreServices;
#import "ADFileListTableViewController.h"
#import "ADFetchedResultsControllerDataSource.h"
#import "ADOAuth2Client.h"
#import "Service.h"
#import "File.h"
#import "ADDropboxStore.h"

@interface ADFileListTableViewController ()<ADFetchedResultsControllerDataSourceDelegate>

@property (nonatomic, readwrite) ADFetchedResultsControllerDataSource* fetchedResultsControllerDataSource;

- (IBAction)refreshAction:(UIRefreshControl *)sender;
- (IBAction)addFileAction:(UIBarButtonItem *)sender;
- (void)setUpFetchedResultsController;

@end

@implementation ADFileListTableViewController

#pragma mark - View controller life cycle
- (void)viewDidLoad {
  NSAssert(self.service,
           @"\n\n  ERROR in %s: The property \"_managedObjectContext\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  [super viewDidLoad];

  self.title = self.service.name;

  [self setUpFetchedResultsController];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.fetchedResultsControllerDataSource.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  self.fetchedResultsControllerDataSource.paused = YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
  NSAssert(self.managedObjectContext,
           @"\n\n  ERROR in %s: The property \"_managedObjectContext\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  // Save the context everytime the user hits the back button.
  [ADStore saveContext:self.managedObjectContext];

  [super didMoveToParentViewController:parent];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions
- (IBAction)refreshAction:(UIRefreshControl * __unused)sender {
  NSAssert(self.service,
           @"\n\n  ERROR in %s: The property \"_service\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.service.client,
           @"\n\n  ERROR in %s: The property \"_service.client\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.service.client.dateFormat,
           @"\n\n  ERROR in %s: The property \"_service.client.dateFormat\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.managedObjectContext,
           @"\n\n  ERROR in %s: The property \"_managedObjectContext\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.dateFormatter,
           @"\n\n  ERROR in %s: The property \"_dateFormatter\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  ADFileListTableViewController * __weak weakSelf = self;

  [self.service.client listFiles:^(NSArray * fileList) {
    // Do not perform any UI updates unless we are on the main thread.
    NSAssert([NSThread isMainThread],
             @"\n\n  ERROR in %s: Attempted to update UI on a background thread.\n\n",
             __PRETTY_FUNCTION__);

    ADDropboxStore *store = [ADDropboxStore new];
    NSString *originalDateFormat;
    originalDateFormat = weakSelf.dateFormatter.dateFormat;
    weakSelf.dateFormatter.dateFormat = weakSelf.service.client.dateFormat;

    for (NSDictionary *fileMeta in fileList) {
      // Skip if the file already exists in the managed object context.
      if ([store findFileWithPath:fileMeta[@"path"]
           inManagedObjectContext:weakSelf.managedObjectContext]) {
        continue;
      }

      File *newFile =  [store parseFileMeta:fileMeta
                          withDateFormatter:weakSelf.dateFormatter
                     inManagedObjectContext:weakSelf.managedObjectContext];


      // Associate the file with the service.
      [weakSelf.service addFilesObject:newFile];
    }

    weakSelf.service.lastQueryMadeOn = [NSDate date];
    weakSelf.service.totalQueriesMade = @(1 + weakSelf.service.totalQueriesMade.unsignedIntegerValue);
    weakSelf.dateFormatter.dateFormat = originalDateFormat;

    [self.refreshControl endRefreshing];
  }];
}

- (IBAction)addFileAction:(UIBarButtonItem * __unused)sender {
  NSAssert(self.service,
           @"\n\n  ERROR in %s: The property \"_service\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.service.client,
           @"\n\n  ERROR in %s: The property \"_service.client\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.service.client.dateFormat,
           @"\n\n  ERROR in %s: The property \"_service.client.dateFormat\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.managedObjectContext,
           @"\n\n  ERROR in %s: The property \"_managedObjectContext\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.dateFormatter,
           @"\n\n  ERROR in %s: The property \"_dateFormatter\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  NSString *fileName;
  NSURL *fileURL;
  NSString *fileContents;
  NSError * __block error;
  BOOL __block success = NO;
  fileName = [NSString stringWithFormat:@"%@.txt",
              [[NSProcessInfo processInfo] globallyUniqueString]];
  fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
  fileContents = NSLocalizedString(@"fileTableView.file.contents", @"Lorem ipsum");

  // Write the file to disk.
  success = [fileContents writeToURL:fileURL
                          atomically:YES
                            encoding:NSUTF16StringEncoding
                               error:&error];

  if (!success) {
    NSLog(@"%@", error.localizedDescription);
    NSAssert(NO,
             @"\n\n  ERROR in %s: Could not save data as a temporary  file.\n\n",
             __PRETTY_FUNCTION__);
  }

  ADFileListTableViewController * __weak weakSelf = self;

  [self.service.client putFile:fileURL
              mimeType:(NSString *)kUTTypePlainText
     completionHandler:^(NSDictionary * fileMeta){
       NSParameterAssert(fileMeta);
       File *newFile;
       ADDropboxStore *store = [ADDropboxStore new];
       NSString *originalDateFormat;
       originalDateFormat = weakSelf.dateFormatter.dateFormat;
       weakSelf.dateFormatter.dateFormat = weakSelf.service.client.dateFormat;

       newFile = [store parseFileMeta:fileMeta
                    withDateFormatter:weakSelf.dateFormatter
               inManagedObjectContext:weakSelf.managedObjectContext];

       NSAssert(newFile,
                @"\n\n  ERROR in %s: The variable \"newFile\" is nil.\n\n",
                __PRETTY_FUNCTION__);

       // Associate the file with the service.
       [weakSelf.service addFilesObject:newFile];
       weakSelf.service.lastQueryMadeOn = [NSDate date];
       weakSelf.service.totalQueriesMade = @(1 + weakSelf.service.totalQueriesMade.unsignedIntegerValue);

       weakSelf.dateFormatter.dateFormat = originalDateFormat;

       // Remove the file
       if ([[NSFileManager defaultManager] isDeletableFileAtPath:fileURL.path]) {
         success = [[NSFileManager defaultManager] removeItemAtPath:fileURL.path
                                                              error:&error];
         if (!success) {
           NSLog(@"%@", error.localizedDescription);
           NSAssert(NO,
                    @"\n\n  ERROR in %s: Could not delete temporary file.\n\n",
                    __PRETTY_FUNCTION__);
         }

       }
       else {
         NSAssert(NO,
                  @"\n\n  ERROR in %s: The temporary file is not deletable.\n\n",
                  __PRETTY_FUNCTION__);
       }
     }];
}

#pragma mark - FetchedResultsControllerDataSourceDelegate
- (void)configureCell:(UITableViewCell *)theCell withObject:(File *)object {
  NSParameterAssert(theCell);
  NSParameterAssert(object);
  NSAssert(self.dateFormatter,
           @"\n\n  ERROR in %s: The property \"_dateFormatter\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  theCell.detailTextLabel.text = object.path;
  theCell.textLabel.text = [self.dateFormatter stringFromDate:object.lastModified];
}

- (void)deleteObject:(id __unused)object {
}

#pragma mark - "Private" methods
- (void)setUpFetchedResultsController {
  NSAssert(self.fetchedResultsControllerDataSource == nil,
           @"\n\n  ERROR in %s: Cannot redefine the property \"_fetchedResultsControllerDataSource\" is nil.\n\n",
           __PRETTY_FUNCTION__);
  NSAssert(self.managedObjectContext,
           @"\n\n  ERROR in %s: The property \"_managedObjectContext\" is nil.\n\n",
           __PRETTY_FUNCTION__);

  NSFetchedResultsController *fetchedResultsController;
  NSFetchRequest* fetchRequest;

  fetchRequest = [NSFetchRequest
                  fetchRequestWithEntityName:[File entityName]];
  fetchRequest.sortDescriptors = @[[NSSortDescriptor
                                    sortDescriptorWithKey:@"lastModified"
                                    ascending:NO]];
  fetchedResultsController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:fetchRequest
                              managedObjectContext:self.managedObjectContext
                              sectionNameKeyPath:nil
                              cacheName:nil];

  self.fetchedResultsControllerDataSource = [[ADFetchedResultsControllerDataSource alloc]
                                             initWithTableView:self.tableView];
  self.fetchedResultsControllerDataSource.fetchedResultsController = fetchedResultsController;
  self.fetchedResultsControllerDataSource.delegate = self;
  self.fetchedResultsControllerDataSource.reuseIdentifier = @"file";
}

@end
