// This header file declares the functions needed to interface between the
// trimming start and end points (collectively called terminal points) of the
// amplitude data and turns them into points relative to the original sound
// data array.
#ifndef TRIMMINGTERMINALPOINTS_H
#define TRIMMINGTERMINALPOINTS_H

using namespace std;

// Rescale function. Rescales a point from an array of one size to the
// corresponding point in an array of a different size.
int rescale(int oldPoint, int oldSize, int newSize);

// Pads the trimming start point.  This allows for the trimming start point
// to be moved 'backwards' in the time domain to ensure that no data is cut
// off that should be part of the target data area.
int padSndStart(int startPt, int chunkSize, int nchunks = 2);

// Pads the trimming end point.  This allows for the trimming end point to be
// moved 'forward' in the time domain to ensure that no data is cut off that
// should be part of the target data area.
int padSndEnd(int endPt, int chunkSize, vector<char*> smoothedAmpData,
	int nchunks = 2);

// This function calls necessary functions as subroutines to determine the
// trimming start point with respect to the signal data from the input amplitude
// start point.
int determineSndStartPoint(int ampStart, vector<char *> smoothedAmpData,
	int chunkSize);

// This function calls necessary functions as subroutines to determine the
// trimming end point with respect to the signal data from the input amplitude
// end point.
int determineSndEndPoint(int ampEnd, vector<char *> smoothedAmpData,
	int chunkSize);


#endif
