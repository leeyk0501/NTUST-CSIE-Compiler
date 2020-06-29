%{
/* Compiler Project3 - Code Generation
 */
#include <fstream>
#include <stack>
#include "lex.yy.c"

#define Trace(t) cout << t << endl

using namespace std;

void yyerror(string t);

// Symbol Table
SymbolTable *scope;
Symbol *symbol;

// Parser
bool flag;
vector<int> parameter;
bool haveMainFlag = false;
bool elseBranch = false;

// File
string fileName = "";
string rawName = "";
ofstream fout;
int tabs = 0;

// Branch
int branchIndex;
stack<int> branch;

// IDK
bool hasValue = false;

// union data
bool bool_value = false;
int int_value = 0;
float float_value = 0.0;
char char_value = ' ';
string string_value = "";

void clearUnionData() {
    bool_value = false;
    int_value = 0;
    float_value = 0.0;
    char_value = ' ';
    string_value = "";
}

void fileWrite(ofstream &fs, string str) {
    for (int i = 0; i < tabs; ++i) {
        str = "    " + str;
    }
    fs << str << endl;
}

// Deal with Backslash
string formatString(string str) {
    string result = "";
    for (int i=0; i < str.length(); ++i) {
        switch(str[i]) {
            case '\t':
                result += "\\t";
                break;
            case '\n':
                result += "\\n";
                break;
            case '\'':
                result += "\\\'";
                break;
            case '\"':
                result += "\\\"";
                break;
            case '\\':
                result += "\\\\";
                break;
            default:
                result += string(1, str[i]);
                break;
        }
    }
    return result;
}

%}

/* tokens */
%token BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT
%token nULL OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE READ
%token COM COL PER SEM
%token PAR_L PAR_R SBRA_L SBRA_R BRA_L BRA_R
%token ADD SUB MUL DIV REM
%token LE LEEQ GR GREQ EQ NEQ
%token AND OR NOT ASS ARR

%union {
    bool boolVal;
    int intVal;
    float floatVal;
    char charVal;
    char* stringVal;
}

%token <boolVal> BOOL_VAL
%token <intVal> INT_VAL
%token <floatVal> FLOAT_VAL
%token <charVal> CHAR_VAL
%token <stringVal> STRING_VAL
%token <stringVal> ID

%type <boolVal> bool_val
%type <intVal> assignment_type type constant_expression expression function_invocation

//%type <intVal> 

/*
 * (7) ||
 * (6) &&
 * (5) !
 * (4) < <= > >= == !=
 * (3) + -
 * (2) * / %
 * (1) - (unary)
*/
%left OR
%left AND
%left NOT
%left LE LEEQ GR GREQ EQ NEQ
%left ADD SUB
%left MUL DIV REM
%nonassoc UMINUS

%%

// Program
program: object_declaration
       ;

// Object
object_declaration: OBJECT ID   {
                                    scope = new SymbolTable($2, NULL);

                                    // Java bytecode
                                    fileWrite(fout, "class " + string($2));
                                    fileWrite(fout, "{");
                                    tabs++;
                                }
                        BRA_L object_block_declarations BRA_R {
                                                                    // Check if method have "main"
                                                                    if(!haveMainFlag) {
                                                                        yyerror("\'main\' method is not found.");
                                                                    }
                                                                    
                                                                    SymbolTable *temp = scope;
                                                                    scope = scope->parentTable;
                                                                    delete temp;

                                                                    // Java bytecode
                                                                    tabs--;
                                                                    fileWrite(fout, "}");
                                                                    fout.close();
                                                              }
                  ;

object_block_declarations: /* empty */
                         | object_block_declaration object_block_declarations
                         ;
                        
object_block_declaration: variable_constant_declaration
                        | method_declaration
                        ;

// Constant and Variable Declarations
variable_constant_declaration: constant
                             | variable
                             ;

