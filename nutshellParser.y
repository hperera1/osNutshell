%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"

int yylex();
int yyerror(char *s);
int testingFunction(char *input);
int startPrintenv();
int setEnv(char *variable, char *word);
int unsetEnv(char *variable);
int changeDirectory(char *directory);
int setAlias(char *variable, char *word);
int unsetAlias(char *variable);
int listAlias();
%}

%union {char *string;}

%start cmd_line
%token <string> BYE TESTING PRINTENV STRING END SETENV UNSETENV CD ALIAS UNALIAS 

%%
cmd_line : 
	BYE END				{exit(1); return 1;}
	| TESTING STRING END		{testingFunction($2); return 1;}
	| SETENV STRING STRING END      {setEnv($2, $3); return 1;}
	| PRINTENV END			{startPrintenv(); return 1;}
	| UNSETENV STRING END		{unsetEnv($2); return 1;}
	| CD STRING END			{changeDirectory($2); return 1;}
	| ALIAS STRING STRING END       {setAlias($2, $3); return 1;}
	| UNALIAS			{unsetAlias($1); return 1;}
	| ALIAS END			{listAlias(); return 1;}

%%

int yyerror(char *s)
{
	printf("%s\n", s);
	return 0;
}

int testingFunction(char* input)
{
	printf("input: %s\n", input);

	return 1;
}

int setEnv(char *variable, char *word)
{
	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable)  == 0)
		{
			strcpy(variableTable.word[i], word);
			return 1;
		}
	}

	strcpy(variableTable.var[variableIndex], variable);
	strcpy(variableTable.word[variableIndex], word);
	variableIndex++;
	return 1;
}

int startPrintenv()
{
	printf("environment variables:\n");
	for(int i = 0; i < variableIndex; i++)
	{
		printf("%s = %s\n", variableTable.var[i], variableTable.word[i]);
	}

	return 1;
}

int unsetEnv(char *variable)
{
	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			strcpy(variableTable.var[i], variableTable.var[variableIndex - 1]);
			strcpy(variableTable.word[i], variableTable.word[variableIndex - 1]);
			variableIndex--;
			
			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int changeDirectory(char *directory)
{
	if (directory[0] != '/')
	{
		strcat(variableTable.word[0], "/");
		strcat(variableTable.word[0], directory);

		if (chdir(variableTable.word[0]) == 0) //If we succesfully change directories
		{
			return 1;
		}
		else 
		{
			getcwd(cwd, sizeof(cwd));
			strcpy(variableTable.word[0], cwd); 
			printf("Directory not found\n");
			return 1;
		}
	}
	else 
	{
		if (chdir(directory) == 0)
		{
			strcpy(variableTable.word[0], directory);
			return 1;
		}
		else 
		{
			printf("Directory not found\n");
			return 1;
		}
	}

	return 1;
}

int setAlias(char *variable, char *word)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}

	strcpy(aliasTable.name[aliasIndex], variable);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;
	return 1;
}

int unsetAlias(char *variable)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.name[i], aliasTable.name[aliasIndex - 1]);
			strcpy(aliasTable.word[i], aliasTable.word[aliasIndex - 1]);
			aliasIndex--;

			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int listAlias()
{
	printf("aliases:\n");
	for(int i = 0; i < aliasIndex; i++)
	{
		printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	return 1;
}
