%{
#include "nutshellParser.tab.h"
#include <sys/types.h>
#include <pwd.h>
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
WILD		[*?][*?]*
CHARS		[:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
META		[\<\>\|\"\\\&]

%x string_condition
%x env_condition
%x senv_condition
%%

<string_condition>{CHARS}*"${"{CHARS}+"}"{CHARS}*	{yylval.string = strdup( yytext ); return ENVSTRING;}

<string_condition>{CHARS}+				{yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]					{BEGIN(INITIAL);}

<env_condition>{CHARS}+					{
							int check = 1;
							yylval.string = strdup(yytext);
							for (int i = 0; i < variableIndex; i++){
								if (strcmp(variableTable.var[i], yylval.string) == 0){
									input(); check = 0;
									char *yycopy = strdup(variableTable.word[i]);

									for (int i = strlen(yycopy) - 1 ; i >= 0; --i){
										unput(yycopy[i]);
									}
									free(yycopy);
									BEGIN(INITIAL);
								}
							}
							if(check == 1){return STRING;}
							}

<env_condition>[}]					{BEGIN(INITIAL);}

<senv_condition>{CHARS}+				{
							int check = 1;
							yylval.string = strdup(yytext);
							for(int i = 0; i < variableIndex; i++){
								if(strcmp(variableTable.var[i], yylval.string) == 0){
									input(); check = 0;
									char *yycopy = strdup(variableTable.word[i]);
									for (int i = strlen(yycopy) - 1; i >= 0; --i){
										unput(yycopy[i]);
									}
									unput(' ');
									free(yycopy); 
									BEGIN(INITIAL);
								}
							}
							if(check == 1){return STRING;}
							}

<senv_condition>[}]					{BEGIN(INITIAL);}

[\"]							{BEGIN(string_condition);}
"${"							{BEGIN(env_condition);}
" ${"							{BEGIN(senv_condition);}
[ ]{ANYCHAR}*{WILD}+{ANYCHAR}*				{yylval.string = strdup(yytext) + 1; return WILDCARD;}
~{CHARS}*						{
								char temp[4096];
								char entire_string[4096];
								char new_string[4096];
								char rest_string[4096];
								strcpy(entire_string, strdup(yytext) + 1);

								//printf("%s\n", entire_string);
								
								if(strcmp(entire_string, "") == 0){
									//printf("Easy Case\n");
									strcpy(new_string, variableTable.word[1]);
									strcat(new_string, strdup(yytext) + 1);

									yylval.string = strdup(new_string);
									//printf("%s\n", yylval.string);
									return STRING;
								}
								else{
									int stringIter = 0;
									int tempIter = 0;
									struct passwd* pwd;
									//printf("hard case\n");

									while((entire_string[stringIter] != '/') && (entire_string[stringIter] != '0')){
										temp[tempIter++] = entire_string[stringIter++];
									}
									
									temp[tempIter] = '\0';
									//printf("temp: %s\n", temp);

									pwd = getpwnam(temp);
									if(pwd == NULL){
										tempIter = 0;
										strcpy(new_string, variableTable.word[1]);
										for (; stringIter < strlen(entire_string) ; tempIter++, stringIter++){
											rest_string[tempIter] = entire_string[stringIter];
										}
										rest_string[tempIter] = '\0';
										strcat(new_string, rest_string);
										
										//printf("Final: %s\n", new_string);
										yylval.string = strdup(new_string);
										return STRING;
									}
									else{
										tempIter = 0;
										strcpy(new_string, pwd->pw_dir);
										for (; stringIter < strlen(entire_string) ; tempIter++, stringIter++){
											rest_string[tempIter] = entire_string[stringIter];
										}
										rest_string[tempIter] = '\0';
										//printf("rest: %s\n", rest_string);
										
										strcat(new_string, rest_string);									

										//printf("Final: %s\n", new_string);
										
										yylval.string = strdup(new_string);
									
										return STRING;
									}
								}
							}
" ~"{ANYCHAR}*						{
								char temp[4096];
								char entire_string[4096];
								char new_string[4096];
								char rest_string[4096];
								strcpy(entire_string, strdup(yytext) + 2);

								//printf("entire string: %s\n", entire_string);

								if(strcmp(entire_string, "") == 0){
									strcpy(new_string, variableTable.word[1]);
									strcat(new_string, strdup(yytext) + 2);

									yylval.string = strdup(new_string);
									//printf("%s\n", yylval.string);
									return STRING;
								}
								else{
									int stringIter = 0;
									int tempIter = 0;
									struct passwd* pwd;
									
									while((entire_string[stringIter] != '/') && (entire_string[stringIter] != '0')){
										temp[tempIter++] = entire_string[stringIter++];
									}

									temp[tempIter] = '\0';
									//printf("temp: %s\n", temp);
									
									pwd = getpwnam(temp);
									if(pwd == NULL){
										tempIter = 0;
										strcpy(new_string, variableTable.word[1]);
										for(; stringIter < strlen(entire_string); tempIter++, stringIter++){
											rest_string[tempIter] = entire_string[stringIter];
										}
										//printf("rest: %s\n", rest_string);
										rest_string[tempIter] = '\0';
										strcat(new_string, rest_string);
							
										//printf("Final: %s\n", new_string);
										yylval.string = strdup(new_string); 
										return STRING;
									}
									else{
										tempIter = 0;
										strcpy(new_string, pwd->pw_dir);
										for(; stringIter < strlen(entire_string); tempIter++, stringIter++){
											rest_string[tempIter] = entire_string[stringIter];
										}
										rest_string[tempIter] = '\0';
										//printf("rest: %s\n", rest_string);
										strcat(new_string, rest_string);
										//printf("Final: %s\n", new_string);
										yylval.string = strdup(new_string);
										return STRING;
									}
								}
							}
testing							{return TESTING;}
"\n"							{return END;}
"<"							{yylval.string = strdup(yytext); return IN;}
">"							{return OUT;}
">>"							{return APPEND;}
"|"							{return TO;}

{ANYCHAR}+						{
							if(ifAlias(yytext)) {
								char *yycopy = strdup( expandAlias(yytext));
								for (int i = strlen(expandAlias(yytext)) - 1 ; i >= 0; --i)
									unput(yycopy[i]);
								free( yycopy );
							}
							else {
								yylval.string = strdup(yytext);
								return STRING;

							}
							}
[ ]{ANYCHAR}+						{yylval.string = strdup(yytext) + 1; return STRING;}
[ ]							{ };

%%
