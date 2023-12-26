/*
 *  IOMobileFramebuffer.h
 *  iPhoneVNCServer
 *
 *  Created by Steven Troughton-Smith on 25/08/2008.
 *  Copyright 2008 Steven Troughton-Smith. All rights reserved.
 *
 *  Disassembly work by Zodttd
 *
 */

#import <IOKit/IOTypes.h>
#import <IOKit/IOKitLib.h>
#include <stdio.h> // For mprotect
#include <sys/mman.h>

#define kIOMobileFramebufferError 0xE0000000

typedef kern_return_t IOMobileFramebufferReturn;
typedef struct __IOSurface *IOSurfaceRef;
typedef struct __IOMobileFramebuffer *IOMobileFramebufferConnection;
typedef CGSize IOMobileFramebufferDisplaySize;

IOMobileFramebufferReturn IOMobileFramebufferGetMainDisplay(IOMobileFramebufferConnection*);

IOMobileFramebufferReturn IOMobileFramebufferGetDisplaySize(IOMobileFramebufferConnection connection, CGSize *t);

IOMobileFramebufferReturn IOMobileFramebufferGetLayerDefaultSurface(IOMobileFramebufferConnection connection, int surface, IOSurfaceRef *buffer);

IOMobileFramebufferReturn IOMobileFramebufferSwapBegin(IOMobileFramebufferConnection connection, int* token);
IOMobileFramebufferReturn IOMobileFramebufferSwapEnd(IOMobileFramebufferConnection connection);
IOMobileFramebufferReturn IOMobileFramebufferSwapSetLayer(IOMobileFramebufferConnection connection, int layerid, IOSurfaceRef buffer, CGRect bounds, CGRect frame);
