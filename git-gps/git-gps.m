#import <Foundation/Foundation.h>
#import "GGCLDelegate.h"

void usage(NSString *message) {
    NSLog(@"Usage: git-gps [init|commit|update]");
    if (message) {
        NSLog(@"%@", message);
    }
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

NSString * createGitGPSFile(NSString *gitPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filePath = gitGPSPath();
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
        if (isDir) {
            usage([NSString stringWithFormat:@"\tDirectory found at: %@", filePath]);
        } else {
            usage([NSString stringWithFormat:@"\t.git-gps file already exists at: %@", filePath]);
        }
        return nil;
    }
    if ([fm createFileAtPath:filePath contents:nil attributes:nil]) {
        return filePath;
    }
    return nil;
}

int init() {
    NSString *newGitPath = gitPath();
    if (!newGitPath) {
        usage(@"\tNo .git path found in parent directories.");
        return EXIT_FAILURE;
    }
    NSString *gitGPSPath = createGitGPSFile(newGitPath);
    if (!gitGPSPath) {
        return EXIT_FAILURE;
    }
    NSLog(@"git-gps initialized at %@", gitGPSPath);
    return EXIT_SUCCESS;
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
        NSLog(@"%@", [NSString stringWithFormat:@"Unable to update file at: %@", gitGPSPath()]);
        return NO;
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
    int result = update();
    if (result == EXIT_SUCCESS) {
        
    }
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

