-module(erl_eval_records).

-export([load/1, load_all/1, expand/2]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-export_type([foo/0]).
-record(foo, {a}).
-type foo() :: #foo{}.
-endif.

-define(fake_func(Anno, Expr), {function, Anno, fake_func, 0, [{clause, Anno, [], [], Expr}]}).

-type forms() :: term().
-type exprs() :: term().

-spec load(module()) ->
  forms().
load(Module) ->
  [Record || Record = {attribute, _, record, _} <- abstract_code(object_code(Module))].

-spec load_all([module()]) ->
  forms().
load_all(Modules) ->
  lists:flatten(lists:map(fun load/1, Modules)).

-spec expand(forms(), exprs()) ->
  exprs().
expand([], Expr) ->
  Expr;
expand(Records, Expr) ->
  Forms = Records ++ [?fake_func(erl_anno:new(1), Expr)],
  ?fake_func(_, NewExpr) = lists:last(erl_expand_records:module(Forms, [strict_record_tests])),
  NewExpr.

%%

-spec object_code(module()) ->
  binary().
object_code(Module) ->
  case code:get_object_code(Module) of
    {_, Binary, _} -> Binary;
    error          -> erlang:error({'object code not found', Module})
  end.

-spec abstract_code(binary()) ->
  forms().
abstract_code(ObjectCode) ->
  {ok, {_, [{abstract_code, AbstractCode}]}} = beam_lib:chunks(ObjectCode, [abstract_code]),
  case AbstractCode of
    {raw_abstract_v1, Forms} -> Forms;
    no_abstract_code         -> erlang:error('no abstract code')
  end.


-ifdef(TEST).

eval_test() ->
  {ok, Tokens  , _} = erl_scan:string("#foo{a=A} = {foo, 42}, A."),
  {ok, Exprs      } = erl_parse:parse_exprs(Tokens),
  NewExprs          = expand(load(?MODULE), Exprs),
  {value, Value, _} = erl_eval:exprs(NewExprs, []),
  ?assertEqual(Value, 42).

-endif.