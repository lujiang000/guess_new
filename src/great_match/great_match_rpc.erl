%%----------------------------------------------------
%% @doc 大奖赛协议入口
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(great_match_rpc).
-export([handle/3]).

-include("common.hrl").
-include("role.hrl").
-include("animal.hrl").
-include("all_pb.hrl").
-include("error_msg.hrl").

%% 进入大奖赛
handle(2001, _, Role = #role{great_match = #great_match{num = Num, once_score = Score}}) ->
    case great_match_mgr:enter_room(Role) of
        {ok, Data, NewRole} ->
            {ok, Data#m_2001_toc{num = Num, score = Score}, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

%% 退出大奖赛
handle(2002, _, Role = #role{great_match = Great}) ->
    case great_match:out_room(Role) of
        {ok, NewRole} ->
            {ok, #m_2002_toc{}, task:do_task_over(NewRole#role{great_match = Great#great_match{num = 0}})};
        {false, Reason} ->
            {false, Reason}
    end;

%% 打动物
handle(2003, #m_2003_tos{id = Id, coin = Coin}, Role) ->
    case great_match:hit(Role, Id, Coin) of
        {ok, NewRole = #role{great_match = #great_match{num = Num, once_score = Score}}} ->
            {ok, #m_2003_toc{num = Num, score = Score}, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

%% 使用道具技能
handle(2004, #m_2004_tos{type = Type}, Role) ->
    case great_match:use_item(Role, Type) of
        {ok, NewRole} ->
            {ok, #m_2004_toc{}, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

%% 获取大奖赛信息
handle(2015, _, _Role = #role{great_match = #great_match{num = Num, daily_times = Times, week_score = WeekScore, daily_score = Score}}) ->
    case great_match_mgr:get_status() of
        {ok, Status} ->
            {reply, #m_2015_toc{week_score = WeekScore, daily_score = Score, times = Times, num = Num, status = Status}};
        {false, Reason} ->
            {false, Reason}
    end;


%% 购买大奖赛魔法
handle(2016, _, Role = #role{use_coin = Max, great_match = Great = #great_match{daily_times = Times, num = 0}}) ->
    case Max >= 16 of
        true ->
            case great_match_mgr:get_status() of
                {ok, 1} ->
                    case role_lib:get_value(Role, ?daily_great_match) >= 1 of
                        true ->
                            Gold = min(500, (Times - 1) * 50),
                            case role_lib:do_cost_gold(Role, Gold) of
                                {ok, NewRole} ->
                                    Num = case Times of
                                        1 -> 1;
                                        _ -> 0
                                    end,
                                    great_account_mgr:add_cost_num(Gold, Num),
                                    {ok, #m_2016_toc{}, NewRole#role{great_match = Great#great_match{daily_times = Times + 1, num = 2000, vip_add = 0, repeat_add = 0, high_add = 0, task_add = 0, base_score = 0, once_score = 0}}};
                                {false, Reason} ->
                                    {false, Reason}
                            end;
                        _ ->
                            NewRole = role_lib:add_value(Role, ?daily_great_match),
                            great_account_mgr:add_free_num(),
                            {ok, #m_2016_toc{}, NewRole#role{great_match = Great#great_match{daily_times = Times + 1, num = 2000, vip_add = 0, repeat_add = 0, high_add = 0, task_add = 0, base_score = 0, once_score = 0}}}
                    end;
                {ok, _} ->
                    {false, ?error_act_time};
                _ ->
                    {false, ?error_busy}
            end;
        _ -> 
            {false, ?error_act}
    end;


%% 获取单次大奖赛信息
handle(2017, _, _Role = #role{great_match = #great_match{daily_score = Score, base_score = BaseScore, vip_add = Vip, high_add = High, repeat_add = Repeat, task_add = Task, once_score = Once}}) ->
    case great_match_mgr:get_status() of
        {ok, Status} ->
            {reply, #m_2017_toc{score = Score, base = BaseScore, vip = Vip, high = High, repeat = Repeat, task = Task, once = Once, status = Status}};
        _ ->
            {reply, #m_2017_toc{score = Score, base = BaseScore, vip = Vip, high = High, repeat = Repeat, task = Task, once = Once, status = 0}}
    end;

%% 断线重连
handle(2018, _, Role = #role{great_match = #great_match{num = Num, once_score = Score}}) ->
    case great_match:reconnect(Role) of
        {ok, Data} ->
            {reply, Data#m_2018_toc{num = Num, score = Score}};
        {false, Reason, NewRole} ->
            {false, Reason, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

%% 使用表情
handle(2021, #m_2021_tos{type = Type, to_id = Id}, Role) ->
    case great_match:use_expression(Role, Type, Id) of
        {ok, NewRole} ->
            {ok, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

handle(_, _DataIn, _Role) ->
    ok.
