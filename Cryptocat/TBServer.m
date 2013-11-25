//
//  TBServer.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 22/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBServer.h"

#define kDefaultsUserSavedServersKey  @"TBUserSavedServers"
#define kDefaultsCurrentServerKey     @"TBCurrentServer"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServer ()

- (NSDictionary *)serverDic;
+ (NSArray *)defaultServers;
+ (void)loadDefaultServers;
+ (NSInteger)indexForServerName:(NSString *)serverName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBServer

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
  if (self=[super init]) {
    _name = @"";
    _domain = @"";
    _conferenceServer = @"";
    _boshRelay = @"";
    _readonly = NO;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)addServer:(TBServer *)server {
  if ([self indexForServerName:server.name]!=-1) return NO; // name already exists
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  NSDictionary *serverDic = server.serverDic;
  [serverDics addObject:serverDic];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)updateServer:(TBServer *)server atIndex:(NSUInteger)index {
  NSUInteger nbDefaultServers = [[self defaultServers] count];
  NSUInteger adjustedIndex = index - nbDefaultServers;
  NSInteger foundIndex = [self indexForServerName:server.name];
  if (foundIndex!=-1 && foundIndex!=adjustedIndex) return NO; // name already exists
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  [serverDics replaceObjectAtIndex:adjustedIndex withObject:server.serverDic];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)deleteServer:(TBServer *)server {
  NSInteger index = [self indexForServerName:server.name];
  if (index==-1) return NO;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  [serverDics removeObjectAtIndex:index];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)servers {
  [self loadDefaultServers];
  
  NSMutableArray *servers = [NSMutableArray array];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSArray *serverDics = [defaults arrayForKey:kDefaultsUserSavedServersKey];
  
  for (NSDictionary *serverDic in serverDics) {
    [servers addObject:[TBServer serverFromDic:serverDic]];
  }
  
  return servers;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (TBServer *)currentServer {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  
  NSDictionary *serverDic = [defaults objectForKey:kDefaultsCurrentServerKey];
  
  // no default found, choose the first server
  if (serverDic==nil) {
    return [[self servers] objectAtIndex:0];
  }
  else {
    return [self serverFromDic:serverDic];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)setCurrentServer:(TBServer *)server {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:server.serverDic forKey:kDefaultsCurrentServerKey];
  [defaults synchronize];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (TBServer *)serverFromDic:(NSDictionary *)serverDic {
  TBServer *server = [[TBServer alloc] init];
  server.name = [serverDic objectForKey:@"name"];
  server.domain = [serverDic objectForKey:@"domain"];
  server.conferenceServer = [serverDic objectForKey:@"conferenceServer"];
  server.boshRelay = [serverDic objectForKey:@"boshRelay"];
  server.readonly = [[serverDic objectForKey:@"readonly"] boolValue];
  
  return server;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)serverDic {
  return @{@"name": self.name,
           @"domain": self.domain,
           @"conferenceServer": self.conferenceServer,
           @"boshRelay": self.boshRelay,
           @"readonly": [NSNumber numberWithBool:self.isReadonly]};
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)defaultServers {
  TBServer *server = [[TBServer alloc] init];
  server.name = @"Cryptocat";
  server.domain = @"crypto.cat";
  server.conferenceServer = @"conference.crypto.cat";
  server.readonly = YES;

  return @[server];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)loadDefaultServers {
  for (TBServer *server in [self defaultServers]) {
    [self addServer:server];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSInteger)indexForServerName:(NSString *)serverName {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSArray *serverDics = [defaults arrayForKey:kDefaultsUserSavedServersKey];
  NSUInteger nbServers = [serverDics count];
  
  for (NSInteger i = 0; i < nbServers; i++) {
    NSDictionary *serverDic = [serverDics objectAtIndex:i];
    if ([[serverDic objectForKey:@"name"] isEqualToString:serverName]) {
      return i;
    }
  }

  return -1; // not found
}

@end