// Constant
constant: VAL ID assignment_type ASS constant_expression    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, 5 + $3);
                                                                    if ($3 % 5 != $5 % 5) {
                                                                        yyerror("These types are not same.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    switch (symbol->type) {
                                                                        case CONST_BOOL:
                                                                            if (bool_value) {
                                                                                symbol->byteCode = "iconst_1";
                                                                            } else {
                                                                                symbol->byteCode = "iconst_0";
                                                                            }
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_INT:
                                                                            symbol->byteCode = "sipush " + to_string(int_value);
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_FLOAT:
                                                                            symbol->byteCode = "sipush " + to_string(float_value);
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_CHAR:
                                                                            symbol->byteCode = "ldc \"" + string(1, char_value) + "\"";
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_STRING:
                                                                            symbol->byteCode = "ldc \"" + string_value + "\"";
                                                                            clearUnionData();
                                                                            break;
                                                                        default:
                                                                            yyerror("error");
                                                                            break;    
                                                                    }
                                                                }
                                                            }
        | VAL ID ASS constant_expression                    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, 5 + $4);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    switch (symbol->type) {
                                                                        case CONST_BOOL:
                                                                            if (bool_value) {
                                                                                symbol->byteCode = "iconst_1";
                                                                            } else {
                                                                                symbol->byteCode = "iconst_0";
                                                                            }
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_INT:
                                                                            symbol->byteCode = "sipush " + to_string(int_value);
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_FLOAT:
                                                                            symbol->byteCode = "sipush " + to_string(float_value);
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_CHAR:
                                                                            symbol->byteCode = "ldc \"" + string(1, char_value) + "\"";
                                                                            clearUnionData();
                                                                            break;
                                                                        case CONST_STRING:
                                                                            symbol->byteCode = "ldc \"" + formatString(string_value) + "\"";
                                                                            clearUnionData();
                                                                            break;
                                                                        default:
                                                                            yyerror("error");
                                                                            break;
                                                                    }
                                                                }
                                                            }
        ;

assignment_type: COL type   {
                                $$ = $2;
                                hasValue = true;
                            }
               ;

type: BOOLEAN   { $$ = VAR_BOOL; }
    | INT       { $$ = VAR_INT; }
    | FLOAT     { $$ = VAR_FLOAT; }
    | CHAR      { $$ = VAR_CHAR; }
    | STRING    { $$ = VAR_STRING; }
    ;

constant_expression: bool_val   { 
                                    $$ = VAR_BOOL;
                                    bool_value = $1;
                                }
                   | INT_VAL    {
                                    $$ = VAR_INT;
                                    int_value = $1;
                                }
                   | FLOAT_VAL  {
                                    $$ = VAR_FLOAT;
                                    float_value = $1;
                                }
                   | CHAR_VAL   {
                                    $$ = VAR_CHAR;
                                    char_value = $1;
                                }
                   | STRING_VAL {
                                    $$ = VAR_STRING;
                                    string_value = string($1);
                                }
                   ;

bool_val: TRUE  { $$ = true; }
        | FALSE { $$ = false; }
        ;

