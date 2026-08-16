#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// Method export for the Swift `HealthKits` class. The actual implementations
// live in HealthKits.swift; these declarations expose them to React Native.
@interface RCT_EXTERN_MODULE(HealthKits, RCTEventEmitter)

RCT_EXTERN_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(requestPermissions:(NSString *)permissionsJson
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getPermissionStatus:(NSString *)dataType
                  accessType:(NSString *)accessType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(readData:(NSString *)optionsJson
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(writeData:(NSString *)dataJson
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(subscribeToUpdates:(NSString *)dataType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(unsubscribeFromUpdates:(NSString *)subscriptionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(openHealthConnectSettings:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end

// New Architecture: bind the module to the codegen-generated TurboModule spec.
// `RNHealthKitsSpec` is codegenConfig.name; the generated protocol/JSI class are
// derived from the spec file name (NativeHealthKits.ts -> NativeHealthKitsSpec).
#ifdef RCT_NEW_ARCH_ENABLED
#import <RNHealthKitsSpec/RNHealthKitsSpec.h>

@interface HealthKits (TurboModule) <NativeHealthKitsSpec>
@end

@implementation HealthKits (TurboModule)

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeHealthKitsSpecJSI>(params);
}

@end
#endif
