

%{
    var escopoAtual = 0;
    var tabelaSimbolos = [];
    var tac = [];
    var erros = [];
    var tipoAtual = ''; // Conforme seção 4 do PDF (Verificação de Escopo e Tipo)

    function criarVariavel(tipo, nome, valor, escopo) {
        var existe = tabelaSimbolos.some(function(s) {
            return s.id === nome && s.escopo === escopo;
        });
        if (!existe) {
            tabelaSimbolos.push({ tipo: tipo, id: nome, val: valor, escopo: escopo });
            console.log('Variável criada: ' + nome + ' (' + tipo + ') no escopo ' + escopo);
        }
    }

    function gerarCod(resultado, op1, operador, op2) {
        var linha = resultado + " = " + op1 + " " + operador + " " + op2;
        tac.push(linha);
        console.log('TAC Gerado: ' + linha);
    }
%}

%lex
%%

\s+                                 /* ignorar brancos */
"//".* /* ignorar comentários de linha */
"/*"([^*]|\*+[^*/])*\*+"/"   /* ignore */

/* Diretivas de Pré-processamento */
"#include"[ \t]+"<"[^>\n]+">"        return 'INCLUDE';
"#include"[ \t]+"\""[^"\n]+"\""      return 'INCLUDE';
"#"                                 return '#';
"define"                            return 'DEFINE';

/* Tipos Primitivos */
"int"                               return 'INT';
"double"                            return 'DOUBLE';
"float"                             return 'FLOAT';
"char"                              return 'CHAR';

/* Estruturas de Fluxo e Loops */
"if"                                return 'IF';
"else"                              return 'ELSE';
"while"                             return 'WHILE';
"do"                                return 'DO_WHILE'; /* Ajustado conforme a tabela de tokens do PDF */
"for"                               return 'FOR';
"switch"                            return 'SWITCH';
"case"                              return 'CASE';
"break"                             return 'BREAK';
"default"                           return 'DEFAULT';
"return"                            return 'RETURN';
"void"                              return 'VOID';

/* Operadores Expandidos do C */
"++"                                return 'INCREMENTO';
"+="                                return 'MAIS_IGUAL';
"-="                                return 'MENOS_IGUAL';
"--"                                return 'DECREMENTO';
"sizeof"                            return 'SIZEOF';

/* Operadores Relacionais e Lógicos */
"<="                                return 'LE';
">="                                return 'GE';
"=="                                return 'EQ';
"!="                                return 'NE';
"||"                                return 'OR';
"&&"                                return 'AND';
"!"                                 return 'NOT';
"NULL"                              return 'NULL';
"&"                                 return '&';
\"([^\\\"]|\\.)*\"                  return 'STRING_LIT';

/* Símbolos e Pontuação */
"<"                                 return '<';
">"                                 return '>';
"="                                 return '=';
"("                                 return '(';
")"                                 return ')';
"{"                                 { escopoAtual++; return '{'; }
"}"                                 { escopoAtual--; return '}'; }
"["                                 return '[';
"]"                                 return ']';
"*"                                 return '*';
"/"                                 return '/';
"+"                                 return '+';
"-"                                 return '-';
"%"                                 return '%';
";"                                 return ';';
","                                 return ',';
":"                                 return ':';
"'"                                 return 'QUOTE';
'"'                                 return 'DQUOTE';

/* Identificadores e Literais */
[a-zA-Z_][a-zA-Z0-9_]* return 'IDF';
[0-9]+\.[0-9]+                      return 'F_LIT';
[0-9]+                              return 'INT_LIT';
"'"[^"']"'"                         return 'CHAR_LIT';

.                                   /* ignorar outros caracteres inválidos */
<<EOF>>                             return 'EOF';

/lex

%start expressions

%ebnf

/* Precedências para evitar ambiguidades matemáticas e lógicas */
%left OR
%left AND
%left EQ NE LE GE '<' '>'
%left '+' '-'
%left '*' '/' '%'
%right NOT CAST INCREMENTO

%%

/* >>> Gramática BNF <<< */

expressions
    : elementos EOF
        %{  
            console.log('\n\nAnálise sintática concluída com sucesso!');
            console.log('Análise Semântica');
            console.log('Tabela de símbolos:\n', tabelaSimbolos); 
            console.log('Códigos Three Address Code gerados:\n', tac);
            console.log('Expressões contêm algum erro semântico:\n', erros);
        %}
    ;

elementos
    : elemento elementos
    | /* vazio */
    ;

elemento
    : diretiva
    | declaracao ';'
    | bloco
    | funcao
    ;

diretiva
    : INCLUDE
    | '#' DEFINE IDF INT_LIT
    | '#' DEFINE IDF F_LIT
    | '#' DEFINE IDF IDF
    ;

funcao
    : tipo_basico IDF '(' parametros_opt ')' bloco
    | IDF '(' parametros_opt ')' bloco
    ;
argumentos_opt
    : { $$ = [];}
    | argumentos { $$ = $1;}
    ;
argumentos
    : expr 
        { $$ = [$1]; }
    | expr ',' argumentos 
        { $$ = [$1].concat($3);}
    ;
parametros_opt
    : lista_parametros
    | /* vazio */
    ;

lista_parametros
    : tipo_basico IDF ',' lista_parametros
    | tipo_basico IDF
    ;

bloco
    : '{' comandos '}'
    ;

comandos
    : comando comandos
    | /* vazio */
    ;

comando
    : declaracao ';'
    | atribuicao ';'
    | chamada_funcao ';'
    | comando_estruturado
    | bloco
    | BREAK ';'
    | RETURN expr ';'
    | RETURN ';'
    | ';'
    ;
chamada_funcao
    : IDF '(' argumentos_opt ')'
    ;

comando_estruturado
    : IF '(' condicao ')' comando %prec IF
    | IF '(' condicao ')' comando ELSE comando
    | WHILE '(' condicao ')' comando
    | DO_WHILE comando WHILE '(' condicao ')' ';'
    | FOR '('象征_for ';' _opt ';' atribuicao_for ')' comando
    | SWITCH '(' expr ')' '{' casos '}'
    ;

casos
    : CASE expr ':' comandos casos
    | DEFAULT ':' comandos
    | /* vazio */
    ;

atribuicao_for
    : atribuicao
    | declaracao
    | expr
    | /* vazio */
    ;

_opt
    : condicao
    | /* vazio */
    ;

declaracao
    : tipo_basico vars
    ;

tipo_basico
    : INT    { tipoAtual = 'int'; $$ = 'int'; }
    | FLOAT  { tipoAtual = 'float'; $$ = 'float'; }
    | DOUBLE { tipoAtual = 'double'; $$ = 'double'; }
    | CHAR   { tipoAtual = 'char'; $$ = 'char'; }
    | VOID   { tipoAtual = 'void'; $$ = 'void'; }
    ;

vars
    : var_item ',' vars
    | var_item
    ;

var_item
    : '*' IDF
        {
            criarVariavel(tipoAtual + '*',
                           $2,
                           undefined,
                           escopoAtual);
        }

    | '*' IDF '=' expr
        {
            criarVariavel(tipoAtual + '*',
                           $2,
                           $4,
                           escopoAtual);
        }

    | IDF '=' expr
        {
            criarVariavel(tipoAtual,
                           $1,
                           $3,
                           escopoAtual);
        }

    | IDF '[' expr ']' '=' '{' lista_valores '}'
        {
            criarVariavel(tipoAtual + '[]',
                           $1,
                           'array',
                           escopoAtual);
        }

    | IDF '[' expr ']'
        {
            criarVariavel(tipoAtual + '[]',
                           $1,
                           'array',
                           escopoAtual);
        }

    | IDF
        {
            criarVariavel(tipoAtual,
                           $1,
                           undefined,
                           escopoAtual);
        }
    ;

lista_valores
    : expr ',' lista_valores
    | expr
    ;

atribuicao
    : IDF '=' expr
    | IDF MAIS_IGUAL expr
    | IDF MENOS_IGUAL expr
    | IDF INCREMENTO
    | IDF DECREMENTO
    | IDF '[' expr ']' '=' expr
    ;

condicao
    : condicao OR condicao
    | condicao AND condicao
    | NOT condicao
    | expr meio_comp expr
    | '(' condicao ')'
    | expr
    ;

cond_termo
    : expr meio_comp expr
    | '(' condicao ')'
    | expr
    ;

meio_comp
    : '>' | '<' | GE | LE | NE | EQ
    ;

expr
    : expr '+' termo_mat      { var temp = "t"+tac.length; gerarCod(temp, $1, "+", $3); $$ = temp; }
    | expr '-' termo_mat      { var temp = "t"+tac.length; gerarCod(temp, $1, "-", $3); $$ = temp; }
    | termo_mat               { $$ = $1; }
    ;

termo_mat
    : termo_mat '*' fator_mat { var temp = "t"+tac.length; gerarCod(temp, $1, "*", $3); $$ = temp; }
    | termo_mat '/' fator_mat { var temp = "t"+tac.length; gerarCod(temp, $1, "/", $3); $$ = temp; }
    | termo_mat '%' fator_mat { var temp = "t"+tac.length; gerarCod(temp, $1, "%", $3); $$ = temp; }
    | fator_mat               { $$ = $1; }
    ;

fator_mat
    : '(' expr ')'
        { $$ = $2; }

    | '(' tipo_basico ')' fator_mat %prec CAST
        { $$ = $4; }

    | '(' tipo_basico '*' ')' fator_mat %prec CAST
        { $$ = $5; }

    | chamada_funcao
        { $$ = 'call'; }

    | IDF '[' expr ']'
        { $$ = $1 + "[]"; }

    | IDF
        { $$ = $1; }

    | '&' IDF
        { $$ = "&" + $2; }

    | IDF INCREMENTO
        { $$ = $1; }

    | IDF DECREMENTO
        { $$ = $1; }

    | INT_LIT
        { $$ = $1; }
    | STRING_LIT
        { $$ = $1; }

    | F_LIT
        { $$ = $1; }

    | CHAR_LIT
        { $$ = $1; }
    | SIZEOF '(' tipo_basico ')'
        { $$ = 'sizeof(' + $3 + ')'; }

    | NULL
        { $$ = 'NULL'; }
    ;
