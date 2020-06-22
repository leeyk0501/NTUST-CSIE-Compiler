# Project2 - Lexical Definition
The project is to write an LALR(1) parser for the **Scala** language.
Write the
grammar and create a parser using **yacc**.

## My development env
### OS
+ WSL: Ubuntu-18.04
### development
+ g++ (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0
+ flex 2.6.4
+ bison (GNU Bison) 3.0.4
+ GNU Make 4.1 Built for x86_64-pc-linux-gnu

## Install flex
```
$ sudo apt install flex bison
```

## How to build & run
```
make
./parser examples/HelloWorld.scala
```
## Files tree
```
├── lex.l       // The Scanner
├── yacc.y      // The Parser
├── symbol.h    // Symbol & SymbolTable Class Header
├── symbol.cpp  // Symbol & SymbolTable Class c++
├── Makefile    // Makefile
└── example/    // Testing scala file folder
```

## Update log
+ 改用 `g++ (-std=c++11)` 編譯

### Scanner
+ 讓 token 可以被 Parser 接收並使用
+ 把值的型態放入 `yylval`
+ 新增 `char` 型態
+ 將 `SymbolTable` 實作部分獨立至 `symbol.h` &  `symbol.cpp`
+ 加入 `symbol.h` & `y.tab.h`
+ 刪除 `main()`

