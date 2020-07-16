/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBDevice.h"
#import "FBDevice+Private.h"

#import <XCTestBootstrap/XCTestBootstrap.h>

#import <FBControlCore/FBControlCore.h>

#import "FBAMDevice.h"
#import "FBDeviceApplicationCommands.h"
#import "FBDeviceApplicationDataCommands.h"
#import "FBDeviceControlError.h"
#import "FBDeviceCrashLogCommands.h"
#import "FBDeviceDebuggerCommands.h"
#import "FBDeviceLogCommands.h"
#import "FBDeviceScreenshotCommands.h"
#import "FBDeviceVideoRecordingCommands.h"
#import "FBDeviceXCTestCommands.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation FBDevice

@synthesize allValues = _allValues;
@synthesize amDevice = _amDevice;
@synthesize architecture = _architecture;
@synthesize buildVersion = _buildVersion;
@synthesize calls = _calls;
@synthesize deviceType = _deviceType;
@synthesize extendedInformation = _extendedInformation;
@synthesize logger = _logger;
@synthesize name = _name;
@synthesize osVersion = _osVersion;
@synthesize productVersion = _productVersion;
@synthesize state = _state;
@synthesize targetType = _targetType;
@synthesize udid = _udid;
@synthesize uniqueIdentifier = _uniqueIdentifier;

#pragma mark Initializers

- (instancetype)initWithSet:(FBDeviceSet *)set amDevice:(FBAMDevice *)amDevice logger:(id<FBControlCoreLogger>)logger
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _set = set;
  _amDevice = amDevice;
  _logger = [logger withName:amDevice.udid];
  _forwarder = [FBiOSTargetCommandForwarder forwarderWithTarget:self commandClasses:FBDevice.commandResponders statefulCommands:FBDevice.statefulCommands];
  [self cacheValuesFromInfo:amDevice];

  return self;
}

#pragma mark FBiOSTarget

- (NSArray<Class> *)actionClasses
{
  return @[
    FBTestLaunchConfiguration.class,
  ];
}

- (dispatch_queue_t)workQueue
{
  return dispatch_get_main_queue();
}

- (dispatch_queue_t)asyncQueue
{
  return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

- (FBiOSTargetDiagnostics *)diagnostics
{
  return [[FBiOSTargetDiagnostics alloc] initWithStorageDirectory:self.auxillaryDirectory];
}

- (FBProcessInfo *)containerApplication
{
  return nil;
}

- (FBProcessInfo *)launchdProcess
{
  return nil;
}

- (NSString *)auxillaryDirectory
{
  NSString *cwd = NSFileManager.defaultManager.currentDirectoryPath;
  return [NSFileManager.defaultManager isWritableFileAtPath:cwd] ? cwd : @"/tmp";
}

- (FBiOSTargetScreenInfo *)screenInfo
{
  return nil;
}

- (NSComparisonResult)compare:(id<FBiOSTarget>)target
{
  return FBiOSTargetComparison(self, target);
}

#pragma mark FBDebugDescribeable

- (NSString *)description
{
  return [self debugDescription];
}

- (NSString *)debugDescription
{
  return [FBiOSTargetFormat.fullFormat format:self];
}

- (NSString *)shortDescription
{
  return [FBiOSTargetFormat.defaultFormat format:self];
}

#pragma mark FBJSONSerializable

- (NSDictionary *)jsonSerializableRepresentation
{
  return [FBiOSTargetFormat.fullFormat extractFrom:self];
}

#pragma mark Public

+ (NSOperatingSystemVersion)operatingSystemVersionFromString:(NSString *)string
{
  NSArray<NSString *> *components = [string componentsSeparatedByCharactersInSet:NSCharacterSet.punctuationCharacterSet];
  NSOperatingSystemVersion version = {
    .majorVersion = 0,
    .minorVersion = 0,
    .patchVersion = 0,
  };
  for (NSUInteger index = 0; index < components.count; index++) {
    NSInteger value = components[index].integerValue;
    switch (index) {
      case 0:
        version.majorVersion = value;
        continue;
      case 1:
        version.minorVersion = value;
        continue;
      case 2:
        version.patchVersion = value;
        continue;
      default:
        continue;
    }
  }
  return version;
}

#pragma mark FBDevice Properties

- (NSOperatingSystemVersion)operatingSystemVersion
{
  return [FBDevice operatingSystemVersionFromString:self.amDevice.productVersion];
}

- (void)setAmDevice:(FBAMDevice *)amDevice
{
  _amDevice = amDevice;
  [self cacheValuesFromInfo:amDevice];
}

- (FBAMDevice *)amDevice
{
  return _amDevice;
}

- (void)cacheValuesFromInfo:(id<FBiOSTargetInfo, FBDevice>)targetInfo
{
  // Don't overwrite with nil values.
  if (!targetInfo) {
    return;
  }
  _allValues = targetInfo.allValues;
  _architecture = targetInfo.architecture;
  _buildVersion = targetInfo.buildVersion;
  _calls = targetInfo.calls;
  _deviceType = targetInfo.deviceType;
  _extendedInformation = targetInfo.extendedInformation;
  _name = targetInfo.name;
  _osVersion = targetInfo.osVersion;
  _productVersion = targetInfo.productVersion;
  _state = targetInfo.state;
  _targetType = targetInfo.targetType;
  _udid = targetInfo.udid;
  _uniqueIdentifier = targetInfo.uniqueIdentifier;
}

#pragma mark Forwarding

+ (NSArray<Class> *)commandResponders
{
  static dispatch_once_t onceToken;
  static NSArray<Class> *commandClasses;
  dispatch_once(&onceToken, ^{
    commandClasses = @[
      FBDeviceApplicationCommands.class,
      FBDeviceApplicationDataCommands.class,
      FBDeviceCrashLogCommands.class,
      FBDeviceDebuggerCommands.class,
      FBDeviceLogCommands.class,
      FBDeviceScreenshotCommands.class,
      FBDeviceVideoRecordingCommands.class,
      FBDeviceXCTestCommands.class,
      FBInstrumentsCommands.class,
    ];
  });
  return commandClasses;
}

+ (NSSet<Class> *)statefulCommands
{
  // All commands are stateful
  return [NSSet setWithArray:self.commandResponders];
}

- (id)forwardingTargetForSelector:(SEL)selector
{
  // Try the underling FBAMDevice instance>
  if ([self.amDevice respondsToSelector:selector]) {
    return self.amDevice;
  }
  // Try the forwarder.
  id command = [self.forwarder forwardingTargetForSelector:selector];
  if (command) {
    return command;
  }
  // Nothing left.
  return [super forwardingTargetForSelector:selector];
}

- (BOOL)conformsToProtocol:(Protocol *)protocol
{
  if ([super conformsToProtocol:protocol]) {
    return YES;
  }
  if ([self.forwarder conformsToProtocol:protocol]) {
    return  YES;
  }

  return NO;
}

@end

#pragma clang diagnostic pop
