%lex

%%

\s+                                 {/* ignorar espaços */}

/* ===== COMENTÁRIOS ===== */
"//".*                              {/* comentário de linha */}
"/*"[^*]*"*"+([^/*][^*]*"*"+)*"/"   {/* comentário de bloco */}

/* ===== DIRETIVAS ===== */
"#include"                          {return 'INCLUDE';}
"#define"                           {return 'DEFINE';}

/* ===== PALAVRAS RESERVADAS ===== */
"auto"      {return 'AUTO';}
"break"     {return 'BREAK';}
"case"      {return 'CASE';}
"char"      {return 'CHAR';}
"const"     {return 'CONST';}
"continue"  {return 'CONTINUE';}
"default"   {return 'DEFAULT';}
"do"        {return 'DO';}
"double"    {return 'DOUBLE';}
"else"      {return 'ELSE';}
"enum"      {return 'ENUM';}
"extern"    {return 'EXTERN';}
"float"     {return 'FLOAT';}
"for"       {return 'FOR';}
"goto"      {return 'GOTO';}
"if"        {return 'IF';}
"int"       {return 'INT';}
"long"      {return 'LONG';}
"register"  {return 'REGISTER';}
"return"    {return 'RETURN';}
"short"     {return 'SHORT';}
"signed"    {return 'SIGNED';}
"sizeof"    {return 'SIZEOF';}
"static"    {return 'STATIC';}
"struct"    {return 'STRUCT';}
"switch"    {return 'SWITCH';}
"typedef"   {return 'TYPEDEF';}
"union"     {return 'UNION';}
"unsigned"  {return 'UNSIGNED';}
"void"      {return 'VOID';}
"volatile"  {return 'VOLATILE';}
"while"     {return 'WHILE';}

/* ===== OPERADORES ===== */
"==" {return 'EQ';}
"!=" {return 'NE';}
">=" {return 'GE';}
"<=" {return 'LE';}
"&&" {return 'AND';}
"\|\|" {return 'OR';}
"++" {return 'INC';}
"--" {return 'DEC';}

"+"  {return '+';}
"-"  {return '-';}
"*"  {return '*';}
"/"  {return '/';}
"%"  {return '%';}
">"  {return '>';}
"<"  {return '<';}
"="  {return '=';}
"!"  {return '!';}

/* ===== DELIMITADORES ===== */
";" {return ';';}
"," {return ',';}
"\(" {return '(';}
"\)" {return ')';}
"\{" {return '{';}
"\}" {return '}';}
"\[" {return '[';}
"\]" {return ']';}

/* ===== LITERAIS ===== */
\"([^\\\"]|\\.)*\"                 {return 'STRING_LIT';}
"'"[^']"'"                         {return 'CHAR_LIT';}
[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?  {return 'F_LIT';}
[0-9]+                            {return 'INT_LIT';}

/* ===== IDENTIFICADOR ===== */
[a-zA-Z_][a-zA-Z0-9_]*            {return 'IDF';}

/* ===== ERRO ===== */
. {console.log("Erro léxico:", yytext);}

/* EOF */
<<EOF>> {return 'EOF';}

%%
/lex

%start programa

%left '+' '-'
%left '*' '/'
%left '>' '<' GE LE EQ NE

%%

programa
    : lista_declaracoes EOF
    ;

lista_declaracoes
    : lista_declaracoes declaracao
    | declaracao
    ;

declaracao
    : declaracao_variavel ';'
    | atribuicao ';'
    | if_stmt
    | loop_stmt
    | switch_stmt
    | include_stmt
    | define_stmt
    ;

/* ===== INCLUDE / DEFINE ===== */

include_stmt
    : INCLUDE '<' IDF '>'
      {console.log("INCLUDE detectado");}
    ;

define_stmt
    : DEFINE IDF valor
      {console.log("DEFINE detectado");}
    ;

/* ===== VARIÁVEL ===== */

declaracao_variavel
    : tipo IDF
      {console.log("Declaração de variável");}
    | tipo IDF '=' expressao
      {console.log("Declaração com inicialização");}
    ;

tipo
    : INT | FLOAT | DOUBLE | CHAR | VOID
    | LONG | SHORT | SIGNED | UNSIGNED
    ;

/* ===== ATRIBUIÇÃO ===== */

atribuicao
    : IDF '=' expressao
      {console.log("Atribuição");}
    ;

/* ===== IF ===== */

if_stmt
    : IF '(' expressao ')' '{' lista_declaracoes '}'
      {console.log("IF");}
    | IF '(' expressao ')' '{' lista_declaracoes '}' ELSE '{' lista_declaracoes '}'
      {console.log("IF ELSE");}
    ;

/* ===== LOOPS ===== */

loop_stmt
    : WHILE '(' expressao ')' '{' lista_declaracoes '}'
      {console.log("WHILE");}
    | DO '{' lista_declaracoes '}' WHILE '(' expressao ')' ';'
      {console.log("DO WHILE");}
    | FOR '(' atribuicao ';' expressao ';' atribuicao ')' '{' lista_declaracoes '}'
      {console.log("FOR");}
    ;

/* ===== SWITCH ===== */

switch_stmt
    : SWITCH '(' IDF ')' '{' case_list '}'
      {console.log("SWITCH");}
    ;

case_list
    : case_list case_item
    | case_item
    ;

case_item
    : CASE valor ':' lista_declaracoes
      {console.log("CASE");}
    | DEFAULT ':' lista_declaracoes
      {console.log("DEFAULT");}
    ;

/* ===== EXPRESSÕES ===== */

expressao
    : expressao '+' expressao
    | expressao '-' expressao
    | expressao '*' expressao
    | expressao '/' expressao
    | expressao '>' expressao
    | expressao '<' expressao
    | expressao GE expressao
    | expressao LE expressao
    | expressao EQ expressao
    | expressao NE expressao
    | '(' expressao ')'
    | valor
    | IDF
    ;

valor
    : INT_LIT
    | F_LIT
    | CHAR_LIT
    | STRING_LIT
    ;
