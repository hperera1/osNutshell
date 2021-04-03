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

int aliasIndex, variableIndex;
char* subAliases(char* name);

