%{
#include "nutshellParser.tab.h"
#include "global.h"
#include <string.h>
#include <stdbool.h>
#include <unistd.h>

char* expandAlias(char* name){
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(aliasTable.name[i], name) == 0) {
			return aliasTable.word[i];
		}
	}
	return name;
}

bool ifAlias(char* name){
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(aliasTable.name[i], name) == 0) {
			return true;
		}
	}
	return false;
}

bool ifNotBuiltIn(char *input){
	pid_t pid;
	int returnVal;
	const char slash = '/';

	char *path = strchr(strdup(variableTable.word[3]), slash);
	strcat(path, "/");
	strcat(path, input);

	if((pid = fork()) == -1)
		perror("fork error!");
	else if(pid == 0)
	{
		returnVal = execl(path, input, NULL);
	}

	if(returnVal == -1)
		return 0;

	return 1;
}

%}
%array
%option noyywrap

CHAR		[:.A-Za-z0-9!\/_-~][:.A-Za-z0-9!\/_-~]*
ANYCHAR		[:)(*&%#@!`;,\.a-zA-Z0-9'/_=~-][:)(*&%#@!`;,\.a-zA-Z0-9'/_=~-]*
WILD		[/*?][*?]*
CHARS		[:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
META		[\<\>\|\"\\\&]

%x string_condition
%x env_condition
%x unalias_condition
%%

<string_condition>{CHARS}*"${"{CHARS}+"}"{CHARS}*	{
							printf("we got him\n");
							yylval.string = strdup( yytext );
							return ENVSTRING;
							}

<string_condition>{CHARS}+	{yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]		{BEGIN(INITIAL);}

<env_condition>{CHARS}+		{
				yylval.string = strdup(yytext);
				printf("yytext: %s\n", yylval.string);
				for (int i = 0; i < variableIndex; i++){
					if (strcmp(variableTable.var[i], yylval.string) == 0){
						yylval.string = variableTable.word[i];
					}
				}
				return STRING;
				}

<env_condition>[}]		{BEGIN(INITIAL);}

[\"]		{BEGIN(string_condition);}
"${"		{BEGIN(env_condition);}
[ ]{ANYCHAR}*{WILD}+{ANYCHAR}*				{yylval.string = strdup(yytext) + 1; return WILDCARD;}
~{ANYCHAR}*	{
			char *temp = malloc(strlen(variableTable.word[1]));
			strcpy(temp, variableTable.word[1]);
			strcat(temp, strdup(yytext) + 1);

			yylval.string = strdup(temp);

			free(temp);
			return STRING;
		}
testing		{return TESTING;}
"\n"		{return END;}
"<"		{yylval.string = strdup(yytext); printf("yytext: %s\n", yylval.string); return IN;}
">"		{return OUT;}
"|"		{return TO;}

{ANYCHAR}+		{if(ifAlias(yytext)) {
				printf("yytext: %s\n", yytext);
				char *yycopy = strdup( expandAlias(yytext));
				for (int i = strlen(expandAlias(yytext)) - 1 ; i >= 0; --i)
					unput(yycopy[i]);
				free( yycopy );
			}
			else {
				printf("yytext (command): %s\n", yytext);
				yylval.string = strdup(yytext);
				return STRING;

			}
		}

[ ]{ANYCHAR}+	{
			yylval.string = strdup(yytext) + 1;
			return STRING;
		}
[ ]		{ };

%%
