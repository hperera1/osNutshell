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
int setPath(char *variable, char* word);
int builtInCheck(char *input);
void testExecl();

%}

%union {char *string;}

%start cmd_line
%token <string> BYE TESTING PRINTENV STRING END SETENV UNSETENV CD ALIAS UNALIAS

%%
cmd_line : 
	TESTING STRING END			{testingFunction($2); return 1;}
	| STRING END				{return 1;}
	| STRING STRING END			{return 1;}
	| STRING STRING STRING END		{return 1;}
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
	if(strcmp(variable, "PATH") == 0){
		printf("Handling Path\n");
		setPath(variable, word);
		return 1;
	}
	
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

int setPath(char* variable, char* word)
{
	for (int i = 0; i < variableIndex; i++){
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			int counter = 0;
			for (int j = 0; j < strlen(word); j++){
				if(strstr(&word[i],":~") == &word[i]){
					counter++;
					printf("Counter: %d\n", counter);
					j++;
				}
			}
			char *tempPath = malloc(strlen(word) + counter*(strlen(variableTable.word[1])+1));
			char *home_text = malloc(strlen(variableTable.word[1]) + 1);
			strcpy(home_text, ":");
			strcpy(&home_text[1], variableTable.word[1]);
			int iter = 0;
			
			while (*word) {
				if (strstr(word, ":~") == word) {
					strcpy(&tempPath[iter], home_text);
					iter += strlen(home_text);
					word += 2;
				}
				else{
					tempPath[iter++] = *word++;
				}
			}
		tempPath[iter] = '\0';
		
		strcpy(variableTable.word[i], tempPath);
		free(tempPath);	

		}
	}	
	return 1;
}
