// This source file defines the relevant functions for turning a trimming
// terminal point (the start and stop points for trimming) from the amplitude
// data array into points that correspond to points in the original audio
// signal.
//

#include <vector>
#include <string>
#include <math.h>

#include "trimmingTerminalPoints.h"

using namespace std;

// Rescale function. Rescales a point from an array of one size to the
// corresponding point in an array of a different size.
int rescale(int oldPoint, int oldSize, int newSize){
	float ratio = (float) oldPoint / (float) oldSize;
	return (int)(ratio * newSize);
}

// Pads the trimming start point.  This allows for the trimming start point
// to be moved 'backwards' in the time domain to ensure that no data is cut
// off that should be part of the target data area.
int padSndStart(int startPt, int chunkSize, int nchunks){
	int padding = nchunks * chunkSize;
	int adjusted = 0;
	if ((startPt - padding) > 0){
		adjusted = (startPt - padding);
	}
	return adjusted;
}

// Pads the trimming end point.  This allows for the trimming end point to be
// moved 'forward' in the time domain to ensure that no data is cut off that
// should be part of the target data area.
int padSndEnd(int endPt, int chunkSize, vector<char*> smoothedAmpData,
	int nchunks){
	int padding = nchunks * chunkSize;
	int adjusted = (((int) smoothedAmpData.size()) * chunkSize);
	if ((endPt + padding) < (smoothedAmpData.size() * chunkSize)){
		adjusted = (endPt + padding);
	}
	return adjusted;
}

// This function calls necessary functions as subroutines to determine the
// trimming start point with respect to the signal data from the input amplitude
// start point.
int determineSndStartPoint(int ampStart, vector<char *> smoothedAmpData,
													int chunkSize){
	int sndStartIndex = rescale(ampStart, (int) smoothedAmpData.size(),
                                (int) (smoothedAmpData.size() * chunkSize));
	int padded = padSndStart(sndStartIndex, chunkSize);
	return padded;
}

// This function calls necessary functions as subroutines to determine the
// trimming end point with respect to the signal data from the input amplitude
// end point.
int determineSndEndPoint(int ampEnd, vector<char *> smoothedAmpData,
													int chunkSize){
	int sndEndIndex = rescale(ampEnd, (int) smoothedAmpData.size(),
                              (int) (smoothedAmpData.size() * chunkSize));
	int padded = padSndEnd(sndEndIndex, chunkSize, smoothedAmpData);
	return padded;
}
