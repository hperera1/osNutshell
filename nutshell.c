#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include "global.h"

int main()
{
	aliasIndex = 0;
	variableIndex = 0;
	getcwd(cwd, sizeof(cwd));

	strcpy(variableTable.var[variableIndex], "PWD");
	strcpy(variableTable.word[variableIndex], cwd);
	variableIndex++;
	strcpy(variableTable.var[variableIndex], "HOME");
	strcpy(variableTable.word[variableIndex], cwd);
	variableIndex++;
	strcpy(variableTable.var[variableIndex], "PROMPT");
	strcpy(variableTable.word[variableIndex], "nutshell");
	variableIndex++;
	strcpy(variableTable.var[variableIndex], "PATH");
	strcpy(variableTable.word[variableIndex], ".:/bin");
	variableIndex++;

	strcpy(aliasTable.name[aliasIndex], ".");
	strcpy(aliasTable.word[aliasIndex], cwd);
	aliasIndex++;

	char *pointer = strrchr(cwd, '/');
	while(*pointer != '\0')
	{
		*pointer = '\0';
		pointer++;
	}

	strcpy(aliasTable.name[aliasIndex], "..");
	strcpy(aliasTable.word[aliasIndex], cwd);
	aliasIndex++;

	system("clear");
	while(1)
	{
		printf("[%s:%s]>> ", variableTable.word[2], variableTable.word[0]);
		yyparse();
	}

	return 0;
}
