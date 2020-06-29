# Project3 - Code Generation
The project is to generate code (in Java assembly language) for the **Scala** language. The generated code will then be translated to Java bytecode by a Java assembler.

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
$ javaa/javaa example.scala
$ java example
```
