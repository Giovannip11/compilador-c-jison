%{
/* ==========================================================================
   SEMÂNTICA & CÓDIGO INTERMEDIÁRIO (PARTE 3) - VERSÃO COM SUPORTE A FUNÇÕES
   ========================================================================== */
var escopoAtual = 0;
var tabelaSimbolos = {}; 
var tac = [];            
var erros = [];          
var tempCont = 0;        

function criarNo(tipo, valor, esquerda = null, direita = null) {
    return { tipo: tipo, valor: valor, esquerda: esquerda, direita: direita };
}

function buscarTipo(id) {
    if (tabelaSimbolos[id]) {
        return tabelaSimbolos[id].tipo;
    }
    return null;
}

function processarExpressao(no) {
    if (!no) return null;

    if (no.tipo === 'NUM') return { tipo: 'int', resultado: no.valor };
    if (no.tipo === 'FLOAT') return { tipo: 'float', resultado: no.valor };
    
    if (no.tipo === 'ID') {
        let t = buscarTipo(no.valor);
        if (!t) {
            erros.push(" Erro semântico: Variável não declarada -> " + no.valor);
            return { tipo: null, resultado: no.valor };
        }
        return { tipo: t, resultado: no.valor };
    }

    let esq = processarExpressao(no.esquerda);
    let dir = processarExpressao(no.direita);

    if (!esq || !dir || !esq.tipo || !dir.tipo) return { tipo: null, resultado: null };

    if (esq.tipo !== dir.tipo) {
        erros.push(" Erro de tipo: Operação inválida entre " + esq.tipo + " e " + dir.tipo);
        return { tipo: null, resultado: null };
    }

    tempCont++;
    let novoTemp = "T" + tempCont;
    
    tac.push(novoTemp + " = " + esq.resultado + " " + no.valor + " " + dir.resultado);

    return { tipo: esq.tipo, resultado: novoTemp };
}
%}

%lex
%%

\s+                     /* ignora espaços e quebras de linha */
"//".* /* ignora comentários de linha */
"/*"([^*]|\*+[^*/])*\*+"/" /* ignora comentários de bloco */

/* Diretivas de pré-processador */
\#include[ \t]*\<[^>\n]+\>           return 'INCLUDE';
\#include[ \t]*\"[^"\n]+\"           return 'INCLUDE';
\#define[ \t]+[a-zA-Z_][a-zA-Z0-9_]* return 'DEFINE';

"if"                    return 'IF';
"else"                  return 'ELSE';
"while"                 return 'WHILE';
"for"                   return 'FOR';

"int"                   return 'INT_TYPE';
"float"                 return 'FLOAT_TYPE';
"char"                  return 'CHAR_TYPE';

"=="                    return 'COMP_OP';
"!="                    return 'COMP_OP';
"<="                    return 'COMP_OP';
">="                    return 'COMP_OP';
"="                     return '=';
"<"                     return '<';
">"                     return '>';
"+"                     return '+';
"-"                     return '-';
"*"                     return '*';
"/"                     return '/';

"("                     return '(';
")"                     return ')';
"{"                     { escopoAtual++; return '{'; } 
"}"                     { escopoAtual--; return '}'; } 
";"                     return ';';
","                     return ',';

[0-9]+\.[0-9]+          { yytext = Number(yytext); return 'FLOAT'; }
[0-9]+                  { yytext = Number(yytext); return 'NUM'; }

[a-zA-Z_][a-zA-Z0-9_]* return 'ID';

.                       { throw new Error("Caractere inválido: " + yytext); }

<<EOF>>                 return 'EOF';

/lex

%start programa

/* Definição de Precedência de Operadores */
%left '+' '-'
%left '*' '/'
%left '<' '>' 'COMP_OP'
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

programa
    : diretivas comandos EOF
    {
        $$ = { tipoNode: 'PROGRAMA', diretivas: $1, comandos: $2 };

        console.log("\n==================================================");
        console.log("Análise Sintática e Semântica Concluída!");
        console.log("==================================================");
        
        console.log("\n Tabela de Símbolos Final:");
        console.table(tabelaSimbolos);

        console.log("\n Código de Três Endereços (TAC) Gerado:");
        if (tac.length > 0) {
            tac.forEach(linha => console.log("   " + linha));
        } else {
            console.log("   (Nenhum código gerado devido a erros ou ausência de atribuições)");
        }

        if (erros.length > 0) {
            console.log("\n Erros Semânticos Detectados:");
            erros.forEach(err => console.log("   " + err));
        } else {
            console.log("\n Sucesso Semântico: 0 erros detectados!");
        }

        return $$; 
    }
    | diretivas EOF
    { 
        $$ = { tipoNode: 'PROGRAMA', diretivas: $1, comandos: [] };
        return $$;
    }
    ;

diretivas
    : diretivas diretiva    { $$ = $1.concat([$2]); }
    | /* vazio */           { $$ = []; }
    ;

diretiva
    : INCLUDE   { $$ = { tipoNode: 'INCLUDE', valor: yytext }; }
    | DEFINE    { $$ = { tipoNode: 'DEFINE', valor: yytext }; }
    ;

comandos
    : comandos comando      { $$ = $1.concat([$2]); }
    | comando               { $$ = [$1]; }
    ;

