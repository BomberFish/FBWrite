#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOSurface/IOSurfaceRef.h>
#import "IOMobileFramebuffer.h"
#include <mach/mach.h>
#include <pthread.h>
#include <spawn.h>
#include <stdio.h>

#include "console/video_console.c"

void IOMobileFramebufferSwapDirtyRegion(IOMobileFramebufferConnection conn);

IOMobileFramebufferConnection fbConn;
IOSurfaceRef surface, oldSurface;

pthread_t logger;
// int pfd[2];

// void initialize_prescreen(struct vc_info vinfo);

void initFramebuffer() {
  CGContextRef context;

  NSLog(@"[*] Connection init\n");
  IOMobileFramebufferDisplaySize size;
  IOMobileFramebufferGetMainDisplay(&fbConn);
  IOMobileFramebufferGetDisplaySize(fbConn, &size);
  IOMobileFramebufferGetLayerDefaultSurface(fbConn, 0, &surface);

/*
  NSDictionary *dict = @{
    //@"CAWindowServerSurface": @YES,
    @"CreationProperties": @{@"IOSurfacePixelSizeCastingAllowed": @YES},
    @"IOSurfaceIsGlobal": @YES,
    @"IOSurfaceName": @"CA Framebuffer (Default)",
    @"IOSurfacePixelFormat": @('RGBA'),
    @"IOSurfaceWidth": @(IOSurfaceGetWidth(oldSurface)),
    @"IOSurfaceHeight": @(IOSurfaceGetHeight(oldSurface))
  };
  surface = IOSurfaceCreate((__bridge CFDictionaryRef)dict);
  NSLog(@"SURFACE %p\n", surface);
*/

  struct vc_info vinfo;
  vinfo.v_width = IOSurfaceGetWidth(surface);
  vinfo.v_height = IOSurfaceGetHeight(surface);
  vinfo.v_depth = 32; // 16, 32?
  vinfo.v_type = 0;
  vinfo.v_scale = 2; //kPEScaleFactor2x;
  vinfo.v_name[0]  = 0;
  vinfo.v_rowbytes = IOSurfaceGetBytesPerRow(surface);
  vinfo.v_baseaddr = (unsigned long)IOSurfaceGetBaseAddress(surface);
  initialize_prescreen(vinfo);

  printf("PTR %p\n", IOSurfaceGetBaseAddress(surface));
}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		if (argc < 2) {
			printf("[*] Usage: %s <string>\n", argv[0]);
			return 1;
		}
    printf("[*] Initializing fb\n");
    // FIXME: This always segfaults
    initFramebuffer();
    ssize_t rsize;
    char c;

    printf("[*] Hammer time.\n");
    sleep(1);
    CGRect frame = CGRectMake(0, 0, IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface));
    uint8_t linesPrinted = 0;
    vcputc(0, 0, argv[1]);
    if (c == '\n') {
        vcputc(0, 0, '\r');

        if (linesPrinted < 80) {
            ++linesPrinted;
            IOMobileFramebufferSwapBegin(fbConn, NULL);
            IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame);
            IOMobileFramebufferSwapEnd(fbConn);
        }
    }
		return 0;
	}
}
