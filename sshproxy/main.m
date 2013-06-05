#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

int main(int argc, char *argv[]) {
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize = 1024*1024; // 1MB
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    [DDLog addLogger:fileLogger];
    
    return NSApplicationMain(argc, (const char **)argv);
}
