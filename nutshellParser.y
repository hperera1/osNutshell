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

%}

%union {char *string;}

%start cmd_line
%token <string> BYE TESTING PRINTENV STRING END

%%
cmd_line : 
	BYE END				{exit(1); return 1;}
	| TESTING STRING END		{testingFunction($2); return 1;}
	| PRINTENV END			{startPrintenv(); return 1;}

%%

int yyerror(char *s)
{
	printf("%s\n", s);
	return 0;
}

int testingFunction(char* input)
{
	printf("~in testingFunction()~\n");
	printf("input: %s\n", input);

	if(input[0] == 'T')
	{
		printf("the input started with a T lolz\n");
	}
	else
	{	
		printf("whatever you put in, i don't understand it\n");
	}

	return 1;
}

int startPrintenv()
{
	printf("environment variables:\n");
	for(int i = 0; i < variableIndex; i++)
	{
		printf("%s = %s\n", variableTable.var[i], variableTable.word[i]);
	}

	printf("\naliases:\n");
	for(int i = 0; i < aliasIndex; i++)
	{
		printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
	}

	return 1;
}
