#import <Foundation/Foundation.h>
#import "GGCLDelegate.h"

void usage(NSString *message) {
    printf("Usage: git-gps [init|commit|update|log]\n");
    printf("\tinit\tInitializes git-gps in a git repository.\n");
    printf("\tupdate\tUpdates the .git-gps file.\n");
    printf("\tcommit\tUsed by the commit hook. Don't run!\n");
    printf("\tlog\tUnimplemented.\n");
    if (message) {
        printf("%s\n", [message UTF8String]);
    }
}

NSString *commitHook() {
    return @"# BEGIN git-gps HOOK\n"
           @"git-gps commit\n"
           @"# END git-gps HOOK\n";
}

NSString * gitPath() {
    NSString *result = nil;
    do { // once
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *cwd = [fm currentDirectoryPath];
        if (!cwd) break;
        
        NSString *path = cwd;
        while (YES) {
            NSString *gitPath = [path stringByAppendingPathComponent:@".git"];
            BOOL isDir = NO;
            if ([fm fileExistsAtPath:gitPath isDirectory:&isDir] && isDir) {
                result = gitPath;
                break;
            }
            if ([path length] == 1) break;
            
            path = [path stringByDeletingLastPathComponent];
            if (!path || [path length] == 0) {
                break;
            }
        }
        
    } while (NO);
    return result;
}

NSString *gitGPSPath () {
    return [[gitPath() stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".git-gps"];
}

NSString *gitCommitHookPath() {
    return [gitPath() stringByAppendingPathComponent:@"hooks/post-commit"];
}

int createGitGPSHook() {
    int result = EXIT_FAILURE;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:gitCommitHookPath()]) {
        NSString *contents = [NSString stringWithContentsOfFile:gitCommitHookPath() encoding:NSUTF8StringEncoding error:nil];
        if ([contents rangeOfString:@"BEGIN git-gps HOOK"].length == 0) {
            NSRange shRange = [contents rangeOfString:@"#!/bin/sh"];
            if (shRange.location == 0 && shRange.length > 0) {
                NSString *newContents = [NSString stringWithFormat:@"%@\n%@", contents, commitHook()];
                if ([newContents writeToFile:gitCommitHookPath() atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
                    result = EXIT_SUCCESS;
                } else {
                    printf("Unable to add post-commit hook.\n");
                }
            } else {
                printf("post-commit hook must be a sh script.\n");
            }
        } else {
            result = EXIT_SUCCESS;
        }
    } else {
        NSString *contents = [NSString stringWithFormat:@"%@\n%@", @"#!/bin/sh\n", commitHook()];
        if (![contents writeToFile:gitCommitHookPath() atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
            printf("Unable to add post-commit hook.\n");
        } else {
            result = EXIT_SUCCESS;
        }
    }
    if (result == EXIT_SUCCESS) {
        NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:[NSArray arrayWithObjects:@"+x", gitCommitHookPath(), nil]];
        [chmod waitUntilExit];
    }
    return result;
}

NSString * createGitGPSFile(NSString *gitPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filePath = gitGPSPath();
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
        if (isDir) {
            usage([NSString stringWithFormat:@"\tDirectory found at: %@", filePath]);
            return nil;
        } else {
            return filePath;
        }
    }
    if ([fm createFileAtPath:filePath contents:nil attributes:nil]) {
        return filePath;
    }
    return nil;
}

int init() {
    int result = EXIT_FAILURE;
    NSString *newGitPath = gitPath();
    if (!newGitPath) {
        usage(@"\tNo .git path found in parent directories.");
        return EXIT_FAILURE;
    }
    result = createGitGPSHook();
    if (result == EXIT_SUCCESS) {
        printf("git-gps initialized at %s\n", [gitGPSPath() UTF8String]);
    }
    NSString *gitGPSPath = createGitGPSFile(newGitPath);
    if (!gitGPSPath) {
        return EXIT_FAILURE;
    }
    return result;
}

