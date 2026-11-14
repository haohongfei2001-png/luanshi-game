#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// The compositor must see clicks at its real cursor. Only operate on the foreground game
// of a disposable hosted Mac, within its checked content bounds.
int main(int argc,char **argv) {
    if (argc!=5) return 2;
    @autoreleasepool {
        if (!getenv("GITHUB_ACTIONS") || strcmp(getenv("GITHUB_ACTIONS"),"true") ||
            !getenv("RUNNER_OS") || strcmp(getenv("RUNNER_OS"),"macOS")) return 8;
        [NSApplication sharedApplication];
        pid_t pid=(pid_t)strtol(argv[1],NULL,10);
        NSArray *windows=CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements,kCGNullWindowID));
        for (NSDictionary *item in windows) {
            if ([item[(id)kCGWindowOwnerPID] intValue]!=pid || [item[(id)kCGWindowLayer] intValue]!=0) continue;
            CGRect rect;
            if (!CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)item[(id)kCGWindowBounds],&rect) || rect.size.width<600.) continue;
            if (!strcmp(argv[2],"capture")) {
                NSString *window=[item[(id)kCGWindowNumber] stringValue];
                NSTask *shot=[NSTask new];
                shot.launchPath=@"/usr/sbin/screencapture";
                shot.arguments=@[@"-x",@"-o",@"-t",@"jpg",[@"-l" stringByAppendingString:window],[NSString stringWithUTF8String:argv[3]]];
                [shot launch]; [shot waitUntilExit]; return shot.terminationStatus;
            }
            if (strcmp(argv[2],"click")) return 3;
            double scale=rect.size.width/1280.;
            double title=fmax(0.,rect.size.height-800.*scale);
            CGPoint p=CGPointMake(rect.origin.x+strtod(argv[3],NULL)*scale,rect.origin.y+title+strtod(argv[4],NULL)*scale);
            if (!CGRectContainsPoint(rect,p) || NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier!=pid) return 9;
            CGWarpMouseCursorPosition(p);
            [NSThread sleepForTimeInterval:.10];
            CGEventType phases[]={kCGEventMouseMoved,kCGEventLeftMouseDown,kCGEventLeftMouseUp};
            for (int i=0;i<3;i++) {
                CGEventRef event=CGEventCreateMouseEvent(NULL,phases[i],p,kCGMouseButtonLeft);
                if (!event) return 5;
                CGEventSetIntegerValueField(event,kCGMouseEventClickState,1);
                CGEventPost(kCGHIDEventTap,event); CFRelease(event);
                [NSThread sleepForTimeInterval:.11];
            }
            printf("click window %g x %g (title %g) at %g %g\n",rect.size.width,rect.size.height,title,p.x,p.y);
            return 0;
        }
    }
    return 4;
}
