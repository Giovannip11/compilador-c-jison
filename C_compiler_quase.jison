/* >>> Gramática Léxica e Semântica Unificada <<< */
%{
var escopo = 0;
var nInt = 0;
var nFloat = 0;
var tabelaSimbolos = []; 
var raiz = null;         
var tipoAtual = "";

function criarSimbolo(tipo, nome) {
    var t = 'i';
    var n = nInt;
    
    if (tipo.toLowerCase().indexOf('float') !== -1 || tipo.toLowerCase().indexOf('double') !== -1) {
        t = 'f';
        n = nFloat++;
    } else {
        nInt++;
    }
    
    var idGerado = "@" + t + n;
    
    tabelaSimbolos.push({
        id: idGerado,
        nome: nome,
        tipo: tipo,
        escopo: escopo
    });
}

function criarNo(valor, tipoNode, esquerda = null, direita = null) {
    return {
        valor: valor,
        tipo: tipoNode,
        escopo: escopo,
        esquerda: esquerda,
        direita: direita,
        proximo: null
    };
}

function adicionarNoRaiz(novoNo) {
    if (raiz !== null) {
        var pos = raiz;
        while (pos.proximo !== null) {
            pos = pos.proximo;
        }
        pos.proximo = novoNo;
    } else {
        raiz = novoNo;
    }
}

function printArvore(no) {
    if (no !== null) {
        var res = "";
        if (no.esquerda) res += printArvore(no.esquerda) + " ";
        res += no.valor;
        if (no.direita) res += " " + printArvore(no.direita);
        return res;
    }
    return "";
}

function printAtomos(no) {
    if (no !== null) {
        var esq = no.esquerda;
        var dir = no.direita;
        
        if (no.tipo === 'ATT') {
            if (dir && (dir.tipo === 'INT_LIT' || dir.tipo === 'F_LIT' || dir.tipo === 'IDF')) {
                console.log(no.valor + " " + esq.valor + " " + dir.valor);
            } else if (dir) {
                printAtomos(dir);
                console.log(no.valor + " " + esq.valor + " *");
            }
        } else if (no.tipo === 'OPC' || no.tipo === 'OPD') {
            if (esq && (esq.tipo === 'INT_LIT' || esq.tipo === 'F_LIT' || esq.tipo === 'IDF')) {
                if (dir && (dir.tipo === 'INT_LIT' || dir.tipo === 'F_LIT' || dir.tipo === 'IDF')) {
                    console.log(no.valor + " " + esq.valor + " " + dir.valor);
                } else if (dir) {
                    printAtomos(dir);
                    console.log(no.valor + " " + esq.valor + " *");
                }
            } else if (esq) {
                if (dir && (dir.tipo === 'INT_LIT' || dir.tipo === 'F_LIT' || dir.tipo === 'IDF')) {
                    printAtomos(esq);
                    console.log(no.valor + " * " + dir.valor);
                } else if (dir) {
                    printAtomos(esq);
                    printAtomos(dir);
                    console.log(no.valor + " * *");
                }
            }
        }
    }
}
%}

%lex
%%

\s+                                 /* ignorar brancos */

