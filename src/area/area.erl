%%----------------------------------------------------
%% 竞技场处理进程
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(area).
-behaviour(gen_server).
-export([start_link/1
        ,hit/2
        ,use_item/2
        ,out_room/1
        ,reconnect/1
        ,apply_reward/2
        ,enter_area/2
    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        id = 0
        ,type = 0
        ,role_list = []
        ,animal_list = []
        ,num = 1
        ,skill = []
        ,pre_list = []
        ,start_time = 0
    }
).

-record(area_role, {
        role_id = 0
        ,type = 0   %% 0人物1机器人
        ,name = ""
        ,pid
        ,socket_pid
        ,score = 0
        ,num = 300
        ,skill_id = []
    }
).


-include("common.hrl").
-include("animal.hrl").
-include("role.hrl").
-include("all_pb.hrl").
-include("error_msg.hrl").

-define(area_pre, 1.1).

start_link(List) ->
    gen_server:start_link(?MODULE, [List], []).


%% 打动物
hit(_Role = #role{role_id = RoleId, status = ?status_area, room_pid = Pid}, Id) when is_pid(Pid)->
    Pid ! {hit, role, RoleId, Id};
hit(_, _) ->
    {false, ?error_act}.


%% 使用技能
use_item(Role = #role{role_id = RoleId, status = ?status_area, room_pid = Pid, skill_list = List}, Item) when is_pid(Pid)->
    case lists:keyfind(Item, #role_skill.type, List) of
        false ->
            case is_process_alive(Pid) of
                true ->
                    role_lib:send_buff_begin(),
                    case check_item_num(Role, Item) of
                        {ok, NewRole} ->
                            case catch gen_server:call(Pid, {use_item, RoleId, Item}) of
                                ok ->
                                    role_lib:send_buff_flush(),
                                    {ok, NewRole};
                                {ok, Skill} ->
                                    role_lib:send_buff_flush(),
                                    Now = date:unixtime(),
                                    do_skill(Skill, Now),
                                    {ok, NewRole#role{skill_list = [Skill | List]}};
                                {false, Reason} ->
                                    role_lib:send_buff_clean(),
                                    {false, Reason};
                                _ ->
                                    role_lib:send_buff_clean(),
                                    {false, ?error_busy}
                            end;
                        {false, Reason} ->
                            {false, Reason}
                    end;
                _ ->
                    {false, ?error_act}
            end;
        _ ->
            {false, ?error_act}
    end;
use_item(_, _) ->
    {false, ?error_act}.

%% 技能处理
do_skill(#role_skill{type = Type, end_time = Time}, Now) when Time > Now->
    erlang:send_after((Time - Now) * 1000, self(), {delete_skill, Type});
do_skill(_, _) -> ok.


%% 退出房间
out_room(Role = #role{role_id = RoleID, status = ?status_area, room_pid = Pid}) when is_pid(Pid)->
    Pid ! {out, RoleID},
    {ok, Role#role{room_pid = undefined, room_type = 0, status = ?status_normal}};
out_room(Role) -> {ok, Role}.


%% 断线重连进来
reconnect(Role = #role{role_id = RoleId, status = ?status_area, room_pid = Pid, socket_pid = SocketPid}) when is_pid(Pid) ->
    case is_process_alive(Pid) of
        true -> 
            case catch gen_server:call(Pid, {reconnect, RoleId, SocketPid}) of
                {ok, Data} ->
                    {ok, Data};
                _ ->
                    {false, ?error_act, Role#role{status = ?status_normal, room_pid = undefined, room_type = 0}}
            end;
        _ -> 
            {false, ?error_act, Role#role{status = ?status_normal, room_pid = undefined, room_type = 0}}
    end;
reconnect(_Role) ->  
    {false, ?error_act}.


init([List]) ->
    process_flag(trap_exit, true),
    RoleList = do_init(List, [], 0),
    erlang:send_after(3000, self(), start),
    push_role_list(RoleList, RoleList),
    {ok, #state{role_list = RoleList}}.


%% 玩家使用道具
handle_call({use_item, RoleId, Item}, _From, State = #state{role_list = RoleList, skill = SkillList}) ->
    case lists:keyfind(RoleId, #area_role.role_id, RoleList) of
        Role = #area_role{skill_id = IdList} ->
            case lists:member(Item, IdList) of
                true ->
                    {reply, {false, ?error_item_use}, State};
                _ ->
                    case lists:member(Item, SkillList) of
                        true ->
                            {reply, {false, ?error_item_repeat}, State};
                        _ ->
                            case do_use_skill(Role, Item, State) of
                                {ok, NewState} ->
                                    {reply, ok, NewState};
                                {ok, Reply, NewState} ->
                                    {reply, Reply, NewState};
                                {false, Reason} ->
                                    {reply, {false, Reason}, State}
                            end
                    end
            end;
        _ ->
            {reply, {false, ?error_act}, State}
    end;

%% 断线重连
handle_call({reconnect, RoleId, SocketPid}, _From, State = #state{role_list = RoleList, animal_list = AnimalList, start_time = Start}) ->
    case lists:keyfind(RoleId, #area_role.role_id, RoleList) of
        Role = #area_role{} ->
            Now = date:unixtime(),
            case Now - Start >180 of
                true ->
                    self() ! stop,
                    {reply, false, State};
                _ ->
                    Time = 180 - (Now - Start),
                    NewList = lists:keyreplace(RoleId, #area_role.role_id, RoleList, Role#area_role{socket_pid = SocketPid}),
                    NewList1 = to_p_area_role(RoleList),
                    NewList2 = to_p_animal(AnimalList),
                    Data = #m_1518_toc{animals = NewList2, role_list = NewList1, time = Time},
                    {reply, {ok, Data}, State#state{role_list = NewList}}
            end;
        _ ->
            {reply, false, State}
    end;



handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 打动物
handle_info({hit, Type, RoleId, Id},State = #state{role_list = RoleList, animal_list = AnimalList}) ->
    case lists:keyfind(RoleId, #area_role.role_id, RoleList) of
        Role = #area_role{num = Num, score = Score} when Num > 0-> 
            Coin = if Num =< 100 ->
                    20;
                Num =< 200 ->
                    15;
                true ->
                    10
            end,
            case lists:keyfind(Id, #animal_base.id, AnimalList) of
                Animal = #animal_base{} ->
                    push_hit(RoleId, Id, RoleList),
                    case do_hit(Animal, AnimalList, Coin, Type) of
                        {Win, HitList, NewAnimalList, Skill,  CreateNum} ->
                            push_die(HitList, Skill, RoleId, RoleList),
                            NewRoleLlist = lists:keyreplace(RoleId, #area_role.role_id, RoleList, Role#area_role{num = Num - 1, score = Score + Win}),
                            NewState = init_animal(CreateNum, State#state{animal_list = NewAnimalList, role_list = NewRoleLlist}),
                            {noreply, NewState};
                        _ ->
                            NewList = lists:keyreplace(RoleId, #area_role.role_id, RoleList, Role#area_role{num = Num - 1}),
                            {noreply, State#state{role_list = NewList}}
                    end;
                _ ->
                    {noreply,  State}
            end;
        _ ->
            {noreply, State}
    end;

%% 检查动物是否走出去
handle_info(check_animal_out, State = #state{animal_list = List, role_list = RoleList}) ->
    {NewAnimal, OutAnimal, CreateNum} = do_animal_out(List, [], [], 0),
    push_animal_out(OutAnimal, RoleList),
    NewState = init_animal(CreateNum, State#state{animal_list = NewAnimal}),
    erlang:send_after(1000, self(), check_animal_out),
    {noreply, NewState};


%% 玩家退出
handle_info({out, RoleId}, State = #state{role_list = List}) ->
    NewList = lists:keydelete(RoleId, #area_role.role_id, List),
    case [1 || #area_role{type = 0} <-List] of
        [] ->
            [Pid ! stop||#area_role{type = 1, pid = Pid} <-List],
            {stop, normal, State#state{role_list = NewList}};
        _ ->
            push_out(RoleId, NewList),
            {noreply, State#state{role_list = NewList}}
    end;

%% 新的动物加进来
handle_info({add_animal, Animal}, State = #state{role_list = RoleList, animal_list = AnimalList, pre_list = PreList}) ->
    push_animal_enter([Animal], RoleList),
    List1 = lists:delete(Animal, PreList),
    {noreply, State#state{animal_list = [Animal | AnimalList], pre_list = List1}};


%% 删除技能
%% 全局 号角
handle_info({delete_skill, Item = horn}, State = #state{skill = Skill}) ->
    NewSkill = lists:delete(Item, Skill),
    {noreply, State#state{skill = NewSkill}};

%% 删除技能
%% 私有
handle_info({delete_skill, RoleId, Item}, State = #state{role_list = RoleList}) ->
    case lists:keyfind(RoleId, #area_role.role_id, RoleList) of
        Role = #area_role{skill_id = Skill} ->
            push_delete_skill(RoleId, Item, RoleList),
            NewList = lists:keyreplace(RoleId, #area_role.role_id, RoleList, Role#area_role{skill_id = lists:keydelete(Item, #role_skill.type, Skill)}),
            {noreply, State#state{role_list = NewList}};
        _ ->
            {noreply, State}
    end;

%% 关闭房间
handle_info(stop, State) ->
    {stop, normal, State};

%% 延迟处理使用
handle_info(use_horn, State) ->
    NewState = init_one_animal(elephant, State, horn),
    {noreply, NewState};


%% 开始推送动物
handle_info(start, State = #state{role_list = RoleList}) ->
    push_animal_list([], 180, RoleList),
    erlang:send_after(4000, self(), start_animal),
    erlang:send_after(180000, self(), reward),
    {noreply, State#state{start_time = date:unixtime()}};

handle_info(start_animal, State) ->
    NewState  = do_init(State),
    erlang:send_after(1000, self(), check_animal_out),
    {noreply, NewState};

%% 发奖励
handle_info(reward, State = #state{role_list = RoleList}) ->
    Rank = lists:reverse(lists:keysort(#area_role.score, RoleList)),
    push_rank_reward(to_p_area_role(Rank), RoleList),
    do_rank_reward(Rank, 1),
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 发奖励并且推出
do_rank_reward([], _) -> ok;
do_rank_reward([#area_role{type = 0, pid = Pid} | L], Num)->
    role:apply(async, Pid, {?MODULE, apply_reward, [Num]}),
    do_rank_reward(L, Num + 1);
do_rank_reward([#area_role{pid = Pid} | L], Num) ->
    Pid ! stop,
    do_rank_reward(L, Num + 1).

%% 回调发奖励并且推出
apply_reward(Role, N) ->
    Coin =  case N of
        1 -> 10000;
        2 -> 5000;
        3 -> 2000;
        _ -> 0
    end,
    case N =:= 0 of
        true -> 
            {ok, Role#role{status = ?status_normal, room_pid = undefined}};
        _ ->
            {ok, NewRole} = role_lib:do_add_coin(Role, Coin),
            account_mgr:output(?area_coin, Coin),
            area_account_mgr:reward(Coin),
            {ok, NewRole#role{status = ?status_normal, room_pid = undefined}}
    end.


%% 推送排行奖励
push_rank_reward(Rank, RoleList) ->
    [sys_conn:pack_send(Pid, 1516, #m_1516_toc{list = Rank})||#area_role{socket_pid = Pid, type = 0} <-RoleList].


%% 推送有玩家推出
push_out(RoleId, List) ->
    [sys_conn:pack_send(Pid, 1508, #m_1508_toc{role_id = RoleId})||#area_role{socket_pid = Pid, type = 0} <-List].



%% 推送匹配成功列表
push_role_list(RoleList, RoleList) ->
    Data = to_p_area_role(RoleList),
    [sys_conn:pack_send(Pid, 1507, #m_1507_toc{role_list = Data})||#area_role{socket_pid = Pid, type = 0} <-RoleList].

%% 推送动物列表
push_animal_list(List, Time, RoleList) ->
    [sys_conn:pack_send(Pid, 1513, #m_1513_toc{animal_list = List, time = Time})||#area_role{socket_pid = Pid, type = 0} <-RoleList].



%% 推送玩家点击
push_hit(RoleId, Id, List) ->
    [sys_conn:pack_send(Pid, 1505, #m_1505_toc{role_id = RoleId, id = Id})||#area_role{socket_pid = Pid, type = 0} <-List].

%% 推送动物死亡
push_die(HitList, Skill, RoleId, RoleList) ->
    List = to_p_animal_die(HitList),
    Data = #m_1509_toc{role_id = RoleId, type = Skill, ids = List},
    [sys_conn:pack_send(Pid, 1509, Data)||#area_role{socket_pid = Pid} <- RoleList].

%% 推送动物进入
push_animal_enter([], _List) -> ok;
push_animal_enter(PushList, List) ->
    NewList = to_p_animal(PushList),
    [sys_conn:pack_send(Pid, 1506, #m_1506_toc{animals = NewList})||#area_role{socket_pid = Pid} <-List].

%% 推送动物走出
push_animal_out([], _List) -> ok;
push_animal_out(PushList, List) ->
    [sys_conn:pack_send(Pid, 1511, #m_1511_toc{id = [ Id || #animal_base{id = Id}<-PushList]})||#area_role{socket_pid = Pid} <-List].

%% 推送预警
push_pre_animal(BaseId, List) ->
    [sys_conn:pack_send(Pid, 1510, #m_1510_toc{base_id = BaseId})||#area_role{socket_pid = Pid, type = 0} <-List].

%% 推送使用技能
push_use_skill(RoleId, Icon, Item, List) ->
    [sys_conn:pack_send(Pid, 1512, #m_1512_toc{role_id = RoleId, type = Item, icon = Icon})||#area_role{socket_pid = Pid, type = 0} <-List].

%% 推送技能消失
push_delete_skill(RoleId, Item, List) ->
    [sys_conn:pack_send(Pid, 1514, #m_1514_toc{id = RoleId, type = Item})||#area_role{socket_pid = Pid, type = 0} <-List].


%% 初始化
do_init([], List, 5) -> 
    List;
do_init([], List, N) -> 
    Robot = do_init_robot(),
    do_init([], [Robot | List], N + 1);
do_init([Id | L], List, N) -> 
    case role_data:get_online_role(Id) of
        {ok, #online_role{name = Name, pid = Pid, socket_pid = SocketPid}} ->
            role:apply(async, Pid, {?MODULE, enter_area, [self()]}),
            do_init(L, [#area_role{role_id = Id, name = Name, pid = Pid, socket_pid = SocketPid} | List], N + 1);
        _ ->
            do_init(L, List, N)
    end.

enter_area(Role, Pid) ->
    {ok, Role#role{status = ?status_area, room_pid = Pid}}.
  
%% 人数不够创建机器人
do_init_robot() -> 
    Id = sys_rand:rand(1000000, 20000000),
    {ok, Pid} = robot_mgr:start_area_robot(Id, self()),
    #area_role{role_id = Id, pid = Pid, socket_pid = Pid, type = 1, name = lists:concat(["游客", Id])}.

%% 初始化房间
do_init(State) ->
    init_animal(20, State).


%% 批量产生动物
init_animal(0, State) -> State;
init_animal(N, State = #state{animal_list = List, role_list = RoleList, num = Num, pre_list = PreList}) ->
    {PushList, NewList, NewNum, PreList1} = init_animal(N, [], List, Num, RoleList, PreList),
    push_animal_enter(PushList, RoleList),
    NewState = State#state{animal_list = NewList, num = NewNum, pre_list = PreList1},
    NewState.


%% 初始化线路
init_animal(0, List1, List, Num, _, PreList) -> {List1, List, Num, PreList};
init_animal(N, List1, List, Num, RoleList, PreList) ->
    Animal = #animal_base{base_id = BaseId} = get_one_annimal(PreList ++ List),
    #animal_route{id = RouteId, time = AllTime, post = Post, xy = XY} = init_animal_route(),
    case lists:member(BaseId, ?animal_pre_notice_list) of
        true ->
            NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = 0, route_id = RouteId, xy = XY},
            push_pre_animal(BaseId, RoleList),
            erlang:send_after(3000, self(), {add_animal, NewAnimal}),   %% 预警动物之后再加载
            init_animal(N -1, List1, List, Num + 1, RoleList, [NewAnimal | PreList]);
        _ ->
            NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = Post, route_id = RouteId, xy = XY},
            init_animal(N -1, [NewAnimal | List1], [NewAnimal| List], Num + 1, RoleList,  PreList)
    end.

%% 指定产出一种动物
init_one_animal(BaseId, State = #state{animal_list =  List, role_list = RoleList, num = Num, pre_list = PreList}, Horn) ->
    case lists:keyfind(BaseId, #animal_base.base_id, get_animal_base()) of
        Animal = #animal_base{} ->
            #animal_route{id = RouteId, time = AllTime, post = Post, xy = XY} = init_animal_route(),
            case lists:member(BaseId, ?animal_pre_notice_list) of
                true ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = 0, route_id = RouteId, is_horn = Horn, xy = XY},
                    push_pre_animal(BaseId, RoleList),
                    erlang:send_after(3000, self(), {add_animal, NewAnimal}),   %% 预警动物之后再加载
                    State#state{num  = Num + 1, pre_list = [NewAnimal | PreList]};
                _ ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = Post, route_id = RouteId, is_horn = Horn, xy = XY},
                    push_animal_enter([NewAnimal], RoleList),
                    State#state{num = Num + 1, animal_list = [NewAnimal | List]}
            end;
        _ ->
            State
    end.


%% 随机产生一只动物 只允许一只动物在场上
get_one_annimal(List) ->
    OnlyList = [Id || #animal_base{base_id = Id} <- List, lists:member(Id, ?animal_only_one_list)],
    NewList = [A||A = #animal_base{base_id = Id} <-get_animal_base(), not lists:member(Id, OnlyList)],
    sys_rand:rand_list(NewList, #animal_base.pre).


%% 动物是否走出去了
do_animal_out([], NewAnimal, OutAnimal, CreateNum) -> {NewAnimal, OutAnimal, CreateNum};
do_animal_out([Animal = #animal_base{route_id = Id, end_time = _End, post = Pos, status = 0, is_horn = Horn} | L], NewAnimal, OutAnimal, CreateNum) ->
    case animal:get_xy(Id, Pos + 1) of
        {0, 0} ->
            Num = case Horn of
                0 -> 1;
                _ -> 
                    self() ! {delete_skill, Horn},
                    0
            end,
            do_animal_out(L, NewAnimal, [Animal#animal_base{post = Pos + 1} | OutAnimal], CreateNum + Num);
        XY ->
            do_animal_out(L, [Animal#animal_base{post = Pos + 1, xy = XY} | NewAnimal], OutAnimal, CreateNum)
    end;
do_animal_out([Animal | L], NewAnimal, OutAnimal, CreateNum) ->
    do_animal_out(L, [Animal | NewAnimal], OutAnimal, CreateNum).


%% 初始化单个线路
init_animal_route() ->
    Id = sys_rand:rand_list(animal_route:get_all()),
    Post = sys_rand:rand(1, 5),
    XY = animal:get_xy(Id, Post),
    #animal_route{id = Id, post = Post, xy = XY}.


%% 转换前端数据
to_p_area_role(List) when is_list(List)->
    [to_p_area_role(Role) || Role <-List];
to_p_area_role(#area_role{role_id = RoleId, name = Name,  skill_id = SkillId, score = Score, num = Num}) ->
    Now = date:unixtime(),
    #p_area_role{role_id = RoleId, name = Name, score = Score, num = Num, skill_list = [#p_skill{type = Type, effect = Effect, time = max(0, Time - Now)}|| #role_skill{type = Type, effect = Effect, end_time = Time} <- SkillId]}.

to_p_animal(List) when is_list(List) ->
    [to_p_animal(Animal) || Animal <-List];
to_p_animal(#animal_base{id = Id, base_id = BaseId, route_id = LineId, post = Point, status = Status, red_bag = RedBag}) ->
    #p_animal{id = Id, base_id = BaseId, line_id = LineId, point = Point, status = Status, red_bag = RedBag}.

to_p_animal_die(List) when is_list(List) ->
    [to_p_animal_die(Animal) || Animal <-List];
to_p_animal_die(#animal_base{id = Id, win = Win}) ->
    #p_animal_die{id = Id, item_list = [#p_assets{type = coin, num = Win}]}.


%% 是否打爆
%% 特殊处理皮卡丘和炸弹人
do_hit(Animal = #animal_base{base_id = pikachu},  AnimalList, Coin, Type) ->
    NewList = lists:delete(Animal, AnimalList),
    {Win, Rate, NewAnimalList, AnimalList1, CreateNum} = do_hit_pikachu([Animal | NewList], 0, 0, [], AnimalList, 0, Coin),
    case do_rate(Rate/10, Type) of
        true ->
            {Win, NewAnimalList, AnimalList1, 1, CreateNum};
        _ ->
            false
    end;
do_hit(_Animal = #animal_base{base_id = bomber},  AnimalList, Coin, Type) ->
    {Win, Rate, NewAnimalList, CreateNum} = do_hit_bomber(AnimalList, 0, 0, [], 0, Coin),
    case do_rate(Rate/10, Type) of
        true ->
            {Win, NewAnimalList, [], 2, CreateNum};
        _ ->
            false
    end;
do_hit(Animal = #animal_base{rate = [Min, Max], is_horn = Horn}, AnimalList, Coin, Type) ->
    Rate = sys_rand:rand(Min, Max),
    case do_rate(Rate/10, Type) of
        true ->
            Win = trunc(Coin * Rate/10),
            NewList = lists:delete(Animal, AnimalList),
            CreateNum = case Horn of
                0 -> 1;
                _ -> 
                    self() ! {delete_skill, Horn},
                    0
            end,
            {Win, [Animal#animal_base{win = Win}], NewList, 0, CreateNum};
        _ ->
            false
    end.

%% 根据倍率计算是否打中 true | false
do_rate(Rate)->
    N = sys_rand:rand(?animal_rand_num),
    Pre = 1/Rate * ?area_pre,
    Num = Pre * ?animal_rand_num,
    N =< Num.


%% 根据倍率计算是否打中 true | false
do_rate(Rate, Type)->
    Pre1 = case Type of
        role -> 1;
        _ -> 1.5
    end,
    N = sys_rand:rand(?animal_rand_num),
    Pre = 1/Rate * ?area_pre,
    Num = Pre * Pre1 * ?animal_rand_num,
    N =< Num.

%% 计算皮卡丘闪电技能,最多打150倍动物
do_hit_pikachu([], Rate, Win, List, AnimalList, CreateNum, _Coin) -> {Win, Rate, List, AnimalList, CreateNum};
do_hit_pikachu([_Animal = #animal_base{rate = [0, 0]} | L], Rate, AllWin, List, AnimalList, CreateNum, Coin) -> 
    do_hit_pikachu(L, Rate, AllWin, List,  AnimalList, CreateNum, Coin);
do_hit_pikachu([Animal = #animal_base{rate = [N, N], is_horn = Horn} | L], Rate, AllWin, List, AnimalList, CreateNum, Coin) -> 
    case N + Rate < 1500 of
        true ->
            Win = trunc(N * Coin/10),
            AddNum = case Horn of
                0 -> 1;
                _ -> 
                    self() ! {delete_skill, Horn},
                    0
            end,
            do_hit_pikachu(L, Rate + N, Win + AllWin, [Animal#animal_base{win = Win} | List], lists:delete(Animal, AnimalList), CreateNum + AddNum, Coin);
        _ ->
            {AllWin, Rate, List, AnimalList, CreateNum}
    end;
do_hit_pikachu([Animal = #animal_base{rate = [Min, Max], is_horn = Horn} | L], Rate, AllWin, List, AnimalList, CreateNum, Coin) -> 
    N = sys_rand:rand(Min, Max),
    case N + Rate < 1500 of
        true ->
            Win = trunc(N * Coin/10),
            AddNum = case Horn of
                0 -> 1;
                _ -> 
                    self() ! {delete_skill, Horn},
                    0
            end,
            do_hit_pikachu(L, Rate + N, Win + AllWin, [Animal#animal_base{win = Win} | List], lists:delete(Animal, AnimalList), CreateNum + AddNum, Coin);
        _ ->
            {AllWin, Rate, List, AnimalList, CreateNum}
    end.


%% 打中炸弹人
do_hit_bomber([], Rate, Win, List, CreateNum, _Coin)-> {Win, Rate, List, CreateNum};
do_hit_bomber([Animal = #animal_base{rate = [Rate, Rate], is_horn = Horn} | L], N, AllWin, List, CreateNum, Coin)-> 
    Win = trunc(Rate * Coin/10),
    AddNum = case Horn of
        0 -> 1;
        _ -> 
            self() ! {delete_skill, Horn},
            0
    end,
    do_hit_bomber(L, N + Rate, Win + AllWin, [Animal#animal_base{win = Win} | List], CreateNum + AddNum, Coin);
do_hit_bomber([Animal = #animal_base{rate = [Min, Max], is_horn = Horn} | L], N, AllWin, List, CreateNum, Coin)-> 
    Rate = sys_rand:rand(Min, Max),
    Win = trunc(Rate * Coin/10),
    AddNum = case Horn of
        0 -> 1;
        _ -> 
            self() ! {delete_skill, Horn},
            0
    end,
    do_hit_bomber(L, N + Rate, Win + AllWin, [Animal#animal_base{win = Win} | List], CreateNum + AddNum, Coin).


%% 检查道具是否足够, 不足够用钻石代替
check_item_num(#role{vip = Vip}, horn) when Vip < 5->
    {false, ?error_act};
check_item_num(Role, Item) when Item =:= horn orelse Item =:= locking ->
    case role_lib:do_cost(Role, [{Item, 1}]) of
        {ok, NewRole} ->
            {ok, NewRole};
        _ ->
            Gold = get_item_gold(Item),
            role_lib:do_cost_gold(Role, Gold)
    end;
check_item_num(_, _) ->
    {false, ?error_act}.

%% 获取道具价格
get_item_gold(ice) -> 2;
get_item_gold(horn) -> 2;
get_item_gold(rage) -> 20;
get_item_gold(trumpet) -> 20;
get_item_gold(locking) -> 2;
get_item_gold(auto) -> 50.

%% 处理动物园使用技能效果
%% 全屏的
%% 号角
do_use_skill(_Role = #area_role{role_id = RoleId, name = Name}, Item = horn, State = #state{role_list = RoleList, animal_list = AnimalList, skill = Skill, pre_list = List}) ->
    case lists:keyfind(elephant, #animal_base.base_id, List ++ AnimalList) of
        false ->
            push_use_skill(RoleId, Name, Item, RoleList),
            erlang:send_after(2000, self(), use_horn),
            {ok, State#state{skill = [Item | Skill]}};
        _ ->
            {false, ?error_horn}
    end;
%% 私有的
%% 锁定
do_use_skill(Role = #area_role{role_id = RoleId, skill_id = Skill, name = Name}, Item = locking, State = #state{role_list = RoleList}) ->
    Now = date:unixtime(),
    NewSkill = #role_skill{type = Item, end_time =  Now + 30},
    NewList = lists:keyreplace(RoleId, #area_role.role_id, RoleList, Role#area_role{skill_id = [NewSkill | Skill]}),
    push_use_skill(RoleId, Name, Item, RoleList),
    {ok, {ok, NewSkill}, State#state{role_list = NewList}};
do_use_skill(_, _, _State) -> {false, ?error_act}.


%% 路线基本配置
get_animal_route() ->
    [
        #animal_route{id = 1, time = 36}
        ,#animal_route{id = 2, time = 36}
        ,#animal_route{id = 3, time = 40}
        ,#animal_route{id = 4, time = 36}
        ,#animal_route{id = 5, time = 42}
        ,#animal_route{id = 6, time = 36}
        ,#animal_route{id = 7, time = 38}
        ,#animal_route{id = 8, time = 36}
        ,#animal_route{id = 9, time = 40}
        ,#animal_route{id = 10, time = 40}
        ,#animal_route{id = 11, time = 36}
        ,#animal_route{id = 12, time = 40}
        ,#animal_route{id = 14, time = 40}
        ,#animal_route{id = 14, time = 36}
        ,#animal_route{id = 15, time = 34}
        ,#animal_route{id = 16, time = 42}
        ,#animal_route{id = 17, time = 34}
        ,#animal_route{id = 18, time = 30}
        ,#animal_route{id = 19, time = 36}
        ,#animal_route{id = 20, time = 38}
        ,#animal_route{id = 21, time = 34}
        ,#animal_route{id = 22, time = 34}
        #animal_route{id = 23, time = 36}
        ,#animal_route{id = 24, time = 36}
        ,#animal_route{id = 25, time = 40}
        ,#animal_route{id = 26, time = 36}
        ,#animal_route{id = 27, time = 42}
        ,#animal_route{id = 28, time = 36}
        ,#animal_route{id = 29, time = 38}
        ,#animal_route{id = 30, time = 36}
        ,#animal_route{id = 31, time = 40}
        ,#animal_route{id = 32, time = 40}
        ,#animal_route{id = 33, time = 36}
        ,#animal_route{id = 34, time = 40}
        ,#animal_route{id = 35, time = 40}
        ,#animal_route{id = 36, time = 36}
        ,#animal_route{id = 37, time = 34}
        ,#animal_route{id = 38, time = 42}
        ,#animal_route{id = 39, time = 34}
        ,#animal_route{id = 40, time = 30}
        ,#animal_route{id = 41, time = 36}
        ,#animal_route{id = 42, time = 38}
        ,#animal_route{id = 43, time = 34}
        ,#animal_route{id = 44, time = 34}

    ].
 
%% 动物基本配置
get_animal_base() ->
    [
        #animal_base{base_id = turtle,   name = "乌龟", rate = [8, 15],        pre = 2000}
        ,#animal_base{base_id = cock,    name = "小鸡", rate = [12, 12],       pre = 1500}
        ,#animal_base{base_id = dog,     name = "小狗", rate = [20, 20],       pre = 1500}
        ,#animal_base{base_id = monkey,  name = "猴子", rate = [40, 40],       pre = 1500}
        ,#animal_base{base_id = horse,   name = "马",   rate = [60, 60],       pre = 1500}
        ,#animal_base{base_id = ox,      name = "奶牛", rate = [100, 100],     pre = 1000}
        ,#animal_base{base_id = panda,   name = "熊猫", rate = [200, 200],     pre = 800,  item_list = []}
        ,#animal_base{base_id  = hippo,  name = "河马", rate = [1000, 1000],   pre = 500,  item_list = []}
        ,#animal_base{base_id = lion,    name = "狮子", rate = [2000, 2000],   pre = 300,  item_list = []}
        ,#animal_base{base_id = elephant,name = "大象", rate = [10000, 10000], pre = 50,  item_list = []}
        ,#animal_base{base_id = pikachu, name = "皮卡丘", rate = [500, 500],     pre = 500, item_list = []}
        ,#animal_base{base_id = bomber,  name = "炸弹人", rate = [0, 0],         pre = 50}
    ].



%%L = {[6639345320769292243,3608770094660354196,
%%  742243046379662650],
%% [18120842820157533730,8126736957674970839,
%%  15838874456159170949,13720667785623009027,
%%  1981124648388646073,7259762199281454546,4847305429977657164,
%%  7414450875285544033,16891263586416558696,
%%  5656958901809990669,7119686310873009186,1196684206413867236,
%%  5825020388346195561]}.
%%{_, P} = test:get_role(168192, event_pid).
%%gen_server:cast(P, {mfa_without_state, {test, info , [L, 1]}}).

