# Project3 - Code Generation
The project is to generate code (in **Java assembly language**) for the Scala language. The generated code will then be translated to Java bytecode by a Java assembler.

## Language Restrictions
In order to keep the code generation assignment simple that we can implement most of the features of the language, only a subset set of Scala language will be considered in this assignment:

+ No READ statements.
+ No declaration or use of arrays.
+ No floating-point numbers.
+ No string variables.

## My development env
### OS
+ WSL: Ubuntu-18.04
### development
+ g++ (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0
+ flex 2.6.4
+ bison (GNU Bison) 3.0.4
+ GNU Make 4.1 Built for x86_64-pc-linux-gnu
+ openjdk 1.8.0_252

## Install flex & OpenJDK 8
```
$ sudo apt install flex bison
$ sudo apt-get install openjdk-8-jre
```

## How to build & run
```
$ make
$ ./parser example.scala
$ javaa/javaa example.jasm
$ java example
```

## Files tree
```
├── lex.l       // The Scanner
├── yacc.y      // The Parser & Code Generator
├── symbol.h    // Symbol & SymbolTable Class Header
├── symbol.cpp  // Symbol & SymbolTable Class c++
├── Makefile    // Makefile
├── javaa/      // Folder for generate Java assembly language 
└── example/    // Testing scala file folder
```

## Update log
### `lex.l`
+ 修正 string 的 bug
### `yacc.y`
+ 修正 proj2 舊有的 bug
+ 於每個區塊放入適當的 Code Generator
### `symbol.h` & `symbol.cpp`
+ 於 `Symbol` 和 `SymbolTable` 新增成員供 `yacc.y` 使用

