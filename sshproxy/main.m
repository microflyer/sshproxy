#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "NSValueTransformer+TransformerKit.h"

int main(int argc, char *argv[]) {
    @autoreleasepool
    {
    #ifdef DEBUG
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    #endif
        DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
        fileLogger.maximumFileSize = 1024*1024; // 1MB
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        
        [DDLog addLogger:fileLogger];
        
        NSString * const OWProxyModeAllSitesTransformerName = @"OWProxyModeAllSites";
        NSString * const OWProxyModeWhitelistTransformerName = @"OWProxyModeWhitelist";
        NSString * const OWProxyModeDirectTransformerName = @"OWProxyModeDirect";
        
        [NSValueTransformer registerValueTransformerWithName:OWProxyModeAllSitesTransformerName
                                       transformedValueClass:[NSNumber class]
                          returningTransformedValueWithBlock:^id(id value) {
                              return [NSNumber numberWithBool:[value integerValue]==0];
                          }
//                      allowingReverseTransformationWithBlock:^id(id value) {
//                          
//                      }
         ];
        [NSValueTransformer registerValueTransformerWithName:OWProxyModeWhitelistTransformerName
                                       transformedValueClass:[NSNumber class]
                          returningTransformedValueWithBlock:^id(id value) {
                              return [NSNumber numberWithBool:[value integerValue]==1];
                          }];
        [NSValueTransformer registerValueTransformerWithName:OWProxyModeDirectTransformerName
                                       transformedValueClass:[NSNumber class]
                          returningTransformedValueWithBlock:^id(id value) {
                              return [NSNumber numberWithBool:[value integerValue]==2];
                          }];
        
        return NSApplicationMain(argc, (const char **)argv);
    }
}
