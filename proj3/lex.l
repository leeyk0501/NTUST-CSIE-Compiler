%{
/* Compiler Project3 - Code Generation
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"
#include "y.tab.h"

#define LIST strcat(buf, yytext)
#define token(t) {LIST; return(t);}
#define MAX_LINE_LENG 256
int lineNum = 0;
char buf[MAX_LINE_LENG];

/* Output the buf with the line number, then clear buf. */
void nPRINT() {
    ++lineNum;
    // printf("%d: %s\n", lineNum, buf);
    buf[0]='\0';
}

%}

/* Regular definition */
digs        [0-9]+
integer     {digs}
plain_real  {digs}"."{digs}
expreal     {digs}"."{digs}[Ee][+-]?{digs}
real        {plain_real}|{expreal}
newline     \n
string      \"[^"^\n]*\"
char        \'[0-9a-zA-Z]\'
id          [a-zA-Z][0-9a-zA-Z]*
space       [\t ]*

/* Comment mode */
%x COMMENT

%%

<<EOF>> { LIST; nPRINT(); return(0); }

"/*"    { LIST; BEGIN(COMMENT); }
\/\/.*  { LIST; }
<COMMENT>"*/"       { LIST; BEGIN(INITIAL); }
<COMMENT>{newline}  { nPRINT(); }
<COMMENT>.          { LIST; }

","     token(COM);
":"     token(COL);
"."     token(PER);
";"     token(SEM);
"("     token(PAR_L);
")"     token(PAR_R);
"["     token(SBRA_L);
"]"     token(SBRA_R);
"{"     token(BRA_L);
"}"     token(BRA_R);

"+"     token(ADD);
"-"     token(SUB);
"*"     token(MUL);
"/"     token(DIV);
"%"     token(REM);

"<"     token(LE);
"<""="  token(LEEQ);
">"     token(GR);
">""="  token(GREQ);
"=""="  token(EQ);
"!""="  token(NEQ);

"&""&"  token(AND);
"|""|"  token(OR);
"!"     token(NOT);

"="     token(ASS);

"<""-"  token(ARR);

boolean     { token(BOOLEAN); }
break       { token(BREAK); }
char        { token(CHAR); }
case        { token(CASE); }
class       { token(CLASS); }
continue    { token(CONTINUE); }
def         { token(DEF); }
do          { token(DO); }
else        { token(ELSE); }
exit        { token(EXIT); }
false       { token(FALSE); }
float       { token(FLOAT); }
for         { token(FOR); }
if          { token(IF); }
int         { token(INT); }
null        { token(nULL); }
object      { token(OBJECT); }
print       { token(PRINT); }
println     { token(PRINTLN); }
repeat      { token(REPEAT); }
return      { token(RETURN); }
string      { token(STRING); }
to          { token(TO); }
true        { token(TRUE); }
type        { token(TYPE); }
val         { token(VAL); }
var         { token(VAR); }
while       { token(WHILE); }

{space}         { LIST; }
{integer}       { 
                    sscanf(yytext, "%d", &yylval.intVal);
                    token(INT_VAL);
                }
{plain_real}    {
                    sscanf(yytext, "%f", &yylval.floatVal);
                    token(FLOAT_VAL);
                }
{expreal}       {
                    sscanf(yytext, "%f", &yylval.floatVal);
                    token(FLOAT_VAL);
                }
{string}        {
                    char c = yyinput();
                    unput(c);
                    if(c == '\"') {
                        yymore();
                    } else {
                        yyless(yyleng);
                        // Process string
                        char str[MAX_LINE_LENG];
                        int i,j=0;
                        for(i=1;i<yyleng-1;++i) {
                            if(yytext[i] == yytext[i+1] && yytext[i] == '"') {
                                i++;
                            }
                            str[j] = yytext[i];
                            ++j;
                        }
                        str[j]='\0';

                        yylval.stringVal = strdup(str);
                        token(STRING_VAL);
                    }
                }
{char}          {
                    sscanf(yytext, "%c", &yylval.charVal);
                    token(CHAR_VAL);
                }
{id}            { 
                    yylval.stringVal = strdup(yytext);
                    token(ID);
                }
{newline}       { nPRINT(); }
.               {
                    nPRINT();
                    printf("bad character:'%s'\n",yytext);
                    exit(-1);
                }

%%
