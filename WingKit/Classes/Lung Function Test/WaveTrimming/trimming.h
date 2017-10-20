//
//  trimming.h
//  TestTrimming
//
//  Created by Tom Wilkinson on 1/20/16.
//  Copyright © 2016 Tom Wilkinson. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef trimming_h
#define trimming_h

@interface TrimmingWrapper : NSObject

+ (int)trimWithInputFileName:(NSString*)inputFileName
              outputFileName:(NSString*) outputFileName;
@end

#endif /* trimming_h */
