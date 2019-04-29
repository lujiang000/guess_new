%%----------------------------------------------------
%% 大奖赛数据统计管理系统
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(great_account_mgr).
-behaviour(gen_server).
-export([start_link/0
        ,update_animal_pw/2
        ,get_account/0
        ,change/0
        ,save/0
        ,add_free_num/0
        ,add_cost_num/2
    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        p = 0                  %% 打动物总投入金币
        ,w = 0                 %% 打动物总产出金币
        ,all_num = 0           %% 总报名次数
        ,free_num = 0          %% 免费报名次数
        ,cost_num = 0          %% 消费报名次数
        ,cost_value = 0        %% 消费钻石数量
        ,cost_role_num = 0     %% 消费报名人数
        ,time = 0              %% 时间
    }
).

-include("common.hrl").


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

change() ->
    ?MODULE ! change.

save() ->
    ?MODULE ! save.

%% 后台调用
get_account() ->
    case catch gen_server:call(?MODULE, get_account) of
        {ok, Data} ->
            List1 = record_info(fields, state),
            [_ | List2] = erlang:tuple_to_list(Data),
            lists:zip(List1, List2);
        _ ->
            false
    end.


update_animal_pw(P, W) when is_integer(W)->
    ?MODULE ! {update_animal_pw, P, W};
update_animal_pw(P, List) ->
    W1 = case lists:keyfind(coin, 1, List) of
        {coin, Coin} -> Coin;
        _ -> 0
    end,
    ?MODULE ! {update_animal_pw, P, W1}.

add_free_num() ->
    ?MODULE ! add_free_num.

add_cost_num(Gold, Num) ->
    ?MODULE ! {add_cost_num, Gold, Num}.


init([]) ->
    ?INFO("[~w] 正在启动", [?MODULE]),
    process_flag(trap_exit, true),
    erlang:process_flag(min_bin_vheap_size, 1024*1024),
    erlang:process_flag(min_heap_size, 1024*1024),
    erlang:process_flag(priority, high),
    State = do_init(date:unixtime(zero)),
    erlang:send_after(date:next_diff(0, 0, 1) * 1000, self(), next_day),
    ?INFO("[~w] 启动完成", [?MODULE]),
    {ok, State}.

handle_call(get_account, _From, State) ->
    {reply, {ok, State}, State};

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info({update_animal_pw, P, W}, State = #state{p = P1, w = W1}) ->
    {noreply, State#state{p = P1 + P, w = W1 + W}};

handle_info(add_free_num, State = #state{free_num = FreeNum, all_num = AllNum}) ->
    {noreply, State#state{free_num = FreeNum + 1, all_num = AllNum + 1}};
handle_info({add_cost_num, Gold, Num}, State = #state{cost_num = CostNum, all_num = AllNum, cost_value = Value, cost_role_num = RoleNum}) ->
    {noreply, State#state{cost_num = CostNum + 1, all_num = AllNum + 1, cost_value = Value + Gold, cost_role_num = RoleNum + Num}};

%% 0点入库
handle_info(next_day, State) ->
    save(State),
    erlang:send_after(date:next_diff(0, 0, 1) * 1000, self(), next_day),
    {noreply, #state{time = date:unixtime(zero)}};

handle_info(save, State) ->
    save(State),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    ?INFO("[~w] 正在关闭....", [?MODULE]),
    save(State),
    ?INFO("[~w] 关闭完成", [?MODULE]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

      %% 初始化
do_init(Time) ->
    case db:get_row("select * from great_account_log where time = ?", [Time]) of
        {ok, [_, P, W, AllNum, FreeNum, CostNum, CostValue, CostRoleNum, Time]} ->
            #state{p = P, w = W, all_num = AllNum, free_num = FreeNum, cost_num = CostNum, cost_value = CostValue, cost_role_num = CostRoleNum, time = Time};
        _ ->
            #state{time = Time}
    end.

%% 入库
save(#state{p = P, w = W, all_num = AllNum, free_num = FreeNum, cost_num = CostNum, cost_value = CostValue, cost_role_num = CostRoleNum, time = Time}) -> 
    case db:get_row("select id from great_account_log where time = ?", [Time]) of
        {ok, [Id]} ->
            db:exec("replace into great_account_log(id, p, w, all_num, free_num, cost_num, cost_value, cost_role_num, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", [Id, P, W, AllNum, FreeNum, CostNum, CostValue, CostRoleNum, Time]);
        _ ->
            db:exec("insert into great_account_log(p, w, all_num, free_num, cost_num, cost_value, cost_role_num, time) values (?, ?, ?, ?, ?, ?, ?, ?)", [P, W, AllNum, FreeNum, CostNum, CostValue, CostRoleNum, Time])
    end.



