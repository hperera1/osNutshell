CC=/usr/bin/cc

all: bison-config flex-config nutshell

bison-config:
	bison -d nutshellParser.y

flex-config:
	flex nutshellScanner.l

nutshell:
	$(CC) nutshell.c nutshellParser.tab.c lex.yy.c -o nutshell

clean:
	rm nutshellParser.tab.c nutshellParser.tab.h lex.yy.c nutshell
