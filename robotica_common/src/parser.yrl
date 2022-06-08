Nonterminals expr term factor.
Terminals word number '+' '-' '*' '/' '%' '(' ')'.
Rootsymbol expr.

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
