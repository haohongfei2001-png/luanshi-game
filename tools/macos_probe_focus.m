// macOS hosted QA only. Bring the indicated test process forward or temporarily
// make a separate Cocoa application active until the game has processed the key-window loss.
// The parent sends an acknowledgement down a private pipe. No global keys or Accessibility.
#import <AppKit/AppKit.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <unistd.h>

static void pump(double seconds) {
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while (until.timeIntervalSinceNow > 0) {
        NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                            untilDate:until
                                               inMode:NSDefaultRunLoopMode dequeue:YES];
        if (event) [NSApp sendEvent:event];
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 3) return 2;
        NSRunningApplication *game = [NSRunningApplication
            runningApplicationWithProcessIdentifier:(pid_t)strtol(argv[2], NULL, 10)];
        if (!game) return 3;
        [NSApplication sharedApplication];
        if (strcmp(argv[1], "interrupt") == 0) {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            [NSApp finishLaunching];
            NSWindow *window = [[NSWindow alloc]
                initWithContentRect:NSMakeRect(32, 32, 220, 75)
                styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
            window.title = @"Luanshi hosted focus control";
            [window makeKeyAndOrderFront:nil];
            [NSApp activateIgnoringOtherApps:YES];
            NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:8.0];
            BOOL tookFocus = NO;
            BOOL acknowledged = NO;
            while (deadline.timeIntervalSinceNow > 0.0) {
                pump(0.05);
                if (!tookFocus && NSApp.isActive && !game.isActive) {
                    tookFocus = YES;
                    fprintf(stdout, "control_active=1 game_active=0\n");
                    fflush(stdout);
                }
                struct pollfd input = { .fd = STDIN_FILENO, .events = POLLIN };
                if (tookFocus && poll(&input, 1, 0) > 0 && (input.revents & POLLIN)) {
                    char byte = 0;
                    if (read(STDIN_FILENO, &byte, 1) == 1 && byte == '1') {
                        acknowledged = YES;
                        break;
                    }
                }
            }
            fprintf(stdout, "game_observed_pause=%d\n", (int)acknowledged);
            fflush(stdout);
        } else if (strcmp(argv[1], "foreground") != 0) {
            return 2;
        }
        BOOL requested = [game activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        pump(0.4);
        fprintf(stdout, "game_activation_requested=%d game_active=%d\n", (int)requested, (int)game.isActive);
        return game.isActive ? 0 : 4;
    }
}