// Variable
variable: VAR ID                                            {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, NON);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    if (scope->parentTable != NULL) {
                                                                        symbol->byteCode = "iload " + to_string(scope->localValueIndex);
                                                                        symbol->storeCode = "istore " + to_string(scope->localValueIndex);
                                                                        scope->localValueIndex++;

                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "iconst_1");
                                                                                    } else {
                                                                                        fileWrite(fout, "iconst_0");
                                                                                    }
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "sipush " + to_string(int_value));
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } 
                                                                    } else {
                                                                        symbol->byteCode = "getstatic int " + scope->name + "." + symbol->name;
                                                                        symbol->storeCode = "putstatic int " + scope->name + "." + symbol->name;
                                                                        
                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 1");
                                                                                    } else {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 0");
                                                                                    }
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "field static int " + symbol->name + " = " + to_string(int_value));
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } else {
                                                                            fileWrite(fout, "field static int " + symbol->name);
                                                                        }
                                                                    }
                                                                } else {
                                                                    yyerror("error");
                                                                }
                                                            }
        | VAR ID ASS constant_expression                    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $4);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    if (scope->parentTable != NULL) {
                                                                        symbol->byteCode = "iload " + to_string(scope->localValueIndex);
                                                                        symbol->storeCode = "istore " + to_string(scope->localValueIndex);
                                                                        scope->localValueIndex++;

                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "iconst_1");
                                                                                    } else {
                                                                                        fileWrite(fout, "iconst_0");
                                                                                    }
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "sipush " + to_string(int_value));
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } 
                                                                    } else {
                                                                        symbol->byteCode = "getstatic int " + scope->name + "." + symbol->name;
                                                                        symbol->storeCode = "putstatic int " + scope->name + "." + symbol->name;
                                                                        
                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 1");
                                                                                    } else {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 0");
                                                                                    }
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "field static int " + symbol->name + " = " + to_string(int_value));
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } else {
                                                                            fileWrite(fout, "field static int " + symbol->name);
                                                                        }
                                                                    }
                                                                } else {
                                                                    yyerror("error");
                                                                }
                                                            }
        | VAR ID assignment_type                            {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $3);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    if (scope->parentTable != NULL) {
                                                                        symbol->byteCode = "iload " + to_string(scope->localValueIndex);
                                                                        symbol->storeCode = "istore " + to_string(scope->localValueIndex);
                                                                        scope->localValueIndex++;

                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "iconst_1");
                                                                                    } else {
                                                                                        fileWrite(fout, "iconst_0");
                                                                                    }
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "sipush " + to_string(int_value));
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } 
                                                                    } else {
                                                                        symbol->byteCode = "getstatic int " + scope->name + "." + symbol->name;
                                                                        symbol->storeCode = "putstatic int " + scope->name + "." + symbol->name;
                                                                        
                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 1");
                                                                                    } else {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 0");
                                                                                    }
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "field static int " + symbol->name + " = " + to_string(int_value));
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } else {
                                                                            fileWrite(fout, "field static int " + symbol->name);
                                                                        }
                                                                    }
                                                                } else {
                                                                    yyerror("error");
                                                                }
                                                            }
        | VAR ID assignment_type ASS constant_expression    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $3);
                                                                    if ($3 % 5 != $5 % 5) {
                                                                        yyerror("These types are not same.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }

                                                                // Java bytecode
                                                                symbol = scope->localLookup($2);
                                                                if (symbol != NULL) {
                                                                    if (scope->parentTable != NULL) {
                                                                        symbol->byteCode = "iload " + to_string(scope->localValueIndex);
                                                                        symbol->storeCode = "istore " + to_string(scope->localValueIndex);
                                                                        scope->localValueIndex++;

                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "iconst_1");
                                                                                    } else {
                                                                                        fileWrite(fout, "iconst_0");
                                                                                    }
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "sipush " + to_string(int_value));
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } 
                                                                    } else {
                                                                        symbol->byteCode = "getstatic int " + scope->name + "." + symbol->name;
                                                                        symbol->storeCode = "putstatic int " + scope->name + "." + symbol->name;
                                                                        
                                                                        if (hasValue) {
                                                                            hasValue = false;
                                                                            switch (symbol->type) {
                                                                                case VAR_BOOL:
                                                                                    if (bool_value) {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 1");
                                                                                    } else {
                                                                                        fileWrite(fout, "field static int " + symbol->name + " = 0");
                                                                                    }
                                                                                    clearUnionData();
                                                                                    break;
                                                                                case VAR_INT:
                                                                                    fileWrite(fout, "field static int " + symbol->name + " = " + to_string(int_value));
                                                                                    clearUnionData();
                                                                                    break;
                                                                                default:
                                                                                    break;
                                                                            }
                                                                        } else {
                                                                            fileWrite(fout, "field static int " + symbol->name);
                                                                        }
                                                                    }
                                                                } else {
                                                                    yyerror("error");
                                                                }
                                                            }
        ;

