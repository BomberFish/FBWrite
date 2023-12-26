#import <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
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

  printf("[*] Connection init\n");
  printf("[*] size variable init\n");
  IOMobileFramebufferDisplaySize size;
  printf("[*] getting main display\n");
  IOMobileFramebufferGetMainDisplay(&fbConn);
  printf("[*] getting display size\n");
  IOMobileFramebufferGetDisplaySize(fbConn, &size);
  printf("[i] found size %f*%f\n", size.height, size.width);
  printf("[*] getting iosurface\n");
  IOMobileFramebufferGetLayerDefaultSurface(fbConn, 0, &surface);
  printf("[i] got surface %p\n", surface);

  printf("[*] vinfo setup\n");
  struct vc_info vinfo;
  vinfo.v_width = IOSurfaceGetWidth(surface);
  vinfo.v_height = IOSurfaceGetHeight(surface);
  vinfo.v_depth = 32; // 16, 32?
  vinfo.v_type = 0;
  vinfo.v_scale = 2; //kPEScaleFactor2x;
  vinfo.v_name[0]  = 0;
  vinfo.v_rowbytes = IOSurfaceGetBytesPerRow(surface);
  vinfo.v_baseaddr = (unsigned long)IOSurfaceGetBaseAddress(surface);
  printf("[*] initializing\n");
  initialize_prescreen(vinfo);

  printf("[√] PTR %p\n", IOSurfaceGetBaseAddress(surface));
}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
    printf("FBWrite\n");
		if (argc < 2) {
      printf("[!] Expected 1 argument, got %d\n", argc - 1);
			printf("Usage: %s <string>\n", argv[0]);
			return 1;
		}
    printf("[*] fb init\n");
    initFramebuffer();
    ssize_t rsize;
    char c;

    printf("[*] Hammer time.\n");
    usleep(25000); // prevent any terminal output from messing with fb writes
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
