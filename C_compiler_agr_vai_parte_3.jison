%{
    var escopoAtual = 0;
    var tabelaSimbolos = [];
    var tac = [];
    var erros = [];
    var tipoAtual = ''; 

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
"/*"([^*]|\*+[^*/])*\*+"/"          /* ignorar comentários de bloco */

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
"void"                              return 'VOID';

/* Estruturas de Fluxo e Loops */
"if"                                return 'IF';
"else"                              return 'ELSE';
"while"                             return 'WHILE';
"do"                                return 'DO_WHILE'; 
"for"                               return 'FOR';
"switch"                            return 'SWITCH';
"case"                              return 'CASE';
"break"                             return 'BREAK';
"default"                           return 'DEFAULT';
"return"                            return 'RETURN';

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

/* Precedências explícitas e completas (incluindo MENOS_UNARIO para corrigir o "-5") */
%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%right NOT CAST INCREMENTO DECREMENTO MENOS_UNARIO
%left '[' ']' '(' ')'

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
    : argumentos { $$ = $1; }
    | /* vazio */ { $$ = []; }
    ;

argumentos
    : expr { $$ = [$1]; }
    | expr ',' argumentos { $$ = [$1].concat($3); }
    ;

parametros_opt
    : lista_parametros
    | /* vazio */
    ;

lista_parametros
    : tipo_basico pointer_opt IDF ',' lista_parametros
    | tipo_basico pointer_opt IDF
    ;

pointer_opt
    : '*'
    | /* vazio */
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
    : IF '(' expr ')' comando %prec IF
    | IF '(' expr ')' comando ELSE comando
    | WHILE '(' expr ')' comando
    | DO_WHILE comando WHILE '(' expr ')' ';'
    | FOR '(' atribuicao_for ';' expr_opt ';' atribuicao_for ')' comando
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

expr_opt
    : expr
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
            criarVariavel(tipoAtual + '*', $2, undefined, escopoAtual);
        }
    | '*' IDF '=' expr
        {
            criarVariavel(tipoAtual + '*', $2, $4, escopoAtual);
        }
    | IDF '=' expr
        {
            criarVariavel(tipoAtual, $1, $3, escopoAtual);
        }
    | IDF '[' expr ']' '=' '{' lista_valores '}'
        {
            criarVariavel(tipoAtual + '[]', $1, 'array', escopoAtual);
        }
    | IDF '[' expr ']'
        {
            criarVariavel(tipoAtual + '[]', $1, 'array', escopoAtual);
        }
    | IDF
        {
            criarVariavel(tipoAtual, $1, undefined, escopoAtual);
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

expr
    : expr OR expr            { var temp = "t"+tac.length; gerarCod(temp, $1, "||", $3); $$ = temp; }
    | expr AND expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "&&", $3); $$ = temp; }
    | expr EQ expr            { var temp = "t"+tac.length; gerarCod(temp, $1, "==", $3); $$ = temp; }
    | expr NE expr            { var temp = "t"+tac.length; gerarCod(temp, $1, "!=", $3); $$ = temp; }
    | expr LE expr            { var temp = "t"+tac.length; gerarCod(temp, $1, "<=", $3); $$ = temp; }
    | expr GE expr            { var temp = "t"+tac.length; gerarCod(temp, $1, ">=", $3); $$ = temp; }
    | expr '<' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "<", $3); $$ = temp; }
    | expr '>' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, ">", $3); $$ = temp; }
    | expr '+' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "+", $3); $$ = temp; }
    | expr '-' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "-", $3); $$ = temp; }
    | expr '*' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "*", $3); $$ = temp; }
    | expr '/' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "/", $3); $$ = temp; }
    | expr '%' expr           { var temp = "t"+tac.length; gerarCod(temp, $1, "%", $3); $$ = temp; }
    | NOT expr                { var temp = "t"+tac.length; gerarCod(temp, "!", $2, ""); $$ = temp; }
    | '-' expr %prec MENOS_UNARIO { var temp = "t"+tac.length; gerarCod(temp, "-", $2, ""); $$ = temp; }
    | '(' expr ')'            { $$ = $2; }
    | '(' tipo_basico ')' expr %prec CAST
                              { $$ = $4; }
    | '(' tipo_basico '*' ')' expr %prec CAST
                              { $$ = $5; }
    | chamada_funcao          { $$ = 'call'; }
    | IDF '[' expr ']'        { $$ = $1 + "[]"; }
    | IDF                     { $$ = $1; }
    | '&' IDF                 { $$ = "&" + $2; }
    | IDF INCREMENTO          { $$ = $1; }
    | IDF DECREMENTO          { $$ = $1; }
    | INT_LIT                 { $$ = $1; }
    | STRING_LIT              { $$ = $1; }
    | F_LIT                   { $$ = $1; }
    | CHAR_LIT                { $$ = $1; }
    | SIZEOF '(' tipo_basico ')' { $$ = 'sizeof(' + $3 + ')'; }
    | 'NULL'                  { $$ = 'NULL'; }
    ;
