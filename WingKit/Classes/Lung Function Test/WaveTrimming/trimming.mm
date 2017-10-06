//
//  wavetrimmingimpl.cpp
//  Wing
//
//  Created by Robert Asis  on 5/21/15.
//  Copyright (c) 2015 Sparo, Inc. All rights reserved.
//

#include "trimming.h"
#include "waveTrimming.h"

@implementation TrimmingWrapper

+ (int)trimWithInputFileName:(NSString*)inputFileName
              outputFileName:(NSString*)outputFileName {
    std::string inputPathNameString([inputFileName UTF8String]);
    std::string outputPathNameString([outputFileName UTF8String]);
    return trim(inputPathNameString, outputPathNameString);
}

@end
