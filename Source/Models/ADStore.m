//
//  ADStore.m
//  CloudStorage
//
//  Created by Jeffrey Kereakoglow on 8/5/15.
//  Copyright (c) 2015 Alexis Digital. All rights reserved.
//

#import "ADStore.h"
#import "Service.h"
#import "File.h"
@import CoreData;

static NSString *const kModelName = @"Model";

@implementation ADStore

/**
 Searches the main bundle for a property list with the name provided by the argument @c propertyListName. The root item of the property list must be a dictionary because this method returns an array of dictionary keys.
 @param propertyListName The name of the property list to load.
 @since 1.0
 @author Jeff Kereakoglow
 */
+ (NSDictionary *)dictionaryFromPropertyList:(NSString *)propertyListName {
  NSParameterAssert(propertyListName);

  NSString* resourcePath = [[NSBundle mainBundle] pathForResource:propertyListName
                                                           ofType:@"plist"];

  NSAssert(resourcePath, @"\n\n  ERROR in %s: Could not find the property list resource.\n\n", __PRETTY_FUNCTION__);

  NSDictionary *items;

  items = [NSDictionary dictionaryWithContentsOfFile:resourcePath];

  NSAssert(items, @"\n\n  ERROR in %s: Could not load the property list resource. Make sure the root item of the property list is a Dictionary.\n\n", __PRETTY_FUNCTION__);

  return items;
}

/**
 Searches the main bundle for a property list with the name provided by the argument @c propertyListName. The root item of the property list must be a dictionary because this method returns an array of dictionary keys.
 @param propertyListName The name of the property list to load.
 @since 1.0
 @author Jeff Kereakoglow
 */
+ (NSArray *)arrayFromPropertyList:(NSString *)propertyListName {
  NSParameterAssert(propertyListName);
  NSString* resourcePath = [[NSBundle mainBundle] pathForResource:propertyListName
                                                           ofType:@"plist"];

  NSAssert(resourcePath, @"\n\n  ERROR in %s: Could not find the property list resource.\n\n", __PRETTY_FUNCTION__);

  NSArray *items;

  items = [NSArray arrayWithContentsOfFile:resourcePath];

  NSAssert(items, @"\n\n  ERROR in %s: Could not load the property list resource. Make sure the root item of the property list is a Dictionary.\n\n", __PRETTY_FUNCTION__);

  return items;
}

/**
 Saves to disk managed object models which exist in a provided managed object context.
 @param managedObjectContext @c NSManagedObjectContext
 @since 1.0
 @author Jeff Kereakoglow
 */
+ (void)saveContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(managedObjectContext);

  if (!managedObjectContext.hasChanges) {
    return;
  }

  NSError *error;

#if DEBUG
  NSLog(@"\n\n  INFO: Saving the managed object context.\n\n");
#endif
  if (![managedObjectContext save:&error]) {
    NSLog(@"\n\n  ERROR SAVING MOC: %@\n\n", error.localizedDescription);
  }
}

- (Service *)serviceForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(managedObjectContext);

  return (Service *)[NSEntityDescription
                     insertNewObjectForEntityForName:[Service entityName]
                     inManagedObjectContext:managedObjectContext];
}

- (File *)fileForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(managedObjectContext);

  return (File *)[NSEntityDescription
                     insertNewObjectForEntityForName:[File entityName]
                     inManagedObjectContext:managedObjectContext];
}

- (Service *)findServiceWithDomain:(NSString *)domain inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(domain);
  NSParameterAssert(managedObjectContext);

  NSFetchRequest *fetchRequest;

  fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Service entityName]];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"domain=%@", domain];

  NSError *error;
  NSArray *results;
  results = [managedObjectContext executeFetchRequest:fetchRequest
                                                error:&error];
  // "...If an error occurs, returns nil. If no objects match the criteria
  // specified by request, returns an empty array."
  if (!results) {
    NSLog(@"%@", error.localizedDescription);
  }

  return (Service *)results.firstObject;
}

- (File *)findFileWithPath:(NSString *)path inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(path);
  NSParameterAssert(managedObjectContext);

  NSFetchRequest *fetchRequest;

  fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[File entityName]];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"path=%@", path];

  NSError *error;
  NSArray *results;
  results = [managedObjectContext executeFetchRequest:fetchRequest
                                                error:&error];

  if (!results) {
    NSLog(@"%@", error.localizedDescription);
  }

  return (File *)results.firstObject;
}

#pragma mark - Stubs

// Override
- (Service *)seedContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(managedObjectContext);

  NSString *reason;

  reason = [NSString stringWithFormat:@"You must override %@ in a subclass",
            NSStringFromSelector(_cmd)];
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:reason
                               userInfo:nil];

  return nil;
}

// Override
- (File *)parseFileMeta:(NSDictionary *)fileMeta
           withDateFormatter:(NSDateFormatter *) dateFormatter
      inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
  NSParameterAssert(fileMeta);
  NSParameterAssert(dateFormatter);
  NSParameterAssert(managedObjectContext);

  NSString *reason;

  reason = [NSString stringWithFormat:@"You must override %@ in a subclass",
            NSStringFromSelector(_cmd)];
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:reason
                               userInfo:nil];

  return nil;
}

#pragma mark - Getters
- (NSURL *)storeURL {
  static NSURL *_storeURL;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    NSError *error;
    NSURL *documentsDirectory;

    documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                inDomain:NSUserDomainMask
                                                       appropriateForURL:nil
                                                                  create:YES
                                                                   error:&error];
    if (!documentsDirectory) {
      NSLog(@"%@", error);
#if DEBUG
      abort();
#endif
    }

    _storeURL = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", kModelName]];
  });

  return _storeURL;
}

- (NSURL *)modelURL {
  static NSURL *_modelURL;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _modelURL = [[NSBundle mainBundle] URLForResource:kModelName
                                        withExtension:@"momd"];
  });

  return _modelURL;
}


@end
