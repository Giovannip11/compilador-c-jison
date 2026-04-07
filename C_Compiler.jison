%{
/* =======================
   SEMÂNTICA (PARTE 2)
======================= */
var tabela = {};
%}

%lex
%%

\s+                     /* ignora espaços */
"//".*
\/\*[^*]*\*+([^/*][^*]*\*+)*\/
\n                      /* ignora quebra de linha */

\#include[^\n]*         return 'INCLUDE';
\#define[^\n]*          return 'DEFINE';

"if"        return 'IF';
"else"      return 'ELSE';
"while"     return 'WHILE';
"for"       return 'FOR';

"int"       return 'INT_TYPE';
"float"     return 'FLOAT_TYPE';
"char"      return 'CHAR_TYPE';

"="         return '=';
"<"         return '<';
">"         return '>';
"+"         return '+';
"-"         return '-';
"*"         return '*';
"/"         return '/';

"("         return '(';
")"         return ')';
"{"         return '{';
"}"         return '}';
";"         return ';';
","         return ',';

[0-9]+\.[0-9]+      { yytext = Number(yytext); return 'FLOAT'; }
[0-9]+              { yytext = Number(yytext); return 'NUM'; }

[a-zA-Z_][a-zA-Z0-9_]*  return 'ID';

.   { throw new Error("Caractere inválido: " + yytext); }

<<EOF>>             return 'EOF';

/lex

%start programa

%left '+' '-'
%left '*' '/'
%left '<' '>'
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

programa
    : diretivas comandos EOF
    {
        console.log("\n✅ Programa reconhecido com sucesso");

        console.log("\n📜 Tabela de símbolos:");
        console.table(tabela);
    }
    | diretivas EOF
    ;

diretivas
    : diretivas diretiva
    | /* vazio */
    ;

diretiva
    : INCLUDE   { console.log("🔹 Encontrou #include"); }
    | DEFINE    { console.log("🔹 Encontrou #define"); }
    ;

comandos
    : comandos comando
    | comando
    ;

comando
    : declaracao
    | atribuicao
    | if_stmt
    | while_stmt
    | for_stmt
    | bloco
    ;

declaracao
    : tipo ID ';'
    {
        if (tabela[$2]) {
            console.log("❌ Erro: variável já declarada ->", $2);
        } else {
            tabela[$2] = $1;
            console.log("🟢 Declaração:", $2, "| tipo:", $1);
        }
    }
    | tipo ID '=' expressao ';'
    {
        if (tabela[$2]) {
            console.log("❌ Erro: variável já declarada ->", $2);
        } else {
            tabela[$2] = $1;

            if ($1 !== $4) {
                console.log("⚠️ Tipo diferente na inicialização:", $1, "=", $4);
            }

            console.log("🟢 Declaração com valor:", $2);
        }
    }
    ;

atribuicao
    : ID '=' expressao ';'
    {
        if (!tabela[$1]) {
            console.log("❌ Erro: variável não declarada ->", $1);
        } else {
            if (tabela[$1] !== $3) {
                console.log("⚠️ Tipo diferente:", tabela[$1], "=", $3);
            }
            console.log("🟡 Atribuição:", $1);
        }
    }
    ;

if_stmt
    : IF '(' expressao ')' comando %prec LOWER_THAN_ELSE
        { console.log("🔵 IF"); }
    | IF '(' expressao ')' comando ELSE comando
        { console.log("🔵 IF-ELSE"); }
    ;

while_stmt
    : WHILE '(' expressao ')' comando
        { console.log("🟣 WHILE"); }
    ;

for_stmt
    : FOR '(' ID '=' expressao ';' expressao ';' expressao ')' comando
        { console.log("🟠 FOR"); }
    ;

bloco
    : '{' comandos '}'
        { console.log("📦 Bloco"); }
    ;

tipo
    : INT_TYPE     { $$ = 'int'; }
    | FLOAT_TYPE   { $$ = 'float'; }
    | CHAR_TYPE    { $$ = 'char'; }
    ;

/* EXPRESSÃO COM TIPO */
expressao
    : expressao '+' expressao   { $$ = 'int'; }
    | expressao '-' expressao   { $$ = 'int'; }
    | expressao '*' expressao   { $$ = 'int'; }
    | expressao '/' expressao   { $$ = 'int'; }
    | expressao '>' expressao   { $$ = 'int'; }
    | expressao '<' expressao   { $$ = 'int'; }
    | '(' expressao ')'         { $$ = $2; }

    | NUM                       { $$ = 'int'; }
    | FLOAT                     { $$ = 'float'; }

    | ID
    {
        if (!tabela[$1]) {
            console.log("❌ Erro: variável não declarada ->", $1);
            $$ = null;
        } else {
            $$ = tabela[$1];
        }
    }
    ;
