%{
/* Compiler Project3 - Code Generation
 */
#include "lex.yy.c"

#define Trace(t) cout << t << endl

using namespace std;

void yyerror(string t);

SymbolTable *scope;
Symbol *symbol;
bool flag;
vector<int> parameter;
bool haveMainFlag = false;
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

%type <intVal> assignment_type type constant_expression expression array_reference function_invocation

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
                                }
                        BRA_L object_block_declarations BRA_R {
                                                                    if(!haveMainFlag) {
                                                                        yyerror("\'main\' method is not found.");
                                                                    }
                                                                    //TODO: check method have main?
                                                                    SymbolTable *temp = scope;
                                                                    scope = scope->parentTable;
                                                                    delete temp;
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
                             | array
                             ;

// Constant
constant: VAL ID assignment_type ASS constant_expression    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $3 % 5);
                                                                    if ($3 % 5 != $5 % 5) {
                                                                        yyerror("These types are not same.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }
                                                            }
        | VAL ID ASS constant_expression                    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $4 % 5);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }
                                                            }
        ;

assignment_type: COL type { $$ = $2; }
               ;

type: BOOLEAN   { $$ = VAR_BOOL; }
    | INT       { $$ = VAR_INT; }
    | FLOAT     { $$ = VAR_FLOAT; }
    | CHAR      { $$ = VAR_CHAR; }
    | STRING    { $$ = VAR_STRING; }
    ;

constant_expression: bool_val   { $$ = VAR_BOOL; }
                   | INT_VAL    { $$ = VAR_INT; }
                   | FLOAT_VAL  { $$ = VAR_FLOAT; }
                   | CHAR_VAL   { $$ = VAR_CHAR; }
                   | STRING_VAL { $$ = VAR_STRING; }
                   ;

bool_val: TRUE
        | FALSE
        ;

