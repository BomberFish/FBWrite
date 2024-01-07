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

//void IOMobileFramebufferSwapDirtyRegion(IOMobileFramebufferRef conn);

IOMobileFramebufferRef fbConn;
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

  NSDictionary *properties = @{
    (id)kIOSurfaceIsGlobal: @(NO),
    (id)kIOSurfaceWidth: @(size.width),
    (id)kIOSurfaceHeight: @(size.height),
    (id)kIOSurfacePixelFormat: @((uint32_t)'BGRA'),
    (id)kIOSurfaceBytesPerElement: @(4)
  };
  surface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);

  //IOMobileFramebufferGetLayerDefaultSurface
  //IOMobileFramebufferCopyLayerDisplayedSurface(fbConn, 0, &surface);
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
  IOSurfaceLock(surface, 0, nil);
  memset((void *)vinfo.v_baseaddr, 0xFFFFFFFF, vinfo.v_width * vinfo.v_height);
  initialize_prescreen(vinfo);
  IOSurfaceUnlock(surface, 0, 0);

  printf("[√] PTR %p\n", IOSurfaceGetBaseAddress(surface));

  int token;
  CGRect frame = CGRectMake(0, 0, vinfo.v_width, vinfo.v_height);
  IOMobileFramebufferSwapBegin(fbConn, &token);
  IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame, 0);
  IOMobileFramebufferSwapEnd(fbConn);
}

void printText(char *str) {
    //CGRect frame = CGRectMake(0, 0, IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface));
    for (int i = 0; str[i]; i++) {
        //IOSurfaceLock(surface, 0, nil);
        char c = str[i];
        vcputc(0, 0, c);
        if (c == '\n' || !str[i+1]) {
            vcputc(0, 0, '\r');
            //IOSurfaceUnlock(surface, 0, 0);
            //IOMobileFramebufferSwapBegin(fbConn, NULL);
            //IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame);
            //IOMobileFramebufferSwapEnd(fbConn);
        }
    }
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

    printf("[*] Hammer time.\n");
    usleep(25000); // prevent any terminal output from messing with fb writes

    printText(argv[1]);

    for (int i = 0; i < 60; i++) {
        printText("Printing each 16ms, framebuffer write legit 101%\n");
        usleep(16666);
    }
    sleep(1);

    return 0;
	}
}