comando
    : funcao            { $$ = $1; }
    | declaracao        { $$ = $1; }
    | atribuicao        { $$ = $1; }
    | if_stmt           { $$ = $1; }
    | while_stmt        { $$ = $1; }
    | for_stmt          { $$ = $1; }
    | bloco             { $$ = $1; }
    ;

/* Suporte para assinaturas de função como int main() */
funcao
    : tipo ID '(' ')' bloco
    {
        $$ = { tipoNode: 'FUNCAO', retorno: $1, nome: $2, corpo: $5 };
        console.log(" Encontrou declaração de função: " + $2);
    }
    ;

declaracao
    : tipo ID ';'
    {
        $$ = { tipoNode: 'DECLARACAO_SIMPLES', tipo: $1, id: $2 };
        if (tabelaSimbolos[$2]) {
            erros.push(" Erro: Variável '" + $2 + "' já declarada.");
        } else {
            tabelaSimbolos[$2] = { tipo: $1, escopo: escopoAtual };
        }
    }
    /* Suporte para ponteiros simples como: int *arr; */
    | tipo '*' ID ';'
    {
        $$ = { tipoNode: 'DECLARACAO_PONTEIRO', tipo: $1 + '*', id: $3 };
        if (tabelaSimbolos[$3]) {
            erros.push(" Erro: Variável '" + $3 + "' já declarada.");
        } else {
            tabelaSimbolos[$3] = { tipo: $1 + '*', escopo: escopoAtual };
        }
    }
    | tipo ID '=' expressao ';'
    {
        $$ = { tipoNode: 'DECLARACAO_INICIALIZADA', tipo: $1, id: $2, expressao: $4 };
        if (tabelaSimbolos[$2]) {
            erros.push(" Erro: Variável '" + $2 + "' já declarada.");
        } else {
            tabelaSimbolos[$2] = { tipo: $1, escopo: escopoAtual };
            let resExpressao = processarExpressao($4);
            if (resExpressao && resExpressao.tipo) {
                if ($1 !== resExpressao.tipo) {
                    erros.push(" Erro de Tipo: Não é possível inicializar '" + $1 + "' com '" + resExpressao.tipo + "'");
                } else {
                    tac.push($2 + " = " + resExpressao.resultado);
                }
            }
        }
    }
    ;

atribuicao
    : ID '=' expressao ';'
    {
        $$ = { tipoNode: 'ATRIBUICAO', id: $1, expressao: $3 };
        let tipoVariavel = buscarTipo($1);
        if (!tipoVariavel) {
            erros.push(" Erro Semântico: Variável não declarada -> " + $1);
        } else {
            let resExpressao = processarExpressao($3);
            if (resExpressao && resExpressao.tipo) {
                if (tipoVariavel !== resExpressao.tipo) {
                    erros.push(" Erro de Atribuição: Incompatibilidade de tipos em " + $1);
                } else {
                    tac.push($1 + " = " + resExpressao.resultado);
                }
            }
        }
    }
    ;

if_stmt
    : IF '(' expressao ')' comando %prec LOWER_THAN_ELSE
        { $$ = { tipoNode: 'IF', condicao: $3, corpoIf: $5 }; }
    | IF '(' expressao ')' comando ELSE comando
        { $$ = { tipoNode: 'IF_ELSE', condicao: $3, corpoIf: $5, corpoElse: $7 }; }
    ;

while_stmt
    : WHILE '(' expressao ')' comando
        { $$ = { tipoNode: 'WHILE', condicao: $3, corpo: $5 }; }
    ;

for_stmt
    : FOR '(' ID '=' expressao ';' expressao ';' expressao ')' comando
        { 
            $$ = { 
                tipoNode: 'FOR', 
                inicializacao: { tipoNode: 'ATRIBUICAO_FOR', id: $3, expressao: $5 }, 
                condicao: $7, 
                incremento: $9, 
                corpo: $11 
            }; 
        }
    ;

bloco
    : '{' comandos '}'
        { $$ = { tipoNode: 'BLOCO_CODIGO', comandos: $2 }; }
    ;

tipo
    : INT_TYPE     { $$ = 'int'; }
    | FLOAT_TYPE   { $$ = 'float'; }
    | CHAR_TYPE    { $$ = 'char'; }
    ;

expressao
    : expressao '+' expressao   { $$ = criarNo('OP', '+', $1, $3); }
    | expressao '-' expressao   { $$ = criarNo('OP', '-', $1, $3); }
    | expressao '*' expressao   { $$ = criarNo('OP', '*', $1, $3); }
    | expressao '/' expressao   { $$ = criarNo('OP', '/', $1, $3); }
    | expressao '>' expressao   { $$ = criarNo('OP', '>', $1, $3); }
    | expressao '<' expressao   { $$ = criarNo('OP', '<', $1, $3); }
    | expressao COMP_OP expressao { $$ = criarNo('OP', $2, $1, $3); }
    | '(' expressao ')'         { $$ = $2; }
    | NUM                       { $$ = criarNo('NUM', $1); }
    | FLOAT                     { $$ = criarNo('FLOAT', $1); }
    | ID                        { $$ = criarNo('ID', $1); }
    ;
