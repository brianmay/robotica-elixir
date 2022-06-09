Nonterminals boolean condition expr term factor.
Terminals word number 'and' 'or' '+' '-' '*' '/' '%' '(' ')' '==' '!=' '<' '<=' '>' '>='.
Rootsymbol boolean.

boolean -> condition 'and' condition: {'and', '$1', '$3'}.
boolean -> condition 'or' condition: {'or', '$1', '$3'}.
boolean -> condition: '$1'.

condition -> '(' boolean ')': '$2'.
condition -> expr '==' expr: {eq, '$1', '$3'}.
condition -> expr '!=' expr: {ne, '$1', '$3'}.
condition -> expr '<' expr: {lt, '$1', '$3'}.
condition -> expr '<=' expr: {le, '$1', '$3'}.
condition -> expr '>' expr: {gt, '$1', '$3'}.
condition -> expr '>=' expr: {ge, '$1', '$3'}.

expr -> expr '+' term : {plus, '$1', '$3'}.
expr -> expr '-' term : {minus, '$1', '$3'}.
expr -> term : '$1'.

term -> factor '*' term : {multiply, '$1', '$3'}.
term -> factor '/' term : {divide, '$1', '$3'}.
term -> factor '%' term : {remainder, '$1', '$3'}.
term -> factor : '$1'.

factor -> '(' expr ')' : '$2'.
factor -> word : '$1'.
factor -> number : '$1'.
