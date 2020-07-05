#ifndef SYMBOL_H
#define SYMBOL_H
#include<iostream>
#include<string>
#include<vector>

// Namespace
using namespace std;

// Type
#define ERROR -1
#define NON 0
#define VAR_BOOL 1
#define VAR_INT 2
#define VAR_FLOAT 3
#define VAR_CHAR 4
#define VAR_STRING 5
#define CONST_BOOL 6
#define CONST_INT 7
#define CONST_FLOAT 8
#define CONST_CHAR 9
#define CONST_STRING 10
#define ARRAY_BOOL 11
#define ARRAY_INT 12
#define ARRAY_FLOAT 13
#define ARRAY_CHAR 14
#define ARRAY_STRING 15
#define FUNC_BOOL 16
#define FUNC_INT 17
#define FUNC_FLOAT 18
#define FUNC_CHAR 19
#define FUNC_STRING 20
#define FUNC_NON 21

class Symbol {
    public:
        Symbol();
        Symbol(string, int);
        void insertArg(int);
        string name;
        int type;
        vector<int> argumentType;

        // Java bytecode
        string byteCode;
        string storeCode;
};

class SymbolTable {
    public:
        SymbolTable();
        SymbolTable(string, SymbolTable*);
        Symbol* globalLookup(string);
        Symbol* localLookup(string);
        void insert(string, int);
        vector<Symbol*> table;
        SymbolTable *parentTable;
        string name;
        int returnType;
        bool hasReturn;
        int localValueIndex;
};
#endif //SYMBOL_H