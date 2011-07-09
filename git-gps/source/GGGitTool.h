//
//  GGGitTool.h
//  git-gps
//
//  Created by Andrew Wooster on 7/9/11.
//  Copyright 2011 Andrew Wooster. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GGGitTool : NSObject {
@private
    NSString *gitPath;
    int terminationStatus;
}
+ (GGGitTool *)sharedGitTool;

- (NSString *)gitCommand:(NSArray *)arguments;
- (NSString *)gitAdd:(NSString *)path;

/*! The terminationStatus of the last command. */
- (int)terminationStatus;
@end
