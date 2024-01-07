@import IOSurface;
@import Foundation;
@import CoreFoundation;

#include <netinet/in.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <assert.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOTypes.h>
#include <dlfcn.h>
#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/CGImageSource.h>
#include "IOMobileFramebuffer.h"
#include <sys/stat.h>

#include "img/boot-happy.c"
#include "img/boot-sad.c"

#define WHITE 0xffffffff
#define BLACK 0x00000000
static void *base = NULL;
static int bytesPerRow = 0;
static int height = 0;
static int width = 0;

int init_display(void) {
    if (base) return 0;
    IOMobileFramebufferRef display;
    IOMobileFramebufferGetMainDisplay(&display);
    IOMobileFramebufferDisplaySize size;
    IOMobileFramebufferGetDisplaySize(display, &size);
    IOSurfaceRef buffer;
    IOMobileFramebufferGetLayerDefaultSurface(display, 0, &buffer);
    printf("got display %p\n", display);
    width = size.width;
    height = size.height;
    printf("width: %d, height: %d\n", width, height);

    // create buffer
    CFMutableDictionaryRef properties = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionarySetValue(properties, CFSTR("IOSurfaceIsGlobal"), kCFBooleanFalse);
    CFDictionarySetValue(properties, CFSTR("IOSurfaceWidth"), CFNumberCreate(NULL, kCFNumberIntType, &width));
    CFDictionarySetValue(properties, CFSTR("IOSurfaceHeight"), CFNumberCreate(NULL, kCFNumberIntType, &height));
    CFDictionarySetValue(properties, CFSTR("IOSurfacePixelFormat"), CFNumberCreate(NULL, kCFNumberIntType, &(int){ 0x42475241 }));
    CFDictionarySetValue(properties, CFSTR("IOSurfaceBytesPerElement"), CFNumberCreate(NULL, kCFNumberIntType, &(int){ 4 }));
    buffer = IOSurfaceCreate(properties);
    printf("created buffer at: %p\n", buffer);
    IOSurfaceLock(buffer, 0, 0);
    printf("locked buffer\n");
    base = IOSurfaceGetBaseAddress(buffer);
    printf("got base address at: %p\n", base);
    bytesPerRow = IOSurfaceGetBytesPerRow(buffer);
    printf("got bytes per row: %d\n", bytesPerRow);
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int offset = i * bytesPerRow + j * 4;
            *(int *)(base + offset) = 0xFFFFFFFF;
        }
    }
    printf("wrote to buffer\n");
    IOSurfaceUnlock(buffer, 0, 0);
    printf("unlocked buffer\n");

    int token;
    IOMobileFramebufferSwapBegin(display, &token);
    IOMobileFramebufferSwapSetLayer(display, 0, buffer, (CGRect){ 0, 0, width, height }, (CGRect){ 0, 0, width, height }, 0);
    IOMobileFramebufferSwapEnd(display);
    return 0;
}

#define BOOT_IMAGE_PATH "/cores/binpack/usr/share/boot.jp2"

int main(int argc, char **argv) {
    init_display();
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int offset = i * bytesPerRow + j * 4;
            *(int *)(base + offset) = 0x00000000;
        }
    }

    CFDataRef data = NULL;
    CGDataProviderRef cgDataProvider = NULL;
    CGImageRef cgImage = NULL;
    CGContextRef context = NULL;
    int retval = -1;
    if (argc == 2) {
      if (strcmp(argv[1], "failure") == 0) {
        data = CFDataCreate(NULL, sadmac, 2048 * 2732);
      } else {
        data = CFDataCreate(NULL, happymac, 2048 * 2732);
      }
    } else {
      data = CFDataCreate(NULL, happymac, 2048 * 2732);
    }
    if (!data) {
        fprintf(stderr, "could not create image URL\n");
        goto finish;
    }
    cgDataProvider = CGDataProviderCreateWithCFData(data);
    if (!cgDataProvider) {
        fprintf(stderr, "could not create image source\n");
        goto finish;
    }
    cgImage = CGImageCreate(2048, 2732, 8, 8, 2732, CGColorSpaceCreateDeviceGray(), kCGBitmapByteOrderDefault, cgDataProvider, NULL, true, kCGRenderingIntentDefault);
    if (!cgImage) {
        fprintf(stderr, "could not create image\n");
        goto finish;
    }
    context = CGBitmapContextCreate(base, 2048, 2732, 8, 2732, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
    if (!context) {
        fprintf(stderr, "could not create context\n");
        goto finish;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    retval = 0;
    fprintf(stderr, "bootscreend: done\n");
finish:
    if (context) CGContextRelease(context);
    if (cgImage) CGImageRelease(cgImage);
    if (cgDataProvider) CFRelease(cgDataProvider);
    if (data) CFRelease(data);

    return retval;
}