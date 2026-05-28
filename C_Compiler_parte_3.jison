
%{
/* ==========================================================================
   SEMÂNTICA & CÓDIGO INTERMEDIÁRIO (PARTE 3)
   ========================================================================== */
var escopoAtual = 0;
var tabelaSimbolos = {}; // Objeto para busca direta de variáveis e seus tipos [cite: 37, 38]
var tac = [];            // Armazena as instruções do Three Address Code [cite: 33]
var erros = [];          // Armazena erros semânticos de tipo ou escopo [cite: 172]
var tempCont = 0;        // Contador para geração de variáveis temporárias (T1, T2...)

// Fábrica de nós para construir a Árvore Sintática Abstrata (AST) [cite: 2, 4]
function criarNo(tipo, valor, esquerda = null, direita = null) {
    return { tipo: tipo, valor: valor, esquerda: esquerda, direita: direita };
}

// Busca o tipo de uma variável na tabela de símbolos [cite: 63]
function buscarTipo(id) {
    if (tabelaSimbolos[id]) {
        return tabelaSimbolos[id].tipo;
    }
    return null;
}

// Percorre a AST de baixo para cima (Pós-Ordem) para validar tipos e gerar TAC 
function processarExpressao(no) {
    if (!no) return null;

    // Nós folhas: Valores literais [cite: 8]
    if (no.tipo === 'NUM') return { tipo: 'int', resultado: no.valor };
    if (no.tipo === 'FLOAT') return { tipo: 'float', resultado: no.valor };
    
    // Nó folha: Identificador (Variável) [cite: 8]
    if (no.tipo === 'ID') {
        let t = buscarTipo(no.valor);
        if (!t) {
            erros.push(" Erro semântico: Variável não declarada -> " + no.valor);
            return { tipo: null, resultado: no.valor };
        }
        return { tipo: t, resultado: no.valor };
    }

    // Processa recursivamente os filhos da esquerda e da direita [cite: 84, 97]
    let esq = processarExpressao(no.esquerda);
    let dir = processarExpressao(no.direita);

    if (!esq || !dir || !esq.tipo || !dir.tipo) return { tipo: null, resultado: null };

    // Verificação Estrita de Tipos (Exigência do professor: tipos devem ser iguais) [cite: 66, 171]
    if (esq.tipo !== dir.tipo) {
        erros.push(" Erro de tipo: Operação inválida entre " + esq.tipo + " e " + dir.tipo);
        return { tipo: null, resultado: null };
    }

    // Criação de variáveis temporárias para o Código de Três Endereços [cite: 33]
    tempCont++;
    let novoTemp = "T" + tempCont;
    
    // Adiciona a instrução aritmética ao TAC. Ex: T1 = A + B [cite: 33, 85]
    tac.push(novoTemp + " = " + esq.resultado + " " + no.valor + " " + dir.resultado);

    // Retorna o tipo resultante e onde o valor está armazenado temporariamente [cite: 92]
    return { tipo: esq.tipo, resultado: novoTemp };
}
%}

%lex
%%

\s+                     /* ignora espaços */
"//".* /* ignora comentários de linha */
\/\*[^*]*\*+([^/*][^*]*\*+)*\/ /* ignora comentários de bloco */
\n                      /* ignora quebra de linha */

\#include[^\n]* return 'INCLUDE';
\#define[^\n]* return 'DEFINE';

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
"{"         { escopoAtual++; return '{'; } /* Incrementa nível de escopo ao abrir bloco [cite: 60] */
"}"         { escopoAtual--; return '}'; } /* Decrementa nível de escopo ao fechar bloco [cite: 60] */
";"         return ';';
","         return ',';

[0-9]+\.[0-9]+      { yytext = Number(yytext); return 'FLOAT'; }
[0-9]+              { yytext = Number(yytext); return 'NUM'; }

[a-zA-Z_][a-zA-Z0-9_]* return 'ID';

.   { throw new Error("Caractere inválido: " + yytext); }

<<EOF>>             return 'EOF';

/lex

%start programa

/* Definição de Precedência de Operadores */
%left '+' '-'
%left '*' '/'
%left '<' '>'
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

programa
    : diretivas comandos EOF
    {
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
    }
    | diretivas EOF
    ;

diretivas
    : diretivas diretiva
    | /* vazio */
    ;

diretiva
    : INCLUDE   { console.log(" Encontrou #include"); }
    | DEFINE    { console.log(" Encontrou #define"); }
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
        if (tabelaSimbolos[$2]) {
            erros.push(" Erro: Variável '" + $2 + "' já declarada neste programa.");
        } else {
            // Guarda o tipo e o escopo atual na tabela [cite: 45, 63]
            tabelaSimbolos[$2] = { tipo: $1, escopo: escopoAtual };
            console.log(" Declaração simples: " + $2 + " | Tipo: " + $1);
        }
    }
    | tipo ID '=' expressao ';'
    {
        if (tabelaSimbolos[$2]) {
            erros.push(" Erro: Variável '" + $2 + "' já declarada neste programa.");
        } else {
            tabelaSimbolos[$2] = { tipo: $1, escopo: escopoAtual };
            console.log(" Declaração com Inicialização: " + $2);

            // Processa a árvore gerada à direita 
            let resExpressao = processarExpressao($4);

            if (resExpressao && resExpressao.tipo) {
                // Valida se o tipo da expressão casa com o tipo da variável declarada [cite: 66]
                if ($1 !== resExpressao.tipo) {
                    erros.push(" Erro de Tipo: Não é possível inicializar '" + $1 + "' com uma expressão do tipo '" + resExpressao.tipo + "'");
                } else {
                    // Tipos válidos: gera a instrução final de atribuição no TAC [cite: 29, 33]
                    tac.push($2 + " = " + resExpressao.resultado);
                }
            }
        }
    }
    ;

atribuicao
    : ID '=' expressao ';'
    {
        let tipoVariavel = buscarTipo($1);

        if (!tipoVariavel) {
            erros.push(" Erro Semântico: Variável não declarada -> " + $1);
        } else {
            // Avalia e valida a subárvore sintática da expressão [cite: 13, 84]
            let resExpressao = processarExpressao($3);

            if (resExpressao && resExpressao.tipo) {
                // Impede atribuições entre tipos diferentes (ex: int recebendo float) [cite: 66, 171]
                if (tipoVariavel !== resExpressao.tipo) {
                    erros.push(" Erro de Atribuição: Incompatibilidade de tipos. Não é possível atribuir '" + resExpressao.tipo + "' a uma variável '" + tipoVariavel + "' (" + $1 + ")");
                } else {
                    // Sucesso: adiciona o comando final ao Código de Três Endereços [cite: 33, 77]
                    tac.push($1 + " = " + resExpressao.resultado);
                    console.log(" Atribuição processada para: " + $1);
                }
            }
        }
    }
    ;

if_stmt
    : IF '(' expressao ')' comando %prec LOWER_THAN_ELSE
        { console.log(" Processou comando IF"); }
    | IF '(' expressao ')' comando ELSE comando
        { console.log(" Processou comando IF-ELSE"); }
    ;

while_stmt
    : WHILE '(' expressao ')' comando
        { console.log(" Processou comando WHILE"); }
    ;

for_stmt
    : FOR '(' ID '=' expressao ';' expressao ';' expressao ')' comando
        { console.log(" Processou comando FOR"); }
    ;

bloco
    : '{' comandos '}'
        { console.log(" Fechou Bloco de Código"); }
    ;

tipo
    : INT_TYPE     { $$ = 'int'; }
    | FLOAT_TYPE   { $$ = 'float'; }
    | CHAR_TYPE    { $$ = 'char'; }
    ;

/* EXPRESSÕES: CONSTRUÇÃO DA AST (BOTTOM-UP) [cite: 5, 6] */
expressao
    : expressao '+' expressao   { $$ = criarNo('OP', '+', $1, $3); }  /* Nó de Operação [cite: 7, 14] */
    | expressao '-' expressao   { $$ = criarNo('OP', '-', $1, $3); }
    | expressao '*' expressao   { $$ = criarNo('OP', '*', $1, $3); }
    | expressao '/' expressao   { $$ = criarNo('OP', '/', $1, $3); }
    | expressao '>' expressao   { $$ = criarNo('OP', '>', $1, $3); }
    | expressao '<' expressao   { $$ = criarNo('OP', '<', $1, $3); }
    | '(' expressao ')'         { $$ = $2; }
    | NUM                       { $$ = criarNo('NUM', $1); }          /* Nós Folhas Literais [cite: 8] */
    | FLOAT                     { $$ = criarNo('FLOAT', $1); }
    | ID                        { $$ = criarNo('ID', $1); }           /* Nó Folha Identificador [cite: 8] */
    ;