// Variable
variable: VAR ID                                            {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, NON);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }
                                                            }
        | VAR ID ASS constant_expression                    {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $4);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
                                                                }
                                                            }
        | VAR ID assignment_type                            {
                                                                if (scope->localLookup($2) == NULL) {
                                                                    scope->insert($2, $3);
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' is already declared.");
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
                                                            }
        ;

// Array
array: VAR ID assignment_type SBRA_L INT_VAL SBRA_R {
                                                        if (scope->localLookup($2) == NULL) {
                                                            scope->insert($2, $3 + 10);
                                                        } else {
                                                            yyerror("\'" + string($2) + "\' is already declared.");
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
                           } PAR_L optional_formal_arguments PAR_R optional_assignment_type block   {
                                                                                                        SymbolTable *trashTable = scope;
                                                                                                        scope = scope->parentTable;
                                                                                                        delete trashTable;
                                                                                                    }
                  ;

optional_assignment_type: /* empty */
                        | assignment_type {
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
                                                                    } else if (symbol->type >= 1 && symbol->type <= 5) {
                                                                        if (symbol->type % 5 != $3) {
                                                                            yyerror("These types are not same.");
                                                                        }
                                                                    } else {
                                                                        yyerror("\'" + string($1) + "\' is not variable.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($1) + "\' does not declared.");
                                                                }
                                                            }
      | ID SBRA_L integer_expression SBRA_R ASS expression  {
                                                                symbol = scope->globalLookup($1);
                                                                if (symbol != NULL) {
                                                                    if (symbol->type >= 11 && symbol->type <= 15) {
                                                                        if (symbol->type % 5 != $6) {
                                                                            yyerror("These types are not same.");
                                                                        }
                                                                    } else {
                                                                        yyerror("\'" + string($1) + "\'is not array.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($1) + "\' does not declared.");
                                                                }
                                                            }
      | PRINT PAR_L expression PAR_R                        {
                                                                if ($3 == ERROR) {
                                                                    yyerror("The type can not print.");
                                                                }
                                                            }
      | PRINTLN PAR_L expression PAR_R                      {
                                                                if ($3 == ERROR) {
                                                                    yyerror("The type can not print.");
                                                                }
                                                            }
      | READ ID                                             {
                                                                symbol = scope->globalLookup($2);
                                                                if (symbol != NULL) {
                                                                    if (symbol->type < 1 || symbol->type > 5) {
                                                                        yyerror("\'" + string($2) + "\' can not read.");
                                                                    }
                                                                } else {
                                                                    yyerror("\'" + string($2) + "\' does not declared.");
                                                                }
                                                            }
      | RETURN                                              {
                                                                //TODO: check if need return value
                                                                SymbolTable *temp = scope;
                                                                while(temp->returnType == 0) {
                                                                    if (temp->parentTable == NULL) {
                                                                        break;
                                                                    }
                                                                    temp = temp->parentTable;
                                                                }

                                                                if(temp->returnType != FUNC_NON) {
                                                                    if(temp->returnType >= FUNC_BOOL && temp->returnType <= FUNC_STRING) {
                                                                        yyerror(temp->name + " need return value.");
                                                                    } else {
                                                                        yyerror("Return in non-method scope is ilegal.");
                                                                    }
                                                                }
                                                            }
      | RETURN expression                                   {
                                                                //TODO: check if need return value
                                                                SymbolTable *temp = scope;
                                                                while(temp->returnType == 0) {
                                                                    if (temp->parentTable == NULL) {
                                                                        break;
                                                                    }
                                                                    temp = temp->parentTable;
                                                                }

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

conditional: IF PAR_L boolean_expression PAR_R block_or_simple ELSE block_or_simple
           | IF PAR_L boolean_expression PAR_R block_or_simple
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

while_loop: WHILE PAR_L boolean_expression PAR_R block_or_simple
          ;

for_loop: FOR PAR_L ID  {
                            symbol = scope->globalLookup($3);
                            if (symbol == NULL) {
                                yyerror("\'" + string($3) + "\' does not declared.");
                            } else if (symbol->type % 5 != VAR_INT) {
                                yyerror("\'" + string($3) + "\' is not integer.");
                            }
                        } ARR INT_VAL TO INT_VAL PAR_R block_or_simple
        ;

procedure_invocation: ID    {
                                symbol = scope->globalLookup($1);
                                if (symbol == NULL) {
                                    yyerror("\'" + string($1) + "\' does not declared.");
                                } else {
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
                                            if ($2 == 2 || $2 == 3) {
                                                $$ = $2;
                                            } else {
                                                $$ = ERROR;
                                                yyerror("This types can not use in operation UMINUS.");
                                            }
                                        }
          | expression LE expression    {
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
                                            if ($2 == 1) {
                                                $$ = 1;
                                            } else {
                                                $$ = ERROR;
                                                yyerror("These types can not use in operation NOT.");
                                            }
                                        }
          | PAR_L expression PAR_R      { $$ = $2; }
          | bool_val                    { $$ = VAR_BOOL; }
          | INT_VAL                     { $$ = VAR_INT; }
          | FLOAT_VAL                   { $$ = VAR_FLOAT; }
          | CHAR_VAL                    { $$ = VAR_CHAR; }
          | STRING_VAL                  { $$ = 0; }
          | array_reference             { $$ = $1; }
          | function_invocation         { $$ = $1; }
          | ID                          {
                                            symbol = scope->globalLookup($1);
                                            if (symbol != NULL) {
                                                if (symbol->type >= 1 && symbol->type <= 10) {
                                                    $$ = symbol->type % 5;
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

array_reference: ID SBRA_L integer_expression SBRA_R    {
                                                            symbol = scope->globalLookup($1);
                                                            if (symbol != NULL) {
                                                                if (symbol->type >= 11 && symbol->type <= 15) {
                                                                    $$ = symbol->type % 5;
                                                                } else {
                                                                    $$ = ERROR;
                                                                    yyerror("\'" + string($1) + "\' is not array.");
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
    cout << "Warning : " << lineNum << " : " << t << endl;
}

int main (int argc, char *argv[]) {
    if (argc != 2) {
        printf("argv --> need Filename.");
        exit(1);
    }
    yyin = fopen(argv[1], "r");
    yyparse();
    return 0;
}
