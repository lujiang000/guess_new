%%----------------------------------------------------
%% 竞技场统计系统
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(area_account_mgr).
-behaviour(gen_server).
-export([start_link/0
        ,sign_up/1
        ,reward/1
        ,save/0
        ,get_account/0
    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").
-record(state, {
        all_num = 0   %% 所有报名次数
        ,free_num = 0  %% 免费次数
        ,pay_num = 0   %% 付费次数
        ,coin = 0      %% 消耗金币
        ,reward = 0    %% 奖励
        ,time = 0      %% 时间 0点
    }
).


%% 报名
sign_up(Coin) ->
    ?MODULE ! {sign_up, Coin}.

%% 奖励
reward(Coin) ->
    ?MODULE ! {reward, Coin}.

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

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ?INFO("[~w] 正在启动", [?MODULE]),
    process_flag(trap_exit, true),
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


%% 报名
handle_info({sign_up, 0}, State = #state{all_num = All, free_num = Free}) ->
    {noreply, State#state{all_num = All + 1, free_num = Free + 1}};
handle_info({sign_up, Coin}, State = #state{all_num = All, pay_num = Pay, coin = AllCoin}) ->
    {noreply, State#state{all_num = All + 1, pay_num = Pay + 1, coin = AllCoin + Coin}};

%% 奖励
handle_info({reward, Coin}, State = #state{reward = Reward}) ->
    {noreply, State#state{reward = Reward + Coin}};

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
    case db:get_row("select * from area_log where time = ?", [Time]) of
        {ok, [AllNum, Free, Pay, Coin, Reward, Time]} ->
            #state{all_num = AllNum, free_num = Free, pay_num = Pay, coin = Coin, reward = Reward, time = Time};
        _ ->
            #state{time = Time}
    end.

%% 入库
save(#state{all_num = AllNum, free_num = Free, pay_num = Pay, coin = Coin, reward = Reward, time = Time}) -> 
    case db:get_row("select id from area_log where time = ?", [Time]) of
        {ok, [Id]} ->
            db:exec("replace into area_log(id, all_num, free_num, pay_num, pay_coin, reward, time) values (?, ?, ?, ?, ?, ?, ?)", [Id, AllNum, Free, Pay, Coin, Reward, Time]);
        _ ->
            db:exec("insert into area_log(all_num, free_num, pay_num, pay_coin, reward, time) values (?, ?, ?, ?, ?, ?)", [AllNum, Free, Pay, Coin, Reward, Time])
    end.


