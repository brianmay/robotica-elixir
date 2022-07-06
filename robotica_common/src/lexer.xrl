Definitions.
W = [a-zA-Z0-9_]
S = [a-zA-Z0-9_:]

Rules.
%% a number
[0-9]+ : {token, {number, TokenLine, list_to_integer(TokenChars)}}.
%% boolean operators
or : {token, {'or'}}.
and : {token, {'and'}}.
not : {token, {'not'}}.
in : {token, {'in'}}.
%% a word
{W}+ : {token, {word, TokenLine, list_to_binary(TokenChars)}}.
%% a string
"{S}+" : {token, {string, TokenLine, strip_quotes(TokenChars)}}.
'{S}+' : {token, {string, TokenLine, strip_quotes(TokenChars)}}.
%% open/close parens
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
%% arithmetic operators
\+ : {token, {'+', TokenLine}}.
\- : {token, {'-', TokenLine}}.
\* : {token, {'*', TokenLine}}.
\/ : {token, {'/', TokenLine}}.
\% : {token, {'%', TokenLine}}.
== : {token, {'==', TokenLine}}.
!= : {token, {'!=', TokenLine}}.
< : {token, {'<', TokenLine}}.
<= : {token, {'<=', TokenLine}}.
> : {token, {'>', TokenLine}}.
>= : {token, {'>=', TokenLine}}.
%% white space
[\s\n\r\t]+           : skip_token.

Erlang code.
strip_quotes(Str) ->
    S = tl(lists:droplast(Str)),
    list_to_binary(S).