// Method
method_declaration: DEF ID {
                                if (string($2) == "main") {
                                    haveMainFlag = true;
                                }
                                if (scope->localLookup($2) == NULL) {
                                    flag = true;
                                    scope->insert($2, FUNC_NON);
                                    symbol = scope->localLookup($2);
                                    SymbolTable *childTable = new SymbolTable($2, scope);
                                    scope = childTable;
                                } else {
                                    flag = false;
                                    SymbolTable *childTable = new SymbolTable(string($2) + "_temp", scope);
                                    scope = childTable;
                                    yyerror("\'" + string($2) + "\' is already declared.");
                                }
                           } PAR_L optional_formal_arguments PAR_R optional_assignment_type {
                                                                                                // Java bytecode
                                                                                                string functionType = "void ";
                                                                                                switch (symbol->type) {
                                                                                                    case FUNC_NON:
                                                                                                        break;
                                                                                                    case FUNC_INT:
                                                                                                    case FUNC_BOOL:
                                                                                                        functionType = "int ";
                                                                                                        break;
                                                                                                    default:
                                                                                                        break;
                                                                                                }

                                                                                                string arguName = symbol->name;
                                                                                                arguName += "(";
                                                                                                for (int i = 0; i < symbol->argumentType.size(); ++i) {
                                                                                                    if (i) {
                                                                                                        arguName += ", ";
                                                                                                    }
                                                                                                    switch(symbol->argumentType[i]) {
                                                                                                        case VAR_INT:
                                                                                                        case VAR_BOOL:
                                                                                                            arguName += "int";
                                                                                                            break;
                                                                                                        default:
                                                                                                            arguName += "int";
                                                                                                            break;
                                                                                                    }
                                                                                                }
                                                                                                arguName += ")";

                                                                                                symbol->byteCode = "invokestatic " + functionType + scope->parentTable->name + "." + arguName;

                                                                                                if (symbol->name == "main") {
                                                                                                    fileWrite(fout, "method public static void main(java.lang.String[])");
                                                                                                } else {
                                                                                                    fileWrite(fout, "method public static " + functionType + arguName);
                                                                                                }
                                                                                                fileWrite(fout, "max_stack 15");
                                                                                                fileWrite(fout, "max_locals 15");
                                                                                                fileWrite(fout, "{");
                                                                                                tabs++;
                                                                                            } block {
                                                                                                        // Java bytecode
                                                                                                        if (!scope->hasReturn) {
                                                                                                            fileWrite(fout, "return");
                                                                                                        }
                                                                                                        tabs--;
                                                                                                        fileWrite(fout, "}");

                                                                                                        SymbolTable *trashTable = scope;
                                                                                                        scope = scope->parentTable;
                                                                                                        delete trashTable;
                                                                                                    }
                  ;

optional_assignment_type: /* empty */       {
                                                scope->returnType = FUNC_NON;
                                            }
                        | assignment_type   {
                                                if (flag) {
                                                    symbol->type = $1 + 15;
                                                }
                                                scope->returnType = $1 + 15;
                                            }
                        ;

optional_formal_arguments: /* empty */
                         | formal_arguments
                         ;

formal_arguments: formal_argument
                | formal_argument COM formal_arguments
                ;

formal_argument: ID assignment_type {
                                        if (flag) {
                                            symbol->argumentType.push_back($2);
                                        }
                                        scope->insert($1, $2);
                                        
                                        // Java bytecode
                                        Symbol *argumentSymbol = scope->localLookup($1);
                                        if (argumentSymbol != NULL) {
                                            argumentSymbol->byteCode = "iload " + to_string(scope->localValueIndex);
                                            argumentSymbol->storeCode = "istore " + to_string(scope->localValueIndex);
                                            scope->localValueIndex++;
                                        }
                                    }
               ;

block: BRA_L block_constant_variable_statements BRA_R
     ;

block_constant_variable_statements: /* empty */
                                  | block_constant_variable_statement block_constant_variable_statements
                                  ;

block_constant_variable_statement: constant
                                 | variable
                                 | statement
                                 ;

statement: simple
         | conditional
         | while_loop
         | for_loop
         | procedure_invocation
         ;

