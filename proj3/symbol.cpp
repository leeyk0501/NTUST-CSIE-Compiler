#include "symbol.h"

Symbol::Symbol() {

}

Symbol::Symbol(string name, int type) {
    this->name = name;
    this->type = type;
    this->byteCode = "";
    this->storeCode = "";
}

void Symbol::insertArg(int type) {
    this->argumentType.push_back(type);
}

SymbolTable::SymbolTable() {
    this->name = "";
    this->parentTable = NULL;
    this->returnType = NON;
    this->hasReturn = false;
    this->localValueIndex = 0;
}

SymbolTable::SymbolTable(string name, SymbolTable *parentTable) {
    this->name = name;
    this->parentTable = parentTable;
    this->returnType = NON;
    this->hasReturn = false;
    this->localValueIndex = 0;
}

Symbol* SymbolTable::globalLookup(string name) {
    SymbolTable *currentTable = this;
    while(currentTable != NULL) {
        for(int i=0;i<currentTable->table.size();++i) {
            if(currentTable->table.at(i)->name == name) {
                return currentTable->table.at(i);
            }
        }
        currentTable = currentTable->parentTable;
    }
    return NULL;
}

Symbol* SymbolTable::localLookup(string name) {
    SymbolTable *currentTable = this;
    for(int i=0;i<currentTable->table.size();++i) {
        if(currentTable->table.at(i)->name == name) {
            return currentTable->table.at(i);
        }
    }
    return NULL;
}

/* Inserts s into a new entry of the symbol table  */
void SymbolTable::insert(string name, int type) {
    this->table.push_back(new Symbol(name, type));
}
