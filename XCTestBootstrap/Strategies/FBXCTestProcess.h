/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBControlCoreLogger;
@protocol FBXCTestProcessExecutor;

/**
 A Platform-Agnostic wrapper responsible for managing an xctest process.
 Driven by an executor, which implements the platform-specific responsibilities of launching an xctest process.
 */
@interface FBXCTestProcess : NSObject

/**
 The Process Idenfifer of the Launched Process.
 */
@property (nonatomic, assign, readonly) pid_t processIdentifier;

/**
 A future that resolves with the exit code of the launched process, without checking for appropriate values.
 */
@property (nonatomic, strong, readonly) FBFuture<NSNumber *> *exitCode;

/**
 The fully completed xctest process. The value here mirrors `exitCode`.
 However observing this future will mean that you are observing the additional crash detection.
 */
@property (nonatomic, assign, readonly) FBFuture<NSNumber *> *completedNormally;

/**
 Starts the Execution of an fbxctest process

 @param launchPath the Launch Path of the executable
 @param arguments the Arguments to the executable.
 @param environment the Environment Variables to set.
 @param stdOutConsumer the Consumer of the launched xctest process stdout.
 @param stdErrConsumer the Consumer of the launched xctest process stderr.
 @param executor the executor for running the test process.
 @param logger the logger to log to.
 @return a future that resolves with the launched process.
 */
+ (FBFuture<FBXCTestProcess *> *)startWithLaunchPath:(NSString *)launchPath arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment waitForDebugger:(BOOL)waitForDebugger stdOutConsumer:(id<FBDataConsumer>)stdOutConsumer stdErrConsumer:(id<FBDataConsumer>)stdErrConsumer executor:(id<FBXCTestProcessExecutor>)executor timeout:(NSTimeInterval)timeout logger:(id<FBControlCoreLogger>)logger;

@end

NS_ASSUME_NONNULL_END
