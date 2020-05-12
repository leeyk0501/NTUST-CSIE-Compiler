%{
/* Compiler Project1 - Lexical Definition
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LIST strcat(buf, yytext)
#define token(t) {LIST; printf("<'%s'>\n",t);}
#define tokenInteger(t,i) {LIST; printf("< %s: %s >\n",t,i);}
#define tokenReal(t,f) {LIST; printf("< %s: %s >\n",t,f);}
#define tokenString(t,s) {LIST; printf("< %s: %s >\n",t,s);}
#define tokenKeyword(k) {LIST; printf("<%s>\n",k);}

#define MAX_LINE_LENG 256

char buf[MAX_LINE_LENG];
int linecount = 0;

typedef struct Symbol {
    int index;
    char name[MAX_LINE_LENG];
    struct Symbol *next;
}Symbol;

Symbol *symbolTable = NULL;

/* Output the buf with the line number, then clear buf. */
void PRINT() {
    printf("%d: %s\n", ++linecount, buf);
    buf[0]='\0';
}

/* Creates a symbol table. */
int create() {
    symbolTable = (Symbol*)malloc(sizeof(Symbol));
    symbolTable->index = 0;
    symbolTable->name[0] = '\0';
    symbolTable->next = NULL;
}

/* Returns index of the entry for string s, or -1 if s is not found. */
int lookup(char *s) {
    Symbol *currentSymbol = symbolTable;
    while(currentSymbol->next) {
        if(strcmp(currentSymbol->next->name,s)==0) {
            return currentSymbol->next->index;
        }
        currentSymbol = currentSymbol->next;
    }
    return -1;
}


/* Inserts s into a new entry of the symbol table and returns index of the entry. */
int insert(char *s) {
    if (symbolTable==NULL) {
        create();
    }

    Symbol *currentSymbol = symbolTable;
    while(currentSymbol->next) {
        if(strcmp(currentSymbol->next->name,s)==0) {
            return currentSymbol->next->index;
        }
        currentSymbol = currentSymbol->next;
    }

    Symbol *newSymbol = (Symbol*)malloc(sizeof(Symbol));
    newSymbol->index = currentSymbol->index + 1;
    strcpy(newSymbol->name, s);
    newSymbol->next = NULL;
    currentSymbol->next = newSymbol;
    return newSymbol->index;
}

/* Dumps all entries of the symbol table. returns index of the entry. */
int dump() {
    if (symbolTable==NULL) {
        create();
    }
    printf("Symbol Table:\n");
    Symbol *currentSymbol = symbolTable->next;
    while(currentSymbol) {
        printf("%s\n", currentSymbol->name);
        currentSymbol = currentSymbol->next;
    }
    return 0;
}


%}
/* Regular definition */
digs        [0-9]+
integer     -?{digs}
plain_real  {digs}"."{digs}
expreal     {digs}"."{digs}[Ee][+-]?{digs}
real        -?{plain_real}|{expreal}
delimiters  [\,\:\.\;\(\)\[\]\{\}]
operators   [\+\-\*\/\%\=]
logic       "&&"|"||"|"!"|"<"|"<="|">="|">"|"=="|"!="
newline     \n
string      \"[^"]*\"
id          [a-zA-Z][0-9a-zA-Z]*
space       [\t ]*

%x COMMENT

%%

<<EOF>> { LIST; PRINT(); return(0); }

"/*"    { LIST; BEGIN(COMMENT); }
\/\/.*  { LIST; }
<COMMENT>"*/"       { LIST; BEGIN(INITIAL); }
<COMMENT>{newline}  { PRINT(); }
<COMMENT>.          { LIST; }

boolean     { tokenKeyword("BOOLEAN"); }
break       { tokenKeyword("BREAK"); }
char        { tokenKeyword("CHAR"); }
case        { tokenKeyword("CASE"); }
class       { tokenKeyword("CLASS"); }
continue    { tokenKeyword("CONTINUE"); }
def         { tokenKeyword("DEF"); }
do          { tokenKeyword("DO"); }
else        { tokenKeyword("ELSE"); }
exit        { tokenKeyword("EXIT"); }
false       { tokenKeyword("FALSE"); }
float       { tokenKeyword("FLOAT"); }
for         { tokenKeyword("FOR"); }
if          { tokenKeyword("IF"); }
int         { tokenKeyword("INT"); }
null        { tokenKeyword("NULL"); }
object      { tokenKeyword("OBJECT"); }
print       { tokenKeyword("PRINT"); }
println     { tokenKeyword("PRINTLN"); }
repeat      { tokenKeyword("REPEAT"); }
return      { tokenKeyword("RETURN"); }
string      { tokenKeyword("STRING"); }
to          { tokenKeyword("TO"); }
true        { tokenKeyword("TRUE"); }
type        { tokenKeyword("TYPE"); }
val         { tokenKeyword("VAL"); }
var         { tokenKeyword("VAR"); }
while       { tokenKeyword("WHILE"); }

{space}         { LIST; }
{delimiters}    { token(yytext); }
{operators}     { token(yytext); }
{logic}         { token(yytext); }
{integer}       { tokenInteger("Int", yytext); }
{real}          { tokenReal("Real", yytext); }
{string}        {
                    char c = input();
                    unput(c);
                    if(c == '\"') {
                        yymore();
                    } else {
                        yyless(yyleng);
                        /* Process string */
                        char str[MAX_LINE_LENG];
                        int i=0,j=1;
                        while(j<yyleng) {
                            str[i++] = yytext[j++];
                            if(yytext[j] == '\"') {
                                j++;
                            }
                        }
                        str[i]='\0';
                        tokenString("String", str);
                    }
                }
{id}            { 
                    tokenString("id", yytext); 
                    insert(yytext);
                }
{newline}       { PRINT(); }
.               {
                    PRINT();
                    printf("bad character:'%s'\n",yytext);
                    exit(-1);
                }

%%

int main()
{
    yylex();
    printf("\n");
    dump();
    return(0);
}
