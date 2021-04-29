#ifndef process_h
#define process_h

#include "wren.h"

#define WREN_PATH_MAX 4096

// Stores the command line arguments passed to the CLI.
void osSetArguments(int argc, const char* argv[]);

// get current home directly 
// (returns pointer to allocated ram must be released later)
char* getHomeDirectory();

#endif
