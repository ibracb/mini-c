%{
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include "listaSimbolos.h"
#include "listaCodigo.h"

Lista tablaSimb;
int contCadenas=0;
char registros[10] = {0,0,0,0,0,0,0,0,0,0};
int errorSin = 0;
int errorSem = 0;
extern int errorLex;
int contador_etiq=1;
Tipo tipo;
extern int yylineno;

void yyerror();
void yyerrorsem();
extern int yylex();


bool esConstante(char *id);
bool perteneceTablaS(char *id);
void insertaTablaIdentificador(char *id, Tipo tipo,int num);
void insertarTablaS(char *id, Tipo tipo);
char * concatena(char * s1, char * s2);
void liberaReg(char* registro);
char *registroLibre();
void imprimirListaC(ListaC codigo);
char* nuevaEtiqueta();



%}


%code requires{
 #include "listaCodigo.h"
}

%union{
char *lexema;
ListaC codigo;

}


%token READ LPAREN RPAREN SEMICOLON COMMA ASSIGNOP PLUSOP MINUSOP REALLIT COMENTARIO MULTOP DIVOP VAR IF ELSE WHILE PRINT INT CONST COMILLAS ILLAVE DLLAVE INTER DPOINTS

%token <lexema> CADENACHAR ID ENTERO


%type <codigo> expresion program declarations statement_list statement print_list print_item read_list var_list const_list

%expect 1


%left PLUSOP MINUSOP
%left MULTOP DIVOP
%left NEG
%right ELSE INTER DPOINTS


%%

program : {tablaSimb=creaLS();} ID LPAREN RPAREN ILLAVE declarations statement_list DLLAVE	{
												if(errorSin == 0 && errorSem==0 && errorLex==0){
													imprimirTablaS(tablaSimb);
													concatenaLC($6,$7);
													imprimirListaC($6);
												}else{
													    printf("Errores lexicos: %i\n", errorLex);
													    printf("Errores sintacticos: %i\n",errorSin);
													    printf("Errores semanticos: %i\n",errorSem);
												}
												liberaLC($6);
												liberaLC($7); 
												liberaLS(tablaSimb);
												
};

declarations : declarations VAR INT {tipo = VARIABLE;} var_list SEMICOLON		{
									 $$ = $1;
                                                                      	concatenaLC($$, $5);
                                                                      	liberaLC($5);
					
										}

| declarations CONST INT { tipo = CONSTANTE; } const_list SEMICOLON			{
									  $$ = $1;
                                                                       concatenaLC($$, $5);
                                                                       liberaLC($5);										
												
										}
| %empty								{$$ = creaLC();}

| declarations VAR error SEMICOLON                                   {$$ = creaLC();
									yyerrok;
									yyclearin;}
							                
| declarations CONST error SEMICOLON                                 {$$ = creaLC();
									yyerrok;
									yyclearin;}
;


var_list : ID 								{if (!perteneceTablaS($1)){ 
										insertaTablaIdentificador($1,VARIABLE,0);
										            $$ = creaLC(); 
									    Operacion oper; 
									    oper.op = "lw"; 
									    oper.res = registroLibre(); 
									    oper.arg1 = concatena("_",$1); 				
									    oper.arg2 = NULL;
									    guardaResLC($$, oper.res); 
									    insertaLC($$, inicioLC($$), oper);
									}else {printf("Variable %s ya declarada \n",$1);
										$$ = creaLC();
										errorSem++;
										}
									}
									
| var_list COMMA ID 							{if (!perteneceTablaS($3)) {
										insertaTablaIdentificador($3,VARIABLE,0);
										ListaC nueva = creaLC();
									    	Operacion oper; 
									    	oper.op = "lw"; 
									    	oper.res = registroLibre(); 
									    	oper.arg1 = concatena("_",$3); 
									    	oper.arg2 = NULL;
									    	guardaResLC(nueva, oper.res); 
									    	insertaLC(nueva, inicioLC(nueva), oper);
									    	concatenaLC($1, nueva); 
									    	$$ = $1; 
									    	liberaLC(nueva);
									}else {printf("Variable %s ya declarada \n",$3);
										$$ = creaLC();
										errorSem++;}
									}