/* Diretivas de C */
"#include"[ \t]+"<"[^>\n]+">"        return 'INCLUDE_DIR';
"#include"[ \t]+"\""[^"\n]+"\""      return 'INCLUDE_DIR';
"#"                                 return '#';
"define"                            return 'DEFINE';

/* Tipos */
"int"                               return 'INT';
"double"                            return 'DOUBLE';
"float"                             return 'FLOAT';
"char"                              return 'CHAR';

/* Estruturas de controle */
"if"                                return 'IF';
"else"                              return 'ELSE';
"while"                             return 'WHILE';
"switch"                            return 'SWITCH';
"case"                              return 'CASE';
"break"                             return 'BREAK';
"default"                           return 'DEFAULT';
"var"                               return 'VAR';
"do"                                return 'DO';
"for"                               return 'FOR';

/* Símbolos e Operadores */
"("                                 return '(';
")"                                 return ')';
"*"                                 return '*';
"/"                                 return '/';
"+"                                 return '+';
"-"                                 return '-';
";"                                 return ';';
":"                                 return ':';
"."                                 return '.';
","                                 return ',';
"'"                                 return 'QUOTE';
'"'                                 return 'DQUOTE';
"["                                 return '[';
"]"                                 return ']';

"{"                                 { escopo++; return '{'; }
"}"                                 { escopo--; return '}'; }

/* Operadores Relacionais e Lógicos */
"<="                                return 'LE';
">="                                return 'GE';
"=="                                return 'EQ';
"!="                                return 'NE';
"<"                                 return '<';
">"                                 return '>';
"="                                 return '=';
"||"                                return 'OR';
"!"                                 return 'NOT';
"&&"                                return 'AND';

/* Identificadores e Literais */
[a-zA-Z][a-zA-Z0-9_]* return 'IDF';
[0-9]*\.[0-9]+([eE][+-][0-9]+)?     return 'F_LIT';
[0-9]+                              return 'INT_LIT';

.                                   /* ignorar outros caracteres */
<<EOF>>                             return 'EOF';

/lex

%start programa

/* Precedências para evitar conflitos shift/reduce e loops */
%left OR
%left AND
%left EQ NE LE GE '<' '>'
%left '+' '-'
%left '*' '/'
%right NOT

%%

/* >>> Gramática BNF com os Tokens Corretos <<< */

programa
    : elementos EOF
    {
        console.log("\n--- Tabela de Símbolos Final ---");
        tabelaSimbolos.forEach(function(s) {
            console.log(s.id + ":" + s.nome + ":" + s.tipo + ":" + s.escopo);
        });
        return { tipo: 'PROGRAMA', tabela: tabelaSimbolos };
    }
    ;

elementos
    : elemento elementos
    | /* vazio */
    ;

elemento
    : diretiva
    | declaracao ';'
    | bloco
    | comando_estruturado
    ;

diretiva
    : INCLUDE_DIR
    | '#' DEFINE IDF INT_LIT
    | '#' DEFINE IDF F_LIT
    | '#' DEFINE IDF IDF
    ;

bloco
    : '{' comandos '}'
    {
        console.log("Árvore Sintática do Escopo: " + (escopo + 1) + "\n");
        var atual = raiz;
        while (atual !== null) {
            console.log("Sub-Árvore:");
            console.log(printArvore(atual));
            console.log("\nÁtomos gerados:");
            printAtomos(atual);
            atual = atual.proximo;
            console.log("");
        }
        raiz = null; 
    }
    ;

comandos
    : comando comandos
    | /* vazio */
    ;

comando
    : atribuicao ';'
    | declaracao ';'
    | bloco
    | comando_estruturado
    | BREAK ';'
    ;

comando_estruturado
    : IF '(' condicao ')' comando
    | IF '(' condicao ')' comando ELSE comando
    | WHILE '(' condicao ')' comando
    | DO comando WHILE '(' condicao ')' ';'
    | FOR '(' atribuicao ';' condicao ';' atribuicao ')' comando
    ;

declaracao
    : tipo vars
    ;

tipo
    : INT    { tipoAtual = 'int'; }
    | FLOAT  { tipoAtual = 'float'; }
    | DOUBLE { tipoAtual = 'double'; }
    | CHAR   { tipoAtual = 'char'; }
    ;

vars
    : IDF ',' vars { criarSimbolo(tipoAtual, $1); }
    | IDF          { criarSimbolo(tipoAtual, $1); }
    ;

atribuicao
    : IDF '=' expr
    {
        var r = criarNo("ATT", "ATT");
        r.esquerda = criarNo($1, "IDF");
        r.direita = $3;
        adicionarNoRaiz(r);
    }
    ;

condicao
    : expr meio_comp expr
    | expr
    ;

meio_comp
    : '>' | '<' | GE | LE | NE | EQ | OR | AND
    ;

/* Estrutura matemática estrita de 3 níveis para Árvore (AST) */
expr
    : expr '+' cnj   { $$ = criarNo("+", "OPD", $1, $3); }
    | expr '-' cnj   { $$ = criarNo("-", "OPD", $1, $3); }
    | cnj            { $$ = $1; }
    ;

cnj
    : cnj '*' termo  { $$ = criarNo("*", "OPC", $1, $3); }
    | cnj '/' termo  { $$ = criarNo("/", "OPC", $1, $3); }
    | termo          { $$ = $1; }
    ;

termo
    : '(' expr ')'   { $$ = $2; }
    | IDF             { $$ = criarNo($1, "IDF"); }
    | INT_LIT        { $$ = criarNo($1, "INT_LIT"); }
    | F_LIT          { $$ = criarNo($1, "F_LIT"); }
    ;
