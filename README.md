# erl_eval_records
Erlang library for using records in erl_eval. Without extra manipulation you can not use records in interpret by `erl_eval` code. To solve this problems in erlang shell some magic is done.

This magic consist of:
 * fetching records definitions
 * copy it a fake module
 * add fake function with code than needs to be run
 * replace records in this code to tuples
 * extract result code from fake function

Interface of this simple helper module contains functions represented 2 phases:
 * `load/1` (or `load_all/1`) to load record information from module(s) with records
 * `expand/2` expand records in given expressions


```erlang
-record(test, {a}).

test() ->
  {ok, Tokens  , _} = erl_scan:string("#foo{a=A} = {foo, 0}, A."),
  {ok, Exprs      } = erl_parse:parse_exprs(Tokens),
  NewExprs          = erl_eval_records:expand(erl_eval_records:load(?MODULE), Exprs),
  {value, Value, _} = erl_eval:exprs(NewExprs, []),
  ?assertEqual(Value, 0).
```
