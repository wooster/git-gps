//
//  GGGitTool.m
//  git-gps
//
//  Created by Andrew Wooster on 7/9/11.
//  Copyright 2011 Andrew Wooster. All rights reserved.
//

#import "GGGitTool.h"

@interface GGGitTool (Private)
- (NSString *)determineGitPath;
- (NSString *)runTaskAndGatherOutput:(NSTask *)task;
- (NSString *)runGitCommandAndGatherOutput:(NSArray *)arguments;
@end

static GGGitTool *sharedGitTool = nil;

@implementation GGGitTool

+ (GGGitTool *)sharedGitTool {
    @synchronized(self) {
        if (sharedGitTool == nil) {
            sharedGitTool = [[GGGitTool alloc] init];
        }
    }
    return sharedGitTool;
}

- (id)init {
    if ((self = [super init])) {
        gitPath = [[self determineGitPath] retain];
    }
    return self;
}

- (void)dealloc {
    [gitPath release], gitPath = nil;
    [super dealloc];
}

- (int)terminationStatus {
    return terminationStatus;
}

- (NSString *)gitCommand:(NSArray *)arguments {
    return [self runGitCommandAndGatherOutput:arguments];
}

- (NSString *)gitAdd:(NSString *)path {
    return [self runGitCommandAndGatherOutput:[NSArray arrayWithObjects:@"add", path, nil]];
}

@end

@implementation GGGitTool (Private)
- (NSString *)determineGitPath {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/which"];
    [task setArguments:[NSArray arrayWithObjects:@"git", nil]];
    NSString *path = [self runTaskAndGatherOutput:task];
    [task release], task = nil;
    path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return path;
}

- (NSString *)runTaskAndGatherOutput:(NSTask *)task {
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    [task waitUntilExit];
    NSData *data = [file readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [result autorelease];
}

- (NSString *)runGitCommandAndGatherOutput:(NSArray *)arguments {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:gitPath];
    [task setArguments:arguments];
    NSString *result = [self runTaskAndGatherOutput:task];
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    terminationStatus = [task terminationStatus];
    [task release], task = nil;
    return result;
}
@end