simple: ID ASS expression                                   {
                                                                symbol = scope->globalLookup($1);
                                                                if (symbol != NULL) {
                                                                    if (symbol->type == 0) {
                                                                        symbol->type = $3;
                                                                        // Java bytecode
                                                                        fileWrite(fout, symbol->storeCode);
                                                                    } else if (symbol->type >= 1 && symbol->type <= 5) {
                                                                        if (symbol->type % 5 != $3) {
                                                                            yyerror("These types are not same.");
                                                                        }
                                                                        // Java bytecode
                                                                        fileWrite(fout, symbol->storeCode);
                                                                    } else {
                                                                        yyerror("\'" + string($1) + "\' is not variable.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($1) + "\' does not declared.");
                                                                }
                                                            }
      | PRINT   {
                    // Java bytecode
                    fileWrite(fout, "getstatic java.io.PrintStream java.lang.System.out");
                } PAR_L expression PAR_R                    {
                                                                if ($4 == VAR_INT || $4 == VAR_BOOL || $4 == CONST_INT || $4 == CONST_BOOL || $4 == FUNC_INT || $4 == FUNC_BOOL) {
                                                                    // Java bytecode
                                                                    fileWrite(fout, "invokevirtual void java.io.PrintStream.print(int)");
                                                                } else if ($4 == VAR_STRING || $4 == CONST_STRING || $4 == FUNC_STRING) {
                                                                    // Java bytecode
                                                                    fileWrite(fout, "invokevirtual void java.io.PrintStream.print(java.lang.String)");
                                                                } else {
                                                                    yyerror("The type can not print." + to_string($4));
                                                                }
                                                                
                                                            }
      | PRINTLN {
                    // Java bytecode
                    fileWrite(fout, "getstatic java.io.PrintStream java.lang.System.out");
                } PAR_L expression PAR_R                    {
                                                                if ($4 == VAR_INT || $4 == VAR_BOOL || $4 == CONST_INT || $4 == CONST_BOOL || $4 == FUNC_INT || $4 == FUNC_BOOL) {
                                                                    // Java bytecode
                                                                    fileWrite(fout, "invokevirtual void java.io.PrintStream.println(int)");
                                                                } else if ($4 == VAR_STRING || $4 == CONST_STRING || $4 == FUNC_STRING) {
                                                                    // Java bytecode
                                                                    fileWrite(fout, "invokevirtual void java.io.PrintStream.println(java.lang.String)");
                                                                } else {
                                                                    yyerror("The type can not print.");
                                                                }
                                                            }
      | RETURN                                              {
                                                                // Java bytecode
                                                                fileWrite(fout, "return");

                                                                SymbolTable *temp = scope;
                                                                while(temp->returnType == 0) {
                                                                    if (temp->parentTable == NULL) {
                                                                        break;
                                                                    }
                                                                    temp = temp->parentTable;
                                                                }

                                                                temp->hasReturn = true;
                                                                
                                                                if(temp->returnType != FUNC_NON) {
                                                                    if(temp->returnType >= FUNC_BOOL && temp->returnType <= FUNC_STRING) {
                                                                        yyerror(temp->name + " need return value.");
                                                                    } else {
                                                                        yyerror("Return in non-method scope is ilegal.");
                                                                    }
                                                                }
                                                            }
      | RETURN expression                                   {
                                                                // Java bytecode
                                                                fileWrite(fout, "ireturn");

                                                                SymbolTable *temp = scope;
                                                                while(temp->returnType == 0) {
                                                                    if (temp->parentTable == NULL) {
                                                                        break;
                                                                    }
                                                                    temp = temp->parentTable;
                                                                }

                                                                temp->hasReturn = true;
                                                                if(temp->returnType != FUNC_NON) {
                                                                    if(temp->returnType >= FUNC_BOOL && temp->returnType <= FUNC_STRING) {
                                                                        if (temp->returnType % 5 != $2) {
                                                                            yyerror("Function type and Return type are not same.");
                                                                        }
                                                                    } else {
                                                                        if(temp->returnType == FUNC_NON) {
                                                                            yyerror("Function doesn't need return value.");
                                                                        } else {
                                                                            yyerror("Return in non-method scope is ilegal.");
                                                                        }
                                                                    }
                                                                }
                                                            }
      ;



conditional: IF PAR_L boolean_expression PAR_R  {
                                                    elseBranch = false;
                                                    branch.push(branchIndex + 1);
                                                    branch.push(branchIndex);
                                                    branch.push(branchIndex + 1);
                                                    branch.push(branchIndex);
                                                    branchIndex += 2;

                                                    fileWrite(fout, "ifeq L" + to_string(branch.top()));
                                                    branch.pop();
                                                } block_or_simple optional_else {
                                                                                    if (elseBranch) {
                                                                                        fileWrite(fout, "L" + to_string(branch.top()) + ":");
                                                                                    }
                                                                                    branch.pop();
                                                                                }
           ;

optional_else: /* empty */  {
                                branch.pop();
                                fileWrite(fout, "L" + to_string(branch.top()) + ":");
                                branch.pop();
                            }
             | ELSE         {
                                elseBranch = true;

                                int gotoIndex = branch.top();
                                branch.pop();
                                int labelIndex = branch.top();
                                branch.pop();

                                fileWrite(fout, "goto L" + to_string(gotoIndex));
                                fileWrite(fout, "L" + to_string(labelIndex) + ":");
                            } block_or_simple 
             ;

block_or_simple:    {
                        SymbolTable *childTable = new SymbolTable("_temp", scope);
                        scope = childTable;
                    } block {
                                SymbolTable *trashTable = scope;
                                scope = scope->parentTable;
                                delete trashTable;
                            }
               | statement
               ;

while_loop: WHILE   {
                        branch.push(branchIndex + 1);
                        branch.push(branchIndex);
                        branch.push(branchIndex + 1);
                        branch.push(branchIndex);
                        branchIndex += 2;

                        fileWrite(fout, "L" + to_string(branch.top()) + ":");
                        branch.pop();

                    } PAR_L boolean_expression PAR_R    {
                                                            fileWrite(fout, "ifeq L" + to_string(branch.top()));
                                                            branch.pop();
                                                        } block_or_simple   {
                                                                                int gotoIndex = branch.top();
                                                                                branch.pop();
                                                                                int labelIndex = branch.top();
                                                                                branch.pop();

                                                                                fileWrite(fout, "goto L" + to_string(gotoIndex));
                                                                                fileWrite(fout, "L" + to_string(labelIndex) + ":");
                                                                            }
          ;

for_loop: FOR PAR_L ID  {
                            symbol = scope->globalLookup($3);
                            if (symbol == NULL) {
                                yyerror("\'" + string($3) + "\' does not declared.");
                            } else if (symbol->type % 5 != VAR_INT) {
                                yyerror("\'" + string($3) + "\' is not integer.");
                            }
                        } ARR INT_VAL TO INT_VAL    {
                                                        fileWrite(fout, "sipush " + to_string($6));
                                                        fileWrite(fout, symbol->storeCode);

                                                        branch.push(branchIndex + 1);
                                                        branch.push(branchIndex);
                                                        branch.push(branchIndex + 1);
                                                        branch.push(branchIndex);
                                                        branchIndex += 2;

                                                        fileWrite(fout, "L" + to_string(branch.top()) + ":");
                                                        branch.pop();
                                                    } PAR_R block_or_simple {
                                                                                fileWrite(fout, "sipush " + to_string($8));
                                                                                symbol = scope->globalLookup($3);
                                                                                if (symbol != NULL) {
                                                                                    fileWrite(fout, symbol->byteCode);
                                                                                }

                                                                                fileWrite(fout, "isub");
                                                                                fileWrite(fout, "ifeq L" + to_string(branch.top()));
                                                                                branch.pop();

                                                                                fileWrite(fout, "iconst_1");
                                                                                if (symbol != NULL) {
                                                                                    fileWrite(fout, symbol->byteCode);
                                                                                }

                                                                                fileWrite(fout, "iadd");
                                                                                if (symbol != NULL) {
                                                                                    fileWrite(fout, symbol->storeCode);
                                                                                }

                                                                                fileWrite(fout, "goto L" + to_string(branch.top()));
                                                                                branch.pop();

                                                                                fileWrite(fout, "L" + to_string(branch.top()) + ":");
                                                                                branch.pop();
                                                                            }
        ;

procedure_invocation: ID    {
                                symbol = scope->globalLookup($1);
                                if (symbol == NULL) {
                                    yyerror("\'" + string($1) + "\' does not declared.");
                                } else {
                                    // Java bytecode
                                    fileWrite(fout, symbol->byteCode);

                                    if (symbol->type != 21) {
                                    yyerror("\'" + string($1) + "\' is not non-return method.");
                                    }
                                    if (symbol->argumentType.size() != 0) {
                                        yyerror("\'" + string($1) + "\' need argument.");
                                    }
                                }
                                
                            }
                    | ID PAR_L comma_separated_expressions PAR_R {
                                                                    symbol = scope->globalLookup($1);
                                                                    if (symbol == NULL) {
                                                                        yyerror("\'" + string($1) + "\' does not declared.");
                                                                    } else {
                                                                        // Java bytecode
                                                                        fileWrite(fout, symbol->byteCode);

                                                                        if (symbol->type != 21) {
                                                                            yyerror("\'" + string($1) + "\' is not non-return method.");
                                                                        }
                                                                        if (symbol->argumentType.size() == parameter.size()) {
                                                                            bool typeFlag = true;
                                                                            for (int i=0;i<symbol->argumentType.size();++i) {
                                                                                if (symbol->argumentType.at(i) % 5 != parameter.at(i)) {
                                                                                    typeFlag = false;
                                                                                }
                                                                            }
                                                                            if (!typeFlag) {
                                                                                yyerror("\'" + string($1) + "\' parameter type is not match.");
                                                                            }
                                                                        } else {
                                                                            yyerror("\'" + string($1) + "\' parameter size is not match.");
                                                                        }
                                                                    }
                                                                    
                                                                }
                    ;

integer_expression: expression  {
                                    if ($1 != 2) {
                                        yyerror("The type is not integer.");
                                    }
                                }
                  ;

boolean_expression: expression  {
                                    if ($1 != 1) {
                                        yyerror("The type is not boolean.");
                                    }
                                }
                  ;

expression: expression ADD expression   {
                                            // Java bytecode
                                            fileWrite(fout, "iadd");

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4 || $1 == 5) && ($3 == 2 || $3 == 3 || $3 == 4 || $3 == 5)) {
                                                    $$ = $1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation ADD.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression SUB expression   {
                                            // Java bytecode
                                            fileWrite(fout, "isub");

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = $1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation SUB.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression MUL expression   {
                                            // Java bytecode
                                            fileWrite(fout, "imul");

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                                                    $$ = $1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation MUL.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression DIV expression   {
                                            // Java bytecode
                                            fileWrite(fout, "idiv");

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                                                    $$ = $1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation DIV.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression REM expression   {
                                            // Java bytecode
                                            fileWrite(fout, "irem");

                                            if ($1 == $3) {
                                                if (($1 == 2) && ($3 == 2)) {
                                                    $$ = $1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation REM.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | SUB expression %prec UMINUS {
                                            // Java bytecode
                                            fileWrite(fout, "ineg");

                                            if ($2 == 2 || $2 == 3) {
                                                $$ = $2;
                                            } else {
                                                $$ = ERROR;
                                                yyerror("This types can not use in operation UMINUS.");
                                            }
                                        }
          | expression LE expression    {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "iflt L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation LE.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression LEEQ expression  {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "ifle L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation LEEQ.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression GR expression    {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "ifgt L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;
              
                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation GR.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression GREQ expression  {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "ifge L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;

                                            if ($1 == $3) {
                                                if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation GREQ.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression EQ expression    {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "ifeq L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;

                                            if ($1 == $3) {
                                                if (($1 == 0 || $1 == 1 || $1 == 2 || $1 == 3 || $1 == 4) && ($3 == 0 || $3 == 1 || $3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation EQ.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression NEQ expression   {
                                            // Java bytecode
                                            fileWrite(fout, "isub");
                                            fileWrite(fout, "ifne L" + to_string(branchIndex));
                                            fileWrite(fout, "iconst_0");
                                            fileWrite(fout, "goto L" + to_string(branchIndex + 1));
                                            fileWrite(fout, "L" + to_string(branchIndex) + ":");
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "L" + to_string(branchIndex + 1) + ":");
                                            branchIndex += 2;

                                            if ($1 == $3) {
                                                if (($1 == 0 || $1 == 1 || $1 == 2 || $1 == 3 || $1 == 4) && ($3 == 0 || $3 == 1 || $3 == 2 || $3 == 3 || $3 == 4)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation NEQ.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression AND expression   {
                                            // Java bytecode
                                            fileWrite(fout, "iand");

                                            if ($1 == $3) {
                                                if (($1 == 1) && ($3 == 1)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation AND.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | expression OR expression    {
                                            // Java bytecode
                                            fileWrite(fout, "ior");

                                            if ($1 == $3) {
                                                if (($1 == 1) && ($3 == 1)) {
                                                    $$ = 1;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("These types can not use in operation OR.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types are not same.");
                                            }
                                        }
          | NOT expression              {
                                            // Java bytecode
                                            fileWrite(fout, "iconst_1");
                                            fileWrite(fout, "ixor");

                                            if ($2 == 1) {
                                                $$ = 1;
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types can not use in operation NOT.");
                                            }
                                        }
          | PAR_L expression PAR_R      { $$ = $2; }
          | bool_val                    {
                                            $$ = VAR_BOOL;

                                            // Java bytecode
                                            if ($1) {
                                                fileWrite(fout, "iconst_1");
                                            } else {
                                                fileWrite(fout, "iconst_0");
                                            }
                                        }
          | INT_VAL                     {
                                            $$ = VAR_INT;

                                            // Java bytecode
                                            fileWrite(fout, "sipush " + to_string($1));
                                        }
          | FLOAT_VAL                   { $$ = VAR_FLOAT; }
          | CHAR_VAL                    { $$ = VAR_CHAR; }
          | STRING_VAL                  {
                                            $$ = VAR_STRING;

                                            // Java bytecode
                                            fileWrite(fout, "ldc \"" + formatString($1) + "\"");
                                        }
          | function_invocation         { $$ = $1; }
          | ID                          {
                                            symbol = scope->globalLookup($1);
                                            if (symbol != NULL) {
                                                // Java bytecode
                                                fileWrite(fout, symbol->byteCode);

                                                if (symbol->type >= 1 && symbol->type <= 4) {
                                                    $$ = symbol->type;
                                                } else if (symbol->type >= 6 && symbol->type <= 9) {
                                                    $$ = symbol->type % 5;
                                                } else if (symbol->type == 5 || symbol->type == 10) {
                                                    $$ = VAR_STRING;
                                                } else {
                                                    $$ = ERROR;
                                                    yyerror("\'" + string($1) + "\' is not constant or variable.");
                                                }
                                            } else {
                                                $$ = ERROR;
                                                yyerror("\'" + string($1) + "\' does not declared.");
                                            }
                                        }
          ;

function_invocation: ID PAR_L PAR_R                                 {
                                                                        symbol = scope->globalLookup($1);

                                                                        if (symbol != NULL) {
                                                                            // Java bytecode
                                                                            fileWrite(fout, symbol->byteCode);

                                                                            if (symbol->type >= 16 && symbol->type <= 20) {
                                                                                $$ = symbol->type % 5;
                                                                            } else {
                                                                                $$ = ERROR;
                                                                                yyerror("\'" + string($1) + "\' is not-return method.");
                                                                            }
                                                                        } else {
                                                                            $$ = ERROR;
                                                                            yyerror("\'" + string($1) + "\' does not declared.");
                                                                        }
                                                                    }
                   | ID PAR_L {
                                parameter.clear();
                              } comma_separated_expressions PAR_R   {
                                                                        symbol = scope->globalLookup($1);

                                                                        if (symbol != NULL) {
                                                                            // Java bytecode
                                                                            fileWrite(fout, symbol->byteCode);

                                                                            if (symbol->type >= 16 && symbol->type <= 20) {
                                                                                $$ = symbol->type % 5;

                                                                                if (symbol->argumentType.size() == parameter.size()) {
                                                                                    bool typeFlag = true;
                                                                                    for (int i=0;i<symbol->argumentType.size();++i) {
                                                                                        if (symbol->argumentType.at(i) % 5 != parameter.at(i)) {
                                                                                            typeFlag = false;
                                                                                        }
                                                                                    }
                                                                                    if (!typeFlag) {
                                                                                        $$ = ERROR;
                                                                                        yyerror("\'" + string($1) + "\' parameter type is not match.");
                                                                                    }
                                                                                } else {
                                                                                    $$ = ERROR;
                                                                                    yyerror("\'" + string($1) + "\' parameter size is not match.");
                                                                                }
                                                                            } else {
                                                                                $$ = ERROR;
                                                                                yyerror("\'" + string($1) + "\' is not-return method.");
                                                                            }
                                                                        } else {
                                                                            $$ = ERROR;
                                                                            yyerror("\'" + string($1) + "\' does not declared.");
                                                                        }
                                                                    }
                   ;

comma_separated_expressions: expression                                     {
                                                                                parameter.push_back($1);
                                                                            }
                           | expression {
                                            parameter.push_back($1);
                                        } COM comma_separated_expressions
                           ;

%%

void yyerror(string t) {
    cout << "Error : " << lineNum << " : " << t << endl;
}

int main (int argc, char *argv[]) {
    if (argc != 2) {
        printf("argv --> need Filename.");
        exit(1);
    }
    fileName = string(argv[1]);
    rawName = fileName.substr(0, fileName.find_last_of('.'));

    yyin = fopen(argv[1], "r");
    fout.open(rawName + ".jasm");

    yyparse();
    return 0;
}
