// This header file declares functions used to parse and perform calculations
// based on the amplitude array.
// Author: Rajeev Mehrotra
//

#ifndef AMPARRAY_H
#define AMPARRAY_H

using namespace std;

// Struct of ints.  This encapsulates a Point, i.e. a 2D point with an
// xcoordinate and a ycoordinate.  This is implemented as a utility, the
// the calculations performed on the amplitude array can pass around an xyPoint
// instead of the vector index of an amplitude element of interest.
struct xyPoint{
	int xCoord;
	int yCoord;
};

// Reads amplitude data froma  file.
vector<char*> readAmpDataFile(string & fname);

// Smooths noise from amplitude data.
vector<char *> smoothAmpData(vector<char *> rawAmpData, int threshold);

// Determines the index of the maximum value in the amplitude array.
int argMaxAmp(vector<char *> arr);

// Determine the first time-wise trimming point.  Returns an xyPoint.
xyPoint determineStartPoint(vector<char *> smoothedAmpData, int maxInd);

// Determine the first time-wise trimming point.  Returns an int index.
int determineStartIndex(vector<char *> smoothedAmpData, int maxInd);

// Determines the second time-wise trimming point.  Returns an xyPoint.
xyPoint determineEndPoint(vector<char *> smoothedAmpData, int maxInd,
							double percent = 0.1, int allowedSilence = 10);

// Determines the second time-wise trimming point.  Returns an int index.
int determineEndIndex(vector<char *> smoothedAmpData, int maxInd,
						double percent = 0.1, int allowedSilence = 10);

#endif
