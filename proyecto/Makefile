ejecutable_minic: lex.yy.c main.c miniC.tab.c listaSimbolos.c listaCodigo.c
	gcc -g main.c lex.yy.c miniC.tab.c listaSimbolos.c listaCodigo.c -lfl -o ejecutable_minic

miniC.tab.c miniC.tab.h: miniC.y
	bison -d -v miniC.y

lex.yy.c: lexico1.l miniC.tab.h
	flex lexico1.l

clean:
	rm -f ejecutable_minic miniC.tab.c miniC.tab.h lex.yy.c miniC.output

run: ejecutable_minic entrada.mc
	./ejecutable_minic entrada.mc > salida.s
