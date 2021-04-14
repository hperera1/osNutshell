#include <limits.h>

struct evTable
{
	char var[128][100];
	char word[128][100];
};

struct aTable
{
	char name[128][100];
	char word[128][100];
};

struct evTable variableTable;
struct aTable aliasTable;
char cwd[PATH_MAX];

int pipeFile1;
int pipeFile2;
int piping;
int appending;
int firstPipe;

int aliasIndex, variableIndex;
char* subAliases(char* name);
char *getcwd(char *buf, size_t size);
