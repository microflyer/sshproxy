#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "NSValueTransformer+TransformerKit.h"
#import "WhitelistHelper.h"

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
                              return [NSNumber numberWithBool:[value integerValue]==OW_PROXY_MODE_ALLSITES];
                          }
//                      allowingReverseTransformationWithBlock:^id(id value) {
//                          
//                      }
         ];
        [NSValueTransformer registerValueTransformerWithName:OWProxyModeWhitelistTransformerName
                                       transformedValueClass:[NSNumber class]
                          returningTransformedValueWithBlock:^id(id value) {
                              return [NSNumber numberWithBool:[value integerValue]==OW_PROXY_MODE_WHITELIST];
                          }];
        [NSValueTransformer registerValueTransformerWithName:OWProxyModeDirectTransformerName
                                       transformedValueClass:[NSNumber class]
                          returningTransformedValueWithBlock:^id(id value) {
                              return [NSNumber numberWithBool:[value integerValue]==OW_PROXY_MODE_DIRECT];
                          }];
        
        return NSApplicationMain(argc, (const char **)argv);
    }
}
