%{
#include "miniC.tab.h"
#include <math.h>
void error_lexico();
void id_error();
void error_entero(const char *valor);
int errorLex=0;
int lineaInicioComentario=0;
extern int yylineno;
%}
digito              [0-9]
letra               [a-zA-ZñÑ]
entero              {digito}+
identificador	    ({letra}|_)({letra}|{digito}|_){0,31}
identificador_error ({letra}|_)({letra}|{digito}|_){32,}
expresion 	    "("{entero}("+"|"-"){entero}")"
cadena		    \"([^"\n\\]|{escape})*\"
escape         	\\.
error_caracter  	[^0-9a-zA-Z_ \t\n\r;{}()=<>\+\-\*/,\":]+

%option yylineno

%x 	COM_MULT
%%

	//el comentario multilinea returnea algo o es como lo de aqui abajo que pone ";"

[ \n\t]+                            ;
"//"(.*)[\n]                        ; //comentario de una linea

"/*"                        { lineaInicioComentario = yylineno; BEGIN(COM_MULT); }  //comentario multilinea
<COM_MULT>"*/"              { BEGIN(INITIAL); }
<COM_MULT>.    	      ;
<COM_MULT>\n 		      ;
<COM_MULT><<EOF>> 	     {printf("Error: comentario sin cerrar iniciado en la línea %d\n",lineaInicioComentario);
			      errorLex++;
			      return 0;}
			      

read                                return READ;

{entero}                           {if(atoll(yytext)>pow(2,31)){
					error_entero(yytext);
					yylval.lexema = strdup(yytext);
				    	return ENTERO;
				    }
				    else{
				    yylval.lexema = strdup(yytext);
				    	return ENTERO;
				    }}
				    
var 				    return VAR;
const				    return CONST;
int				    return INT;
if				    return IF;
else				    return ELSE;
while				    return WHILE;
print				    return PRINT;
				    
	
{identificador}		{yylval.lexema = strdup(yytext);     	   
					return ID;}
				

	/*{identificador} "=" {identificador}   return EXPRESION;*/
	
{cadena}		     	   {yylval.lexema = strdup(yytext);
					return CADENACHAR;}



"("                                 return LPAREN;		
")"                                 return RPAREN;
";"                                 return SEMICOLON;
","                                 return COMMA;
"="                                 return ASSIGNOP;
"+"                                 return PLUSOP;
"-"                                 return MINUSOP;
"*"				    return MULTOP;
"/"				    return DIVOP;	
"\""				    return COMILLAS;
"{"				    return ILLAVE;
"}"				    return DLLAVE;
":"				    return DPOINTS;
"?"				    return INTER;

{identificador_error}		{id_error();
				 yylval.lexema = strdup(yytext);     	   
				 return ID;}			
{error_caracter} 		{error_lexico();}
					 				                                   
%%

void id_error(){
	printf("ERROR en la linea %i: Id demasiado largo %s\n", yylineno, yytext);
	errorLex++;
	
} 		



void error_lexico()
{
	  printf("\nERROR, simbolo no reconocido %s\n",yytext);
	  errorLex++;
}

void error_entero(const char *valor)
{
	printf("\nERROR: Entero fuera de rango %s\n",valor);
	errorLex++;
}

int yywrap(){
	return 1;
}

    

