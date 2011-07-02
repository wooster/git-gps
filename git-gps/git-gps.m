#import <Foundation/Foundation.h>

void usage(NSString *message) {
    NSLog(@"Usage: git-gps [init|commit]");
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

BOOL createGitGPSFile(NSString *path) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filePath = [path stringByAppendingPathComponent:@".git-gps"];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
        if (isDir) {
            usage([NSString stringWithFormat:@"\tDirectory found at: %@", filePath]);
        } else {
            usage([NSString stringWithFormat:@"\t.git-gps file already exists at: %@", filePat]);
        }
        return NO;
    }
    if ([fm createFileAtPath:filePath contents:nil attributes:nil]) {
        return YES;
    }
    return NO;
}

int init() {
    NSString *path = gitPath();
    if (!path) {
        usage(@"\tNo .git path found in parent directories.");
        return 0;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *git
    return 1;
}

int update() {
    return 1;
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int result = 0;
    do { // once
        if (argc >= 2) {
            NSString *arg = [NSString stringWithUTF8String:argv[1]];
            if ([arg isEqualToString:@"init"]) {
                result = init();
                break;
            } else if ([arg isEqualToString:@"update"]) {
                result = update();
                break;
            } else {
                usage([NSString stringWithFormat:@"\tUnknown argument: %@", arg]);
                break;
            }
        }
        
        usage(nil);
    } while (NO);
    
    [pool drain];
    return 0;
}
