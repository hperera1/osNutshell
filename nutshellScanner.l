%{
#include "nutshellParser.tab.h"
#include <string.h>
#include <stdbool.h>
#include "global.h"
%}
%array
%option noyywrap

CHAR		[.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR		[)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*

%x string_condition
%%

<string_condition>{ANYCHAR}+	{yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]		{BEGIN(INITIAL);}

[ ]		{ }
bye		{return BYE;}
testing		{return TESTING;}
printenv	{return PRINTENV;}
"\n"		{return END;}
[\"]		{BEGIN(string_condition);}
{CHAR}+		{
		 printf("yytext: %s\n", yytext);
		 yylval.string = strdup(yytext);
		 return STRING;
		}

%%