;

const_list : ID ASSIGNOP expresion					{if (!perteneceTablaS($1)) {
										insertaTablaIdentificador($1,CONSTANTE,0);
										Operacion  op;
                                      					op.op="sw";
                                      					op.res=recuperaResLC($3);
                                      					op.arg1=concatena("_",$1);
                                      					op.arg2=NULL;
                                      		                       insertaLC($3,finalLC($3),op);
                                      					liberaReg(op.res);
                                      					$$=$3;
									}else{ printf("Constante %s ya declarada \n",$1);
										errorSem++;
										$$ = creaLC();
										}
									}
									
| const_list COMMA ID ASSIGNOP expresion				{if (!perteneceTablaS($3)) {
										insertaTablaIdentificador($3,CONSTANTE,0);
										Operacion  op;
                                      					op.op="sw";
                                      					op.res=recuperaResLC($5);
                                      					op.arg1=concatena("_",$3);
                                      					op.arg2=NULL;
                                      		                       insertaLC($5,finalLC($5),op);
                                      					liberaReg(op.res);
                                      					$$=$5;
									}else{ printf("Constante %s ya declarada \n",$3);
										errorSem++;
										$$ = creaLC();
										}
									};


statement_list : statement_list statement				{ concatenaLC($1, $2); $$ = $1; liberaLC($2); }
| %empty 								{ $$ = creaLC(); }
;

statement : ID ASSIGNOP expresion SEMICOLON				{if (!perteneceTablaS($1)){
										printf("Variable %s no declarada \n",$1);
										errorSem++;
										$$ = creaLC();
										
									}else if (esConstante($1)){
 										printf("Reasignación a constante: %s\n",$1);
 										errorSem++;
 										$$ = creaLC();
 									}else{
 										Operacion  op;
                                      					op.op="sw";
                                      					op.res=recuperaResLC($3);
                                      					op.arg1=concatena("_",$1);
                                      					op.arg2=NULL;
                                      		                       insertaLC($3,finalLC($3),op);
                                      					liberaReg(op.res);
                                      					$$=$3;
 									
 									}
 									
 												}
| ILLAVE statement_list DLLAVE					{$$=$2;}
| IF LPAREN expresion RPAREN statement ELSE statement		{$$=$3;
									 Operacion op;
									 char* etiqFinIf = nuevaEtiqueta();
          								 char* etiqElse = nuevaEtiqueta();
                                        				 op.op = "beqz";
									 op.res = recuperaResLC($3);
									 op.arg1 = etiqFinIf;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 concatenaLC($$,$5);
									 
									 
									 op.op = "b";
									 op.res = etiqElse;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 op.op = concatena(etiqFinIf,":");
									 op.res = NULL;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 concatenaLC($$,$7);
									 
									 op.op = concatena(etiqElse,":");
									 op.res = NULL;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 }
| IF LPAREN expresion RPAREN statement				{$$=$3;
									 Operacion op;
									 char* etiqFinIf = nuevaEtiqueta();
                                        				 op.op = "beqz";
									 op.res = recuperaResLC($3);
									 op.arg1 = etiqFinIf;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 concatenaLC($$,$5);
									 
									 
									 op.op = concatena(etiqFinIf,":");
									 op.res = NULL;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);}
									 
		
