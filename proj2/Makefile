all: parser

parser: lex.l yacc.y symbol.h symbol.cpp
	lex lex.l
	yacc -d yacc.y
	g++ -o parser y.tab.c symbol.cpp -ll -ly -std=c++11

.PHONY: clean
clean:
	rm lex.yy.c y.tab.* parser
