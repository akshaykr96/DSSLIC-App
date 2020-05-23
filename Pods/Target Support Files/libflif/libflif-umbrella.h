#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "flif.h"
#import "flif_common.h"
#import "flif_dec.h"
#import "flif_enc.h"

FOUNDATION_EXPORT double libflifVersionNumber;
FOUNDATION_EXPORT const unsigned char libflifVersionString[];