NSString *jsonForCLLocation(CLLocation *location) {
    NSString *result = @"";
    if (location) {
        NSMutableArray *parts = [NSMutableArray array];
        [parts addObject:[NSString stringWithFormat:@"\"latitude\":%f", location.coordinate.latitude]];
        [parts addObject:[NSString stringWithFormat:@"\"longitude\":%f", location.coordinate.longitude]];
        [parts addObject:[NSString stringWithFormat:@"\"altitude\":%f", location.altitude]];
        [parts addObject:[NSString stringWithFormat:@"\"horizontalAccuracy\":%f", location.horizontalAccuracy]];
        [parts addObject:[NSString stringWithFormat:@"\"verticalAccuracy\":%f", location.verticalAccuracy]];
        NSString *partsString = [parts componentsJoinedByString:@",\n    "];
        result = [NSString stringWithFormat:@"{\n    %@\n}\n", partsString];
    }
    return result;
}

BOOL updateGitGPSWithLocation(CLLocation *location) {
    NSString *result = jsonForCLLocation(location);
    if (![result writeToFile:gitGPSPath() atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        printf("%s\n", [[NSString stringWithFormat:@"Unable to update file at: %@", gitGPSPath()] UTF8String]);
        return NO;
    } else {
        printf("Added geolocation to commit.\n");
    }
    return YES;
}

int update() {
    int result = EXIT_FAILURE;
    NSString *ourGitPath = gitPath();
    if (!ourGitPath) {
        usage(@"\tNo .git path found in parent directories.");
        return result;
    }
    
    GGCLDelegate *cl = [[GGCLDelegate alloc] init];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    while (YES) {
        NSDate *now = [[NSDate alloc] init];
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:now interval:.01 target:cl selector:@selector(start:) userInfo:nil repeats:YES];
        NSDate *terminate = [[NSDate alloc] initWithTimeIntervalSinceNow:1.0];
        
        [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        [runLoop runUntilDate:terminate];
        
        [timer invalidate];
        [timer release];
        [now release];
        [terminate release];
        if ([cl goodEnough]) {
            break;
        }
    }
    
    if (updateGitGPSWithLocation(cl.location)) {
        result = EXIT_SUCCESS;
    }
    [cl release];
    
    return result;
}

int commit() {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *tombstonePath = [[gitPath() stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".git-gps-tombstone"];
    if ([fm fileExistsAtPath:tombstonePath]) {
        [fm removeItemAtPath:tombstonePath error:nil];
        return EXIT_SUCCESS;
    } else {
        [fm createFileAtPath:tombstonePath contents:nil attributes:nil];
    }
    
    int result = update();
    if (result == EXIT_SUCCESS) {
        // Try to re-commit by `git add .git-gps; git commit --amend -C HEAD`
        do { // once
            NSTask *gitAdd = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/git" arguments:[NSArray arrayWithObjects:@"add", gitGPSPath(), nil]];
            [gitAdd waitUntilExit];
            if ([gitAdd terminationStatus] != EXIT_SUCCESS) {
                result = [gitAdd terminationStatus];
                break;
            }
            
            NSTask *gitCommit = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/git" arguments:[NSArray arrayWithObjects:@"commit", @"--amend", @"-C", @"HEAD", nil]];
            [gitCommit waitUntilExit];
            if ([gitCommit terminationStatus] != EXIT_SUCCESS) {
                result = [gitCommit terminationStatus];
                break;
            }
            result = EXIT_SUCCESS;
        } while (NO);
    }
    return result;
}

int log_all() {
    int result = EXIT_SUCCESS;
    
    
    
    return result;
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int result = EXIT_FAILURE;
    do { // once
        if (argc >= 2) {
            NSString *arg = [NSString stringWithUTF8String:argv[1]];
            if ([arg isEqualToString:@"init"]) {
                result = init();
                break;
            } else if ([arg isEqualToString:@"update"]) {
                result = update();
                break;
            } else if ([arg isEqualToString:@"commit"]) {
                result = commit();
                break;
            } else if ([arg isEqualToString:@"log"]) {
                result = log_all();
                break;
            } else {
                usage([NSString stringWithFormat:@"\tUnknown argument: %@", arg]);
                break;
            }
        }
        
        usage(nil);
    } while (NO);
    
    [pool drain];
    return result;
}

