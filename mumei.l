%{
#include <iostream>
#include <cstdlib>
using namespace std;
#define YY_DECL extern "C" int yylex()
#include "mumei.tab.h"
int linenum=0;
%}
%%
[ \t\n]       ;
FUNCTION       { return FUNCTION;}
END            { return END;}
[0-9]+         { yylval.ival = atoi(yytext); return INT;}
[a-zA-Z][a-zA-Z0-9]* {yylval.sval=strdup(yytext);return VARNAME;}
\+             { return PLUS;}
\-             { return MINUS;}
\(             { return LPARENS; }
\)             { return RPARENS; }
\*             { return MUL;}
\/             { return DIV;}
\=             { return EQ;}
\,             { return COMMA;}
%%