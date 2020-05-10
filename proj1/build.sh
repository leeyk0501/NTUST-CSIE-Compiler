#!/bin/bash
cd ~/NTUST-CSIE-Compiler/proj1
lex lex.l
cc -o scanner -O lex.yy.c -ll
./scanner < input.scala
exit 0
