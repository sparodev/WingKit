#ifndef WAVDATA_H
#define WAVDATA_H

using namespace std;

//struct to hold and pass around wave file info
struct waveFileStruct{
	char chunkID[5]; // an array of 5 chars.  4 for the ID and 1 extra to put a null terminator at the end
	long fileSize;  // size of the data in the rest of the file
	char format[5]; // should be WAVE
	char subChunk1ID[5]; //should just be 'fmt '
	long subChunk1Size; //size of the first data chunk
	short audioFormat; // should be 1 for PCM
	short numChannels; // Number of channels in the recording
	long sampleRate;  //sample rate e.g. 44100
	long byteRate;  //byte rate
	short blockAlign; // alignment of the data blocks
	short bitsPerSample; //bits per sample
	char subChunk3ID[5]; //should be 'data' for actual sound data
	long subChunk3Size;  //size of the data in the file
	vector<short> data; //vector holding the actual data
	char* raw_data; //vector to hold raw data, this is used for writing back to file
};

//read the wave data, the data array can either be parsed as an array of shorts or 
//chars depending on how the data is to be used
waveFileStruct readWaveData(string fname, bool initial_read = true, bool debug = false);

//create the 'amplitude' data from the recorded audio
vector<char *> constructAmpData(waveFileStruct &, int chunk_size = 1024);

//writes a wave file given an input waveFileStruct and trim points
int writeWaveFile(string fname, waveFileStruct &, vector<int> wave_trim_points);

#endif