| WHILE LPAREN expresion RPAREN statement				{$$=creaLC();
									 Operacion op;
									 char* etiqFinWhile = nuevaEtiqueta();
									 char* etiqWhile = nuevaEtiqueta();
									 
									 op.op = concatena(etiqWhile,":");
									 op.res = NULL;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 concatenaLC($$,$3);
									 
                                        				 op.op = "beqz";
									 op.res = recuperaResLC($3);
									 op.arg1 = etiqFinWhile;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 concatenaLC($$,$5);
									 
									 op.op = "b";
									 op.res = etiqWhile;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);
									 
									 op.op = concatena(etiqFinWhile,":");
									 op.res = NULL;
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 insertaLC($$,finalLC($$), op);}
									 
									 
| PRINT LPAREN print_list RPAREN SEMICOLON				{$$ = $3;}
| READ LPAREN read_list RPAREN SEMICOLON				{$$ = $3;}
| error SEMICOLON  							{$$ = creaLC(); 
								        yyerrok;
								        yyclearin;}
| error DLLAVE 							{$$ = creaLC();
								        yyerrok;
								        yyclearin;}
								        
;

print_list : print_item						{$$ = $1;}
| print_list COMMA print_item						{concatenaLC($1,$3);
									 $$=$1;
									 liberaLC($3);
									}
;

print_item : expresion							{$$=$1;
									 Operacion op;
                                        				 op.op = "li";
									 op.arg1 = "1";
									 op.arg2 = NULL;
									 op.res = "$v0";
									 insertaLC($$,finalLC($$), op);
									 op.op = "move";
									 op.arg1 = recuperaResLC($1);
									 op.arg2 = NULL;
									 op.res = "$a0";
									 insertaLC($$,finalLC($$), op);
									 guardaResLC($$, op.res);
									 op.op = "syscall";
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 op.res = NULL;
									 insertaLC($$,finalLC($$), op);};
									 
| CADENACHAR								{insertarTablaS($1,CADENA);
									 $$=creaLC();
									 Operacion op;
                                        				 op.op = "li";
									 op.arg1 = "4";
									 op.arg2 = NULL;
									 op.res = "$v0";
									 insertaLC($$,finalLC($$), op);
									 op.op = "la";
									 char* str;
                            						 asprintf(&str,"$str%d",contCadenas-1);
                              					 op.arg1 = str;
                            						 op.arg2 = NULL;
									 op.res = "$a0";
									 insertaLC($$,finalLC($$), op);
									 op.op = "syscall";
									 op.arg1 = NULL;
									 op.arg2 = NULL;
									 op.res = NULL;
									 insertaLC($$,finalLC($$), op);} 
;

read_list : ID								{if (!perteneceTablaS($1)){
										printf("Variable %s no declarada \n",$1);
										errorSem++;
										$$ = creaLC();
										}
 									else if (esConstante($1)){
 										printf("Asignación a constante\n");
 										errorSem++;
 										$$ = creaLC();
 										}
 									else{
            									$$ = creaLC();
            									Operacion oper; 
            									oper.op = "li"; 
            									oper.res = "$v0"; 
            									oper.arg1 = "5"; 
            									oper.arg2 = NULL;
            									insertaLC($$, finalLC($$), oper);
            									Operacion oper2; 
            									oper2.op = "syscall"; 
            									oper2.res = NULL; 
            									oper2.arg1 = NULL; 
            									oper2.arg2 = NULL;
            									insertaLC($$, finalLC($$), oper2);
            									Operacion oper3; 
            									oper3.op = "sw"; 
            									oper3.res = "$v0"; 
            									oper3.arg1 = concatena("_",$1); 
            									oper3.arg2 = NULL;
            									insertaLC($$, finalLC($$), oper3);         }
            									}
| read_list COMMA ID							{if (!perteneceTablaS($3)){
										printf("Variable %s no declarada \n",$3);
										errorSem++;
										$$ = creaLC();
										}
 									else if(esConstante($3)){
 										printf("Asignación a constante\n");
 										errorSem++;
 										$$ = creaLC();
 										}
 										
 									else{
            									ListaC nueva = creaLC();
            									Operacion oper; 
            									oper.op = "li"; 
            									oper.res = "$v0"; 
            									oper.arg1 = "5"; 
            									oper.arg2 = NULL;
            									insertaLC(nueva, finalLC(nueva), oper);
            									Operacion oper2; 
            									oper2.op = "syscall"; 
            									oper2.res = NULL; 
            									oper2.arg1 = NULL; 
            									oper2.arg2 = NULL;
            									insertaLC(nueva, finalLC(nueva), oper2);
            									Operacion oper3; 
            									oper3.op = "sw"; 
            									oper3.res = "$v0"; 
            									oper3.arg1 = concatena("_",$3); 
            									oper3.arg2 = NULL;
            									insertaLC(nueva, finalLC(nueva), oper3);
            									concatenaLC($1, nueva); liberaLC(nueva); $$ = $1;
            									}
        }
 							
