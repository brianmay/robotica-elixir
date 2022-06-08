Definitions.
W = [a-zA-Z0-9_]

Rules.
%% a number
[0-9]+ : {token, {number, TokenLine, list_to_integer(TokenChars)}}.
%% a word
{W}+ : {token, {word, TokenLine, list_to_binary(TokenChars)}}.
%% open/close parens
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
%% arithmetic operators
\+ : {token, {'+', TokenLine}}.
\- : {token, {'-', TokenLine}}.
\* : {token, {'*', TokenLine}}.
\/ : {token, {'/', TokenLine}}.
\% : {token, {'%', TokenLine}}.
%% white space
[\s\n\r\t]+           : skip_token.

Erlang code.
