/* Read-only display/window metadata, never screenshots or permission requests.
 * Only emits windows owned by the exact child PID; no other app titles/data.
 * Compile on macOS with CoreGraphics and CoreFoundation from the installed SDK.
 */
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>

static int integer(CFDictionaryRef dictionary, CFStringRef key) {
    CFTypeRef value = CFDictionaryGetValue(dictionary, key);
    int result = -1;
    if (value && CFGetTypeID(value) == CFNumberGetTypeID()) {
        CFNumberGetValue(value, kCFNumberIntType, &result);
    }
    return result;
}

int main(int argc, char **argv) {
    int pid = argc == 2 ? atoi(argv[1]) : -1;
    CGDirectDisplayID displays[32];
    uint32_t count = 0;
    CGError error = CGGetActiveDisplayList(32, displays, &count);
    printf("{\"display_error\":%d,\"displays\":[", (int)error);
    if (error == kCGErrorSuccess) {
        for (uint32_t i = 0; i < count; i++) {
            printf("%s{\"id\":%u,\"width\":%zu,\"height\":%zu}",
                   i ? "," : "", displays[i], CGDisplayPixelsWide(displays[i]),
                   CGDisplayPixelsHigh(displays[i]));
        }
    }
    CFArrayRef windows = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID);
    printf("],\"window_query_available\":%s,\"pid\":%d,\"windows\":[",
           windows ? "true" : "false", pid);
    int found = 0;
    if (windows) {
        for (CFIndex i = 0; i < CFArrayGetCount(windows); i++) {
            CFDictionaryRef window = CFArrayGetValueAtIndex(windows, i);
            if (integer(window, kCGWindowOwnerPID) != pid) continue;
            CFDictionaryRef bounds = CFDictionaryGetValue(window, kCGWindowBounds);
            CGRect rect = CGRectZero;
            if (bounds) CGRectMakeWithDictionaryRepresentation(bounds, &rect);
            printf("%s{\"id\":%d,\"layer\":%d,\"width\":%.0f,\"height\":%.0f}",
                   found++ ? "," : "", integer(window, kCGWindowNumber),
                   integer(window, kCGWindowLayer), rect.size.width, rect.size.height);
        }
        CFRelease(windows);
    }
    puts("]}");
    return 0;
}
