%%----------------------------------------------------
%% 红包商店
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(shop_redbag).
-behaviour(gen_server).
-export([start_link/0
        ,reload/0
        ,get_shop_status/0
        ,get_shop_items/0
        ,exchange/3
        ,reload/1
    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        start_time = 0
        ,end_time = 0
        ,items = []
        ,status = 0    %% 0未开启，1开启
        ,num = 0
        ,all_num = 0
    }
).

-record(shop_item, {
        id = 0
        ,type = 0
        ,price = 0
        ,num = 1
        ,need_num = 1
        ,start_time = 0
        ,end_time = 0
    }
).

-define(shop_start_time, date:datetime_to_seconds({2018, 9, 15, 0, 0, 0})).
-define(shop_end_time, date:datetime_to_seconds({2018, 9, 16, 0, 0, 0})).
-define(shop_items, [
        #shop_item{id = 1, type = gold, price = 200, need_num = 2000}
        ,#shop_item{id = 2, type = tel_fare, price = 100, need_num = 1000}
        ,#shop_item{id = 3, type = jd_card, price = 200, need_num = 2000}
        ,#shop_item{id = 4, type = jd_card, price = 500, need_num = 5000}
        ,#shop_item{id = 5, type = red_bag, price = 10, need_num = 100}
        ,#shop_item{id = 6, type = red_bag, price = 50, need_num = 500}
        ,#shop_item{id = 7, type = red_bag, price = 100, need_num = 1000}
        ,#shop_item{id = 8, type = red_bag, price = 500, need_num = 5000}
        ,#shop_item{id = 9, type = red_bag, price = 1000, need_num = 10000}
    ]).



-include("common.hrl").
-include("role.hrl").
-include("all_pb.hrl").
-include("error_msg.hrl").

%% 重载商店
reload() ->
    ?MODULE ! reload.

reload(?setting_shop_redbag) ->
    ?MODULE ! reload;
reload(_) -> ok.


%% 获取商店状态
get_shop_status() ->
    case catch gen_server:call(?MODULE, status) of
        {ok, StartTime, EndTime, Status, Num, AllNum} -> {StartTime, EndTime, Status, Num, AllNum};
        _ -> {0, 0, 0, 0, 0}
    end.

%% 获取商店物品列表
get_shop_items() ->
    case catch gen_server:call(?MODULE, get_items) of
        {ok, Items} -> 
            to_p_shop_item(Items);
        _ -> []
    end.

to_p_shop_item(List) -> 
    [#p_shop_item{id = Id, type = Type, price = Price, need_num = Need}||#shop_item{id = Id, type = Type, price = Price, need_num = Need} <-List].

%% 兑换物品
exchange(Role = #role{role_id = RoleId}, Id, Phone) ->
    case catch gen_server:call(?MODULE, {exchange, Id}) of
        {ok, Type, Price, Need} ->
            role_lib:send_buff_begin(),
            case role_lib:do_cost(Role, [{red_bag, Need}]) of
                {ok, NewRole} ->
                    Flow = functions_mgr:get_exchange_flow(), %% 元
                    case Flow >= Price of
                        true ->
                            case do_exchange(NewRole, Type, Price, Phone, Need) of
                                {ok, NewRole1} -> 
                                    log_db:log(shop_exchange_log, insert, [RoleId, 3, Need, type_to_integer(Type), Price, date:unixtime()]),
                                    functions_mgr:delete_exchange_flow(Price),
                                    role_lib:send_buff_flush(),
                                    {ok, NewRole1};
                                {false, Reason} -> 
                                    case Type of
                                        red_bag -> 
                                            ?MODULE ! {add_num, Need};
                                        _ ->
                                            ok
                                    end,
                                    role_lib:send_buff_clean(),
                                    {false, Reason}
                            end;
                        _ ->
                            case Type of
                                red_bag -> 
                                    ?MODULE ! {add_num, Need};
                                _ ->
                                    ok
                            end,
                            role_lib:send_buff_clean(),
                            {false, ?error_exchange_flow}
                    end;
                {false, Reason} ->
                    case Type of
                        red_bag -> 
                            ?MODULE ! {add_num, Need};
                        _ ->
                            ok
                    end,
                    role_lib:send_buff_clean(),
                    {false, Reason}
            end;
        {false, Reason} ->
            {false, Reason};
        _ ->
            {false, ?error_busy}
    end.

type_to_integer(jd_card) -> 1;
type_to_integer(tel_fare) -> 2;
type_to_integer(gold) -> 3;
type_to_integer(red_bag) -> 4;
type_to_integer(_) -> 0.

%% 进行兑换
do_exchange(Role, gold, Price, _, _) ->
    role_lib:do_add_gold(Role, Price * 10);
do_exchange(Role = #role{role_id = RoleId, exchange = Exchange, channel = Channel}, tel_fare, Price, Phone, Need) ->
    case lib_juhe:check_phone(Phone, Price) of
        true ->
            OrderID = lists:concat([tel, RoleId, date:unixtime()]),
            case lib_juhe:direct_recharge(Phone, Price, OrderID) of
                true ->
                    Now = date:unixtime(),
                    mail_mgr:send(0, RoleId, "兑换好礼", util:fbin("恭喜成功为手机号：~ts 充值~w元话费", [Phone, Price]), [], Now),
                    log_db:log(phone_card, insert, [RoleId, 5, Need, Phone, Price, Now]),
                    case Channel of
                        0 -> ok;
                        _ ->
                            db:exec("insert into channel_exchange_log(channel_id, role_id, exchange, type, time) value(?, ?, ?, ?, ?)", [Channel, RoleId, Price * 100, 1, Now])
                    end,
                    {ok, Role#role{exchange = Exchange + Price * 100}};
                _ ->
                    {false, ?error_busy}
            end;
        _ ->
            {false, ?error_phone}
    end;
do_exchange(Role = #role{role_id = RoleId, exchange = Exchange, channel = Channel}, jd_card, Price, _, Need) ->
    Now = date:unixtime(),
    OrderID = lists:concat([jd, RoleId, Now]),
    case lib_juhe:jd_card(Price, OrderID) of
        {ok, Cami} ->
            mail_mgr:send(0, RoleId, "兑换好礼", util:fbin("恭喜成功兑换~w京东礼品卡:~n ~ts", [Price, Cami]), [], Now),
            log_db:log(jd_card, insert, [RoleId, 5, Need, Cami, Price, Now]),
            case Channel of
                0 -> ok;
                _ ->
                    db:exec("insert into channel_exchange_log(channel_id, role_id, exchange, type, time) value(?, ?, ?, ?, ?)", [Channel, RoleId, Price * 100, 2, Now])
            end,
            {ok, Role#role{exchange = Exchange + Price * 100}};
        _R -> 
            {false, ?error_busy}
    end;
do_exchange(Role, red_bag, _Price, _, Need) ->
    case role_lib:reward_red_bag(Role, Need * 10) of
        {ok, NewRole} ->
            {ok, NewRole};
        {false, _R} ->
            {false, _R}
    end.


%%mail_mgr:send(0, 1014583, "兑换好礼", util:fbin("恭喜成功兑换~w京东礼品卡:~n ~ts", [50, "0461-57DE-246E-1405"]), [], 1543128740).
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ?INFO("[~w] 正在启动", [?MODULE]),
    process_flag(trap_exit, true),
    {Start, End, Items, Num, AllNum} = do_reload(),
    NewState = do_init(#state{start_time = Start, end_time = End, items = Items, num = Num, all_num = AllNum}),
    erlang:send_after(date:next_diff(0, 0, 1) * 1000, self(), flush),
    ?INFO("[~w] 启动完成", [?MODULE]),
    {ok, NewState}.

handle_call(status, _From, State = #state{start_time = Start, end_time = End, status = Status, num = Num, all_num = AllNum}) ->
    {reply, {ok, Start, End, Status, Num, AllNum}, State};

handle_call(get_items, _From, State = #state{items = Items}) ->
    {reply, {ok, Items}, State};
handle_call(get_items, _From, State) ->
    {reply, {false, ?error_shop_status}, State};


handle_call({exchange, Id}, _From, State = #state{items = Items, num = Num}) ->
    case lists:keyfind(Id, #shop_item.id, Items) of
        #shop_item{type = Type = red_bag, price = Price, need_num = Need} when Num >= Need->
            {reply, {ok, Type, Price, Need}, State#state{num = Num - Need}};
        #shop_item{type = Type, price = Price, need_num = Need} ->
            {reply, {ok, Type, Price, Need}, State};
        _ ->
            {reply, {false, ?error_shop_item}, State}
    end;


handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(reload, State) ->
    {Start, End, Items, Num, AllNum} = do_reload(),
    NewState = do_init(State#state{start_time = Start, end_time = End, items = Items, num = Num, all_num = AllNum}),
    {noreply, NewState};

handle_info(stop, State) ->
    Items = [ Item || Item = #shop_item{type = redbag}<-?shop_items],
    {noreply, State#state{status = 0, items = Items}};
handle_info(start, State) ->
    save_setting(State),
    {noreply, State#state{status = 1, items = ?shop_items}};

%% 聚合兑换失败返回数量
handle_info({add_num, Num}, State = #state{num = Num1}) ->
    {noreply, State#state{num = Num + Num1}};

handle_info(flush, State) ->
    case setting_mgr:get(?setting_redbag_exchange_num) of
        {ok, {_Now, All}} ->
            setting_mgr:set(?setting_redbag_exchange_num, {All, All});
        _ -> ok
    end,
    erlang:send_after(date:next_diff(0, 0, 1) * 1000, self(), flush),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    ?INFO("正在关闭~w......", [?MODULE]),
    save_setting(State),
    ?INFO("~w关闭完成", [?MODULE]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 保存设置
save_setting(#state{start_time = Start, end_time = End, num = Num, all_num = AllNum}) ->
    setting_mgr:set(?setting_shop_redbag, {Start, End, Num, AllNum}),
    case setting_mgr:get(?setting_redbag_exchange_num) of
        {ok, {Now, All}} ->
            setting_mgr:set(?setting_redbag_exchange_num, {Now - AllNum + Num, All});
        _ ->
            ok
    end.



%% 重新加载活动
do_reload() ->
    case setting_mgr:get(?setting_shop_redbag) of
        {ok, {Start, End, Num, AllNum}} ->
            case setting_mgr:get(?setting_redbag_exchange_num) of
                {ok, {Now, _}} ->
                    {Start, End, ?shop_items, min(Now, Num), AllNum};
                _ ->
                    {Start, End, ?shop_items, min(0, Num), AllNum}
            end;
        _ ->
            {?shop_start_time, ?shop_end_time, ?shop_items, 0, 0}
   end.

%% 初始化
do_init(State = #state{start_time = Start, end_time = End}) ->
    Now = date:unixtime(),
    case get(start_time) of
        Ref1 when is_reference(Ref1)->
            erlang:cancel_timer(Ref1);
        _ ->
            ok
    end,
    case get(end_time) of
        Ref0 when is_reference(Ref0)->
            erlang:cancel_timer(Ref0);
        _ ->
            ok
    end,
    if Now < Start ->
            Ref = erlang:send_after((Start - Now) * 1000, self(), start),
            put(start_time, Ref),
            Ref2 = erlang:send_after((End - Now) * 1000, self(), stop),
            put(end_time, Ref2),
            Items = [ Item || Item = #shop_item{type = Type}<-?shop_items, Type =/= red_bag],
            State#state{status = 0, items = Items};
        Now >= Start andalso Now =< End ->
            Ref = erlang:send_after((End - Now) * 1000, self(), stop),
            put(end_time, Ref),
            State#state{status = 1};
        true ->
            Items = [ Item || Item = #shop_item{type = Type}<-?shop_items, Type =/= red_bag],
            State#state{status = 0, items = Items}
    end.