;

expresion : expresion PLUSOP expresion				{char *numIzq = recuperaResLC($1);
									 char *numDer = recuperaResLC($3);
									 concatenaLC($1,$3);
									 liberaLC($3);
									 Operacion op;
									 op.op = "add";
									 op.arg1 = numIzq;
									 op.arg2 = numDer;
									 op.res = numIzq;
									 insertaLC($1,finalLC($1), op);
									 guardaResLC($1, op.res);
									 liberaReg(numDer);
									 $$ = $1;
									 }
									 
| expresion MINUSOP expresion						{char *numIzq = recuperaResLC($1);
									 char *numDer = recuperaResLC($3);
									 concatenaLC($1,$3);
									 liberaLC($3);
									 Operacion op;
									 op.op = "sub";
									 op.arg1 = numIzq;
									 op.arg2 = numDer;
									 op.res = numIzq;
									 insertaLC($1,finalLC($1), op);
									 guardaResLC($1, op.res);
									 liberaReg(numDer);
									 $$ =  $1;}
									 
| expresion MULTOP expresion						{char *numIzq = recuperaResLC($1);
									 char *numDer = recuperaResLC($3);
									 concatenaLC($1,$3);
									 liberaLC($3);
									 Operacion op;
									 op.op = "mul";
									 op.arg1 = numIzq;
									 op.arg2 = numDer;
									 op.res = numIzq;
									 insertaLC($1,finalLC($1), op);
									 guardaResLC($1, op.res);
									 liberaReg(numDer);
									 $$ =  $1;}
									 
| expresion DIVOP expresion						{char *numIzq = recuperaResLC($1);
									 char *numDer = recuperaResLC($3);
									 concatenaLC($1,$3);
									 liberaLC($3);
									 Operacion op;
									 op.op = "div";
									 op.arg1 = numIzq;
									 op.arg2 = numDer;
									 op.res = numIzq;
									 insertaLC($1,finalLC($1), op);
									 guardaResLC($1, op.res);
									 liberaReg(numDer);
									 $$ =  $1;}
									 
| LPAREN expresion INTER expresion DPOINTS expresion RPAREN		{$$ = creaLC();
									 Operacion op;
									 char* etiqElse = nuevaEtiqueta();
								 	 char* etiqEnd = nuevaEtiqueta();
								 	 char* regTemp = registroLibre();
								 	 
								 	 concatenaLC($$, $2);
								 	 
									 op.op = "beqz";
									 op.res = recuperaResLC($2);
									 op.arg1 = etiqElse;
									 op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
								
									 concatenaLC($$, $4);
									 
									 op.op = "move";
									 op.res = regTemp;
									 op.arg1 = recuperaResLC($4);
									 op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
									
									 op.op = "b";
									 op.res = etiqEnd;
									 op.arg1 = op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
									
									 op.op = concatena(etiqElse, ":");
									 op.res = op.arg1 = op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
									
									 concatenaLC($$, $6);
									 op.op = "move";
									 op.res = regTemp;
									 op.arg1 = recuperaResLC($6);
									 op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
									
									 op.op = concatena(etiqEnd, ":");
									 op.res = op.arg1 = op.arg2 = NULL;
									 insertaLC($$, finalLC($$), op);
									 
									 guardaResLC($$, regTemp);
									
									 liberaReg(recuperaResLC($2));
									 liberaReg(recuperaResLC($4));
									 liberaReg(recuperaResLC($6));
									 liberaLC($2);
									 liberaLC($4);
									 liberaLC($6);
									 }

