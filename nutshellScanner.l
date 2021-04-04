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
META		[\<\>\|\"\\\&]

%x string_condition
%%

<string_condition>{ANYCHAR}+	{yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]		{BEGIN(INITIAL);}

[ ]		{ }
[\"]		{BEGIN(string_condition);}
bye		{return BYE;}
testing		{return TESTING;}
printenv	{return PRINTENV;}
setenv		{return SETENV;}
unsetenv	{return UNSETENV;}
cd		{return CD;}
alias		{return ALIAS;}
unalias		{return UNALIAS;}
"\n"		{return END;}

{CHAR}+		{
		 printf("yytext: %s\n", yytext);
		 yylval.string = strdup(yytext);
		 return STRING;
		}

%%
