

%{
    var escopoAtual = 0;
    var tabelaSimbolos = [];
    var tac = [];
    var erros = [];
    var tipoAtual = ''; 

    // Contadores exigidos pelo PDF para geração de IDs internos
    var nInt = 0;
    var nFloat = 0;

    function criarVariavel(tipo, nome, valor, escopo) {
        // Verificação de Escopo (Seção 4 do PDF): Evita duplicidade no mesmo escopo
        var existe = tabelaSimbolos.some(function(s) {
            return s.nomeReal === nome && s.escopo === escopo;
        });

        if (existe) {
            erros.push("Erro Semântico: Variável '" + nome + "' já declarada no escopo " + escopo);
            return;
        }

        // Lógica estrita do PDF: Convertendo nome para ID interno (@i0, @f0...)
        var prefixo = (tipo && tipo[0] === 'f') ? 'f' : 'i';
        var num = (prefixo === 'f') ? nFloat++ : nInt++;
        var idInterno = "@" + prefixo + num;

        tabelaSimbolos.push({ 
            tipo: tipo, 
            nomeReal: nome,      // Guarda o nome digitado
            id: idInterno,       // O identificador interno exigido pelo PDF
            val: valor, 
            escopo: escopo 
        });
        
        console.log('Variável criada: ' + nome + ' convertida para ' + idInterno + ' (' + tipo + ') no escopo ' + escopo);
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
"/*"([^*]|\*+[^*/])*?\*+"/"         /* ignorar comentários de bloco */

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

/* Operadores Expandidos do C */
"++"                                return 'INCREMENTO';
"+="                                return 'MAIS_IGUAL';
"-="                                return 'MENOS_IGUAL';

/* Operadores Relacionais e Lógicos */
"<="                                return 'LE';
">="                                return 'GE';
"=="                                return 'EQ';
"!="                                return 'NE';
"||"                                return 'OR';
"&&"                                return 'AND';
"!"                                 return 'NOT';

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
    | comando_estruturado
    | bloco
    | BREAK ';'
    | ';'
    ;

comando_estruturado
    : IF '(' condicao ')' comando %prec IF
    | IF '(' condicao ')' comando ELSE comando
    | WHILE '(' condicao ')' comando
    | DO_WHILE comando WHILE '(' condicao ')' ';'
    | FOR '(' atribuicao_for ';' condicao_opt ';' atribuicao_for ')' comando
    | SWITCH '(' expr ')' '{' casos '}'
    ;

casos
    : CASE expr ':' casos
    | DEFAULT ':' comandos
    | comando comandos
    | /* vazio */
    ;

atribuicao_for
    : atribuicao
    | expr
    | /* vazio */
    ;

condicao_opt
    : condicao
    | /* vazio */
    ;

declaracao
    : capturar_tipo vars
    ;

capturar_tipo
    : tipo_basico { tipoAtual = $1; }
    ;

tipo_basico
    : INT    { $$ = 'int'; }
    | FLOAT  { $$ = 'float'; }
    | DOUBLE { $$ = 'double'; }
    | CHAR   { $$ = 'char'; }
    ;
vars
    : var_item ',' vars
    | var_item
    ;

var_item
    : IDF '=' expr
        { criarVariavel(tipoAtual, $1, $3, escopoAtual); }
    | IDF '[' expr ']' '=' '{' lista_valores '}'
        { criarVariavel(tipoAtual + '[]', $1, 'array', escopoAtual); }
    | IDF '[' expr ']'
        { criarVariavel(tipoAtual + '[]', $1, 'array', escopoAtual); }
    | IDF
        { criarVariavel(tipoAtual, $1, undefined, escopoAtual); }
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
    | IDF '[' expr ']' '=' expr
    ;

condicao
    : condicao OR cond_termo
    | condicao AND cond_termo
    | NOT condicao
    | cond_termo
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
    : '(' expr ')'            { $$ = $2; }
    | '(' tipo_basico ')' fator_mat %prec CAST { $$ = $4; }
    | IDF '[' expr ']'        { $$ = $1 + "[]"; }
    | IDF                     { $$ = $1; }
    | IDF INCREMENTO          { $$ = $1; }
    | INT_LIT                 { $$ = $1; }
    | F_LIT                   { $$ = $1; }
    | CHAR_LIT                { $$ = $1; }
    ;