| MINUSOP expresion %prec NEG						{char *numNeg = recuperaResLC($2);
									 $$=$2;
									 Operacion op;
									 op.op = "neg";
									 op.res= numNeg;
									 op.arg1= numNeg;
									 op.arg2= NULL;
									 insertaLC($$,finalLC($$), op);
									 guardaResLC($$, op.res);
									 }
									 
									 
										
| LPAREN expresion RPAREN						{$$=$2;}


| ID									{if(!perteneceTablaS($1)) {
										printf("Variable %s no declarada \n",$1);
										errorSem++;
										}
									 $$ = creaLC();
									 Operacion op;
									 op.op = "lw";
									 op.res = registroLibre();
									 op.arg1 = concatena("_",$1);
									 op.arg2= NULL;
									 insertaLC($$,finalLC($$), op);
									 guardaResLC($$, op.res);
									}
| ENTERO								{
									 $$ = creaLC();
									 Operacion op;
									 op.op = "li";
									 op.res = registroLibre();
									 op.arg1 = $1;
									 op.arg2= NULL;
									 insertaLC($$,finalLC($$), op);
									 guardaResLC($$, op.res);
}
;
%%


bool esConstante(char *id){
    PosicionLista p = buscaLS(tablaSimb, id);
    Simbolo aux = recuperaLS(tablaSimb,p);
    if(aux.tipo == CONSTANTE){
        return true;
    }
    else{
        return false;
    }
}

bool perteneceTablaS(char *id){
    PosicionLista p = buscaLS(tablaSimb, id);
    if (p != finalLS(tablaSimb)) {
        return true;
    }
    else {
        return false;
    }
}
void insertaTablaIdentificador(char *id, Tipo tipo,int num){
    Simbolo aux;
    aux.nombre = id;
    aux.tipo = tipo;
    aux.valor = num;
    insertaLS(tablaSimb, finalLS(tablaSimb), aux);
}

void insertarTablaS(char *id, Tipo tipo){
    Simbolo aux;
    aux.nombre = id;
    aux.tipo = tipo;
    if(tipo==CADENA){
        aux.valor = contCadenas;
        contCadenas++;
    }
    insertaLS(tablaSimb, finalLS(tablaSimb), aux);
}

char * concatena(char * s1, char * s2){
    char *aux;
    asprintf(&aux, "%s%s", s1, s2);
    return strdup(aux);
}



char *registroLibre(){
  for(int i=0;i<10;i++){
    if(registros[i]==0){
      registros[i]=1;
      char* reg;
      asprintf(&reg,"$t%d",i);
      return reg;
    }
  }
  printf("Error registros temporales agotados!\n");
  exit(1);
}

void liberaReg(char* registro){

    int numRegistro = atoi(&registro[2]);
    registros[numRegistro] = 0;

}

void imprimirListaC(ListaC codigo){
  printf(".text\n.globl main\nmain:\n");
  PosicionListaC p = inicioLC(codigo);
  Operacion oper;
 	while (p != finalLC(codigo)) {
  		oper = recuperaLC(codigo,p);
 	 	printf("%s",oper.op);
	  	if (oper.res) {printf(" %s",oper.res);}
	  	if (oper.arg1) {printf(",%s",oper.arg1);}
	  	if (oper.arg2) {printf(",%s",oper.arg2);}
  		printf("\n");
  		p = siguienteLC(codigo,p);

	}
 printf("li $v0, 10\nsyscall\n");
}

char* nuevaEtiqueta(){
    char* etiq;
    asprintf(&etiq,"etiq%d",contador_etiq);
    contador_etiq++;
    return etiq;
}


void yyerror(){
    printf("\nERROR sintactico en la linea %i\n",yylineno);
    errorSin++;
}

void yyerrorsem(){
    printf("\nERROR semantico en la linea %i\n",yylineno);
    errorSem++;
}



