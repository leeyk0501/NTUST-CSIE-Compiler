all: scanner

scanner: lex.yy.c
	cc -o scanner -O lex.yy.c -ll

lex.yy.c: lex.l
	lex lex.l

.PHONY: clean
clean:
	rm lex.yy.c scanner