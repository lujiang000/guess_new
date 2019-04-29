%%----------------------------------------------------
%% @doc 竞技场协议入库
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(area_rpc).
-export([
        handle/3
    ]).

-include("common.hrl").
-include("role.hrl").
-include("all_pb.hrl").

%% 报名
handle(1501, _Data, Role = #role{status = ?status_normal}) ->
    case role_lib:get_value(Role, ?daily_area_free) >= 6 of
        true ->
            Coin = 2000, 
            case role_lib:do_cost_coin(Role, Coin) of
                {ok, NewRole} ->
                    area_mgr:sign_up(NewRole),
                    area_account_mgr:sign_up(Coin),
                    NewRole1 = role_lib:add_value(NewRole, ?daily_area_free),
                    {ok, #m_1501_toc{}, NewRole1};
                {false, Reason} ->
                    {false, Reason}
            end;
        _ ->
            area_mgr:sign_up(Role),
            area_account_mgr:sign_up(0),
            NewRole = role_lib:add_value(Role, ?daily_area_free),
            {ok, #m_1501_toc{}, NewRole}
    end;

%% 退出
handle(1502, _Data, Role) ->
    {ok, NewRole} = area:out_room(Role),
    {ok, #m_1502_toc{}, NewRole};

%% 打动物
handle(1503, #m_1503_tos{id = Id}, Role = #role{hit_num = Num}) ->
    area:hit(Role, Id),
    {ok, #m_1503_toc{}, Role#role{hit_num = Num + 1}};

%% 使用道具
handle(1504, #m_1504_tos{type = Type}, Role) ->
    case area:use_item(Role, Type) of
        {ok, NewRole} ->
            {ok, #m_1504_toc{}, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;

%% 获取 次数
handle(1515, _, Role) ->
    Value = role_lib:get_value(Role, ?daily_area_free),
    {reply, #m_1515_toc{num = Value}};

%% 断线重连
handle(1518, _, Role) ->
    case area:reconnect(Role) of
        {ok, Data} ->
            {reply, Data};
        {false, Reason, NewRole} ->
            {false, Reason, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;


handle(_Cmd, _Data, _Role) ->
    ?ERR("错误的协议数据cmd:~w,data:~w", [_Cmd, _Data]),
    ok.

