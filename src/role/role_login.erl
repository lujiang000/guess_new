%%----------------------------------------------------
%% @doc 人物登陆处理
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(role_login).
-export([
        do/1
    ]).

-include("role.hrl").
-include("common.hrl").
-include("rank.hrl").


%% 只处理玩家
do(Role = #role{login_time = Time, role_id = RoleId}) -> 
    Now = date:unixtime(),
    Role1 = case date:is_same_day(Time, Now) of
        true ->
            Role;
        _ ->
            role:do_zero_flush(Role)
    end,
    Role2 = mail_mgr:login(Role1),
    Role3 = do_skill(Role2, Now),
    Role4 = task:login(Role3),
    Role5 = task_mgr:get_task(Role4),
    Role6 = do_vip(Role5),
    Role7 = do_daily_gift(Role6, Now),
    RoleEnd = Role7,
    rank:handle(?rank_coin, RoleEnd),
    rank:handle(?rank_lollipop, RoleEnd),
    boradcast_mgr:login(RoleEnd),
    role_data:sync_online_role(RoleEnd),
    role_account_mgr:login(Role),
    db:exec("update role set off = 0 where role_id = ?", [RoleId]),
    RoleEnd#role{login_time = Now, status = ?status_normal, off = 0, hit_num = 0}.



%% 每日礼包特殊处理, 8点更新
do_daily_gift(Role = #role{daily_gift_flush = Time}, Now) ->
    case Now >= Time + 86400 of
        true ->
            Zero = date:unixtime(zero),
            NewTime = Zero + 8 * 60 * 60,
            Role#role{daily_gift_type = 1, daily_gift_flush = NewTime};
        _ ->
            Role
    end.


%% 登陆处理技能
do_skill(Role = #role{skill_list = SkillList}, Now) ->
    NewList = do_skill(SkillList, Now, []),
    Role#role{skill_list = NewList}.

do_skill([], _, List) -> List;
do_skill([Skill = #role_skill{type = Type, end_time = Time} | L], Now, List) when Now < Time->
    erlang:send_after((Time - Now) * 1000, self(), {delete_skill, Type}),
    do_skill(L, Now, [Skill | List]);
do_skill([_Skill| L], Now, List) ->
    do_skill(L, Now, List).


%% 处理vip值
do_vip(Role = #role{vip_charge = VipCharge}) ->
    Vip = vip:get_lev(VipCharge),
    Role#role{vip = Vip}.
