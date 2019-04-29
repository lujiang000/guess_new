%%----------------------------------------------------
%% 竞技场管理进程
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(area_mgr).
-behaviour(gen_server).
-export([start_link/0
        ,sign_up/1

    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        role_list = []
    }
).

-include("common.hrl").
-include("role.hrl").

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 进行报名
sign_up(_Role = #role{role_id = RoleId}) ->
    ?MODULE ! {sign_up, RoleId}.


init([]) ->
    ?INFO("[~w] 正在启动", [?MODULE]),
    process_flag(trap_exit, true),
    State = #state{},
    erlang:send_after(5000, self(), match),
    ?INFO("[~w] 启动完成", [?MODULE]),
    {ok, State}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 匹配玩家
handle_info(match, State = #state{role_list = List}) ->
    NewList = do_match(List),
    erlang:send_after(3000, self(), match),
    {noreply, State#state{role_list = NewList}};

handle_info({sign_up, RoleId}, State = #state{role_list = RoleList}) ->
    case lists:member(RoleId, RoleList) of
        true ->
            {noreply, State};
        _ ->
            NewList = lists:reverse([RoleId | lists:reverse(RoleList)]),
            {noreply, State#state{role_list = NewList}}
    end;

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% 匹配玩家，5个玩家一组
do_match([]) -> [];
do_match([A, B, C, D, E | L]) ->
    area:start_link([A, B, C, D, E]),
    do_match(L);
do_match(L) ->
    area:start_link(L),
    [].
