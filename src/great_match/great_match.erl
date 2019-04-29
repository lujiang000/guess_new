%%----------------------------------------------------
%% 大奖赛处理进程
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(great_match).
-behaviour(gen_server).
-export([start_link/1
        ,hit/3
        ,use_item/2
        ,out_room/1
        ,reconnect/1
        ,get_xy/2
        ,use_expression/3
        ,apply_out/1

    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        id = 0
        ,type = 0
        ,role_list = []
        ,animal_list = []
        ,num = 0
        ,skill = []
        ,pre_list = []
        ,guide_task = 0
        ,time_end = 0
    }
).

-include("common.hrl").
-include("animal.hrl").
-include("role.hrl").
-include("all_pb.hrl").
-include("rank.hrl").
-include("error_msg.hrl").


-define(great_match_end, 23 * 60 * 60).   %% 23点结束

start_link(Id) ->
    gen_server:start_link(?MODULE, [Id], []).


%% 使用表情
use_expression(Role = #role{role_id = RoleId, status = ?status_great_match, room_pid = Pid}, Type, ToId) when is_pid(Pid) ->
    case role_lib:do_cost_gold(Role, 1) of
        {ok, NewRole} ->
            Pid ! {use_expression, RoleId, Type, ToId},
            {ok, NewRole};
        {false, Reason} ->
            {false, Reason}
    end;
use_expression(_, _, _) ->
    {false, ?error_act}.

%% 打动物
hit(Role = #role{role_id = RoleId, status = ?status_great_match, room_pid = Pid, animal_flag = Flag, great_match = #great_match{num = Num}}, Id, Coin) when is_pid(Pid) andalso Num > 0->
    role_lib:send_buff_begin(),
    case role_lib:do_cost_coin(Role, Coin) of
        {ok, NewRole} ->
            case catch gen_server:call(Pid, {hit, RoleId, Id, Coin, Flag}) of
                {ok, HitList, List, BaseScore} -> 
                    {ok, NewRole1} = role_lib:do_add(NewRole, List),
                    %%NewRole2 = do_bonus(HitList, NewRole1, 0),
                    role_lib:send_buff_flush(),
                    case Flag of
                        99 -> ok;
                        _ ->
                            great_account_mgr:update_animal_pw(Coin, List)
                    end,
               %%     NewRole2 = task:handle(NewRole1, animal_die, HitList),
                    NewRole2 = task:do_fire_task(NewRole1, HitList),
                    NewRole3 = do_calc_score(BaseScore, NewRole2, Coin),
                    %%NewRole4 = do_daily_kill(NewRole3, List),
                    {ok, NewRole3};
                ok ->
                    role_lib:send_buff_flush(),
                    case Flag of
                        99 -> ok;
                        _ ->
                            great_account_mgr:update_animal_pw(Coin, 0)
                    end,
                    NewRole1 = task:do_fire_task(NewRole, []),
                    NewRole2 = do_calc_score(0, NewRole1, Coin),
                    {ok, NewRole2};
                {false, Reason} -> 
                    role_lib:send_buff_clean(),
                    {false, Reason};
                _ -> 
                    role_lib:send_buff_clean(),
                    {false, ?error_busy}
            end;
        _ ->
            role_lib:send_buff_clean(),
            {false, ?error_coin}
    end;
hit(_, _, _) ->
    {false, ?error_act}.


%% 使用技能
use_item(Role = #role{role_id = RoleId, status = ?status_great_match, room_pid = Pid, skill_list = List}, Item) when is_pid(Pid)->
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
                                    NewRole1 = task:handle(NewRole, use_skill, 0, Item),
                                    {ok, NewRole1};
                                {ok, Skill} ->
                                    role_lib:send_buff_flush(),
                                    Now = date:unixtime(),
                                    do_skill(Skill, Now),
                                    NewRole1 = task:handle(NewRole, use_skill, 0, Item),
                                    {ok, NewRole1#role{skill_list = [Skill | List]}};
                                {false, Reason} ->
                                    role_lib:send_buff_clean(),
                                    {false, Reason};
                                _ ->
                                    role_lib:send_buff_clean(),
                                    {false, ?error_busy}
                            end;
                        {false, Reason} ->
                            role_lib:send_buff_clean(),
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
out_room(Role = #role{role_id = RoleID, status = ?status_great_match, room_pid = Pid}) when is_pid(Pid)->
    Pid ! {out, RoleID},
    {ok, Role#role{room_pid = undefined, status = ?status_normal}};
out_room(Role) -> {ok, Role}.


%% 断线重连进来
reconnect(Role = #role{role_id = RoleId, status = ?status_great_match, room_pid = Pid, socket_pid = SocketPid}) when is_pid(Pid) ->
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


init([Id]) ->
    NewState = do_init(#state{id = Id}),
    process_flag(trap_exit, true),
    erlang:send_after(1000, self(), check_animal_out),
    erlang:send_after(date:next_diff(23, 0, 0) * 1000, self(), game_over),
    Zero = date:unixtime(zero),
    {ok, NewState#state{time_end = Zero + ?great_match_end}}.

%% 打动物
handle_call({hit, RoleId, Id, Coin, Flag}, _From, State = #state{role_list = RoleList, animal_list = AnimalList}) ->
    case lists:keyfind(RoleId, #animal_role.role_id, RoleList) of
        _Role = #animal_role{vip = Vip} -> 
            case lists:keyfind(Id, #animal_base.id, AnimalList) of
                Animal = #animal_base{self_id = SelfId} when SelfId =:= 0 orelse SelfId =:= RoleId->
                    push_hit(RoleId, Id, RoleList),
                    case do_hit(Animal, AnimalList, Coin, Vip, Flag, RoleId) of 
                        {HitList, NewAnimalList, Skill, ItemList, CreateNum, BaseScore} ->
                            push_die(HitList, Skill, RoleId, RoleList),
                            NewState = init_animal(CreateNum, State#state{animal_list = NewAnimalList}),
                            %%do_broadcast(Animal, Role, ItemList),
                            {reply, {ok, HitList, ItemList, BaseScore}, NewState};
                        _ ->
                            {reply, ok, State}
                    end;
                #animal_base{} ->
                    {reply, {false, ?error_animal_self}, State};
                _ ->
                    {reply, {false, ?error_animal_exit}, State}
            end;
        _ ->
            {reply, {false, ?error_act}, State}
    end;



%% 玩家使用道具
handle_call({use_item, RoleId, Item}, _From, State = #state{role_list = RoleList, skill = SkillList, type = Type}) ->
    case lists:keyfind(RoleId, #animal_role.role_id, RoleList) of
        Role = #animal_role{skill_id = IdList} ->
            case lists:member(Item, IdList) of
                true ->
                    {reply, {false, ?error_item_use}, State};
                _ ->
                    case lists:member(Item, SkillList) of
                        true ->
                            {reply, {false, ?error_item_repeat}, State};
                        _ ->
                            case Item =:= self_elephant of
                                true ->
                                    case Type =:= rich orelse Type =:= gold orelse Type =:= diamond of
                                        true ->
                                            case do_use_skill(Role, Item, State) of
                                                {ok, NewState} ->
                                                    {reply, ok, NewState};
                                                {ok, Reply, NewState} ->
                                                    {reply, Reply, NewState};
                                                {false, Reason} ->
                                                    {reply, {false, Reason}, State}
                                            end;
                                        _ ->
                                            {reply, {false, ?error_act}, State}
                                    end;
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
                    end
            end;
        _ ->
            {reply, {false, ?error_act}, State}
    end;

%% 玩家进入
handle_call({enter, Role = #animal_role{role_id = RoleId}}, _From, State = #state{role_list = RoleList, animal_list = AnimalList, time_end = End}) ->
    NewList = lists:keystore(RoleId, #animal_role.role_id, RoleList, Role),
    push_in(Role, RoleList),
    NewList1 = to_p_animal_role(NewList),
    NewList2 = to_p_animal(AnimalList),
    Data = #m_2001_toc{animals = NewList2, role_list = NewList1, time = max(0, End - date:unixtime())},
    {reply, {ok, Data}, State#state{role_list = NewList}};

%% 断线重连
handle_call({reconnect, RoleId, SocketPid}, _From, State = #state{role_list = RoleList, animal_list = AnimalList, time_end = End}) ->
    case lists:keyfind(RoleId, #animal_role.role_id, RoleList) of
        Role = #animal_role{} ->
            NewList = lists:keyreplace(RoleId, #animal_role.role_id, RoleList, Role#animal_role{socket_pid = SocketPid}),
            NewList1 = to_p_animal_role(RoleList),
            NewList2 = to_p_animal(AnimalList),
            Data = #m_2018_toc{animals = NewList2, role_list = NewList1, time = max(0, End - date:unixtime())},
            {reply, {ok, Data}, State#state{role_list = NewList}};
        _ ->
            {reply, false, State}
    end;



handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.


%% 检查动物是否走出去
handle_info(check_animal_out, State = #state{animal_list = List, role_list = RoleList}) ->
    {NewAnimal, OutAnimal, CreateNum} = do_animal_out(List, [], [], 0),
    push_animal_out(OutAnimal, RoleList),
    NewState = init_animal(CreateNum, State#state{animal_list = NewAnimal}),
    erlang:send_after(1000, self(), check_animal_out),
    {noreply, NewState};

%% 玩家退出 私人特殊处理
handle_info({out, RoleId}, State = #state{role_list = List, id = Id}) ->
    NewList = lists:keydelete(RoleId, #animal_role.role_id, List),
    push_out(RoleId, NewList),
    great_match_mgr ! {delete_room_num, Id},
    {noreply, State#state{role_list = NewList}};

%% 新手任务触发
handle_info({guide_task, Id}, State = #state{type = single}) ->
    {noreply, State#state{guide_task = Id}};

%% 新的动物加进来
handle_info({add_animal, Animal}, State = #state{role_list = RoleList, animal_list = AnimalList, pre_list = PreList}) ->
    push_animal_enter([Animal], RoleList),
    List1 = lists:delete(Animal, PreList),
    {noreply, State#state{animal_list = [Animal | AnimalList], pre_list = List1}};


%% 删除技能
%% 全局 冰冻
handle_info({delete_skill, Item = ice}, State = #state{animal_list = AnimalList, skill = Skill, role_list = RoleList}) ->
    NewAnimal = [A#animal_base{status = 0}||A = #animal_base{} <-AnimalList],
    NewSkill = lists:delete(Item, Skill),
    pus_animal_status(NewAnimal, RoleList),
    {noreply, State#state{animal_list = NewAnimal, skill = NewSkill}};
%% 全局 号角
handle_info({delete_skill, Item = horn}, State = #state{skill = Skill}) ->
    NewSkill = lists:delete(Item, Skill),
    {noreply, State#state{skill = NewSkill}};

%% 删除技能
%% 私有
handle_info({delete_skill, RoleId, Item}, State = #state{role_list = RoleList}) ->
    case lists:keyfind(RoleId, #animal_role.role_id, RoleList) of
        Role = #animal_role{skill_id = Skill} ->
            push_delete_skill(RoleId, Item, RoleList),
            NewList = lists:keyreplace(RoleId, #animal_role.role_id, RoleList, Role#animal_role{skill_id = lists:keydelete(Item, #role_skill.type, Skill)}),
            {noreply, State#state{role_list = NewList}};
        _ ->
            {noreply, State}
    end;

%% 关闭房间
handle_info(stop, State) ->
    {stop, normal, State};

%% 提玩家出房间
handle_info(game_over, State = #state{role_list = RoleList}) ->
    do_out(RoleList),
    {stop, normal, State};


%% 延迟处理使用
handle_info(use_horn, State) ->
    NewState = init_one_animal(elephant, State, horn),
    {noreply, NewState};
handle_info({use_self_horn, RoleId, RoleName}, State) ->
    NewState = init_one_animal(self_elephant, State, self_horn, {RoleId, RoleName}),
    {noreply, NewState};

%% 推送使用表情
handle_info({use_expression, RoleId, Type, ToId}, State = #state{role_list = RoleList}) ->
    Data = #m_2021_toc{role_id = RoleId, type = Type, to_id = ToId}, 
    [sys_conn:pack_send(Pid, 2021, Data)||#animal_role{socket_pid = Pid} <-RoleList],
    {noreply, State};


handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State = #state{id = Id}) ->
    great_match_mgr ! {delete, Id},
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



%% 推送有玩家推出
push_out(RoleId, List) ->
    [sys_conn:pack_send(Pid, 2008, #m_2008_toc{role_id = RoleId})||#animal_role{socket_pid = Pid} <-List].

%% 推送玩家进入
push_in(Role = #animal_role{}, List) ->
    Role1 = to_p_animal_role(Role),
    [sys_conn:pack_send(Pid, 2007, #m_2007_toc{role = Role1})||#animal_role{socket_pid = Pid} <-List].

%% 推送玩家点击
push_hit(RoleId, Id, List) ->
    [sys_conn:pack_send(Pid, 2005, #m_2005_toc{role_id = RoleId, id = Id})||#animal_role{socket_pid = Pid} <-List].

%% 推送动物死亡
push_die(HitList, Skill, RoleId, RoleList) ->
    List = to_p_animal_die(HitList),
    Data = #m_2009_toc{role_id = RoleId, type = Skill, ids = List},
    [sys_conn:pack_send(Pid, 2009, Data)||#animal_role{socket_pid = Pid} <- RoleList].

%% 推送动物进入
push_animal_enter([], _List) -> ok;
push_animal_enter(PushList, List) ->
    NewList = to_p_animal(PushList),
    [sys_conn:pack_send(Pid, 2006, #m_2006_toc{animals = NewList})||#animal_role{socket_pid = Pid} <-List].

%% 推送动物走出
push_animal_out([], _List) -> ok;
push_animal_out(PushList, List) ->
    [sys_conn:pack_send(Pid, 2011, #m_2011_toc{id = [ Id || #animal_base{id = Id}<-PushList]})||#animal_role{socket_pid = Pid} <-List].

%% 推送预警
push_pre_animal(BaseId, List) ->
    [sys_conn:pack_send(Pid, 2010, #m_2010_toc{base_id = BaseId})||#animal_role{socket_pid = Pid} <-List].

%% 推送使用技能
push_use_skill(RoleId, Icon, Item, List) ->
    [sys_conn:pack_send(Pid, 2012, #m_2012_toc{role_id = RoleId, type = Item, icon = Icon})||#animal_role{socket_pid = Pid} <-List].
push_use_skill(RoleId, Icon, Item, Effect, List) ->
    [sys_conn:pack_send(Pid, 2012, #m_2012_toc{role_id = RoleId, type = Item, icon = Icon, effect = Effect})||#animal_role{socket_pid = Pid} <-List].

%% 推送技能消失
push_delete_skill(RoleId, Item, List) ->
    [sys_conn:pack_send(Pid, 2014, #m_2014_toc{id = RoleId, type = Item})||#animal_role{socket_pid = Pid} <-List].

%% 推送动物状态
pus_animal_status(AnimalList, List) ->
    NewList = to_p_animal_status(AnimalList),
    [sys_conn:pack_send(Pid, 2013, #m_2013_toc{list = NewList})||#animal_role{socket_pid = Pid} <-List].


%% 初始化房间
do_init(State) ->
    init_animal(20, State).


%% 批量产生动物
init_animal(0, State) -> State;
init_animal(N, State = #state{animal_list = List, role_list = RoleList, num = Num, pre_list = PreList, type = Type, guide_task = TaskId}) ->
    {PushList, NewList, NewNum, PreList1} = init_animal(N, [], List, Num, RoleList, PreList, Type, TaskId),
    push_animal_enter(PushList, RoleList),
    NewState = State#state{animal_list = NewList, num = NewNum, pre_list = PreList1},
    NewState.


%% 初始化线路
init_animal(0, List1, List, Num, _, PreList, _Type, _) -> {List1, List, Num, PreList};
init_animal(N, List1, List, Num, RoleList, PreList, Type, TaskId) ->
    Animal = #animal_base{base_id = BaseId, rate = [Min, Max]} = get_one_annimal(PreList ++ List, TaskId),
    Rate = sys_rand:rand(Min, Max),
    RedBag = create_red_bag(Type, BaseId),
    #animal_route{id = RouteId, time = AllTime, post = Post, xy = XY} = init_animal_route(),
    case lists:member(BaseId, ?animal_pre_notice_list) of
        true ->
            NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = 0, route_id = RouteId, xy = XY, red_bag = RedBag, rate = Rate},
            push_pre_animal(BaseId, RoleList),
            erlang:send_after(3000, self(), {add_animal, NewAnimal}),   %% 预警动物之后再加载
            init_animal(N -1, List1, List, Num + 1, RoleList, [NewAnimal | PreList], Type, TaskId);
        _ ->
            NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = Post, route_id = RouteId, xy = XY, red_bag = RedBag, rate = Rate},
            init_animal(N -1, [NewAnimal | List1], [NewAnimal| List], Num + 1, RoleList,  PreList, Type, TaskId)
    end.

%% 是否产出红包
create_red_bag(_Type, _BaseId) ->
    0.


%% 指定产出一种动物
init_one_animal(BaseId, State = #state{animal_list =  List, role_list = RoleList, num = Num, pre_list = PreList, type = Type}, Horn) ->
    case lists:keyfind(BaseId, #animal_base.base_id, get_animal_base()) of
        Animal = #animal_base{rate = [Min, Max]} ->
            Rate = sys_rand:rand(Min, Max),
            RedBag = create_red_bag(Type, BaseId),
            #animal_route{id = RouteId, time = AllTime, post = Post, xy = XY} = init_animal_route(),
            case lists:member(BaseId, ?animal_pre_notice_list) of
                true ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = 0, route_id = RouteId, is_horn = Horn, xy = XY, red_bag = RedBag, rate = Rate},
                    push_pre_animal(BaseId, RoleList),
                    erlang:send_after(3000, self(), {add_animal, NewAnimal}),   %% 预警动物之后再加载
                    State#state{num  = Num + 1, pre_list = [NewAnimal | PreList]};
                _ ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = Post, route_id = RouteId, is_horn = Horn, xy = XY, red_bag = RedBag, rate = Rate},
                    push_animal_enter([NewAnimal], RoleList),
                    State#state{num = Num + 1, animal_list = [NewAnimal | List]}
            end;
        _ ->
            State
    end.

init_one_animal(BaseId, State = #state{animal_list =  List, role_list = RoleList, num = Num, pre_list = PreList, type = Type}, Horn, {RoleId, RoleName}) ->
    case lists:keyfind(BaseId, #animal_base.base_id, get_animal_base()) of
        Animal = #animal_base{rate = [Min, Max]} ->
            Rate = sys_rand:rand(Min, Max),
            RedBag = create_red_bag(Type, BaseId),
            #animal_route{id = RouteId, time = AllTime, post = Post, xy = XY} = init_animal_route(),
            case lists:member(BaseId, ?animal_pre_notice_list) of
                true ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = 0, route_id = RouteId, is_horn = Horn, xy = XY, red_bag = RedBag, rate = Rate, self_id = RoleId, self_name = RoleName},
                    push_pre_animal(BaseId, RoleList),
                    erlang:send_after(3000, self(), {add_animal, NewAnimal}),   %% 预警动物之后再加载
                    State#state{num  = Num + 1, pre_list = [NewAnimal | PreList]};
                _ ->
                    NewAnimal = Animal#animal_base{id = Num, end_time = AllTime, post = Post, route_id = RouteId, is_horn = Horn, xy = XY, red_bag = RedBag, rate = Rate, self_id = RoleId, self_name = RoleName},
                    push_animal_enter([NewAnimal], RoleList),
                    State#state{num = Num + 1, animal_list = [NewAnimal | List]}
            end;
        _ ->
            State
    end.


%% 随机产生一只动物 只允许一只动物在场上
get_one_annimal(List, TaskId) when TaskId >= 1 andalso TaskId =< 5 ->
    OnlyList = [Id || #animal_base{base_id = Id} <- List, lists:member(Id, ?animal_only_one_list)],
    NewList = [A||A = #animal_base{base_id = Id} <-get_task_animal(TaskId), not lists:member(Id, OnlyList)],
    case sys_rand:rand_list(NewList, #animal_base.pre) of
        Animal = #animal_base{base_id = type_bomber, bomber_type = List1} ->
            Type = sys_rand:rand_list(List1),
            #animal_base{rate = Rate} = lists:keyfind(Type, #animal_base.base_id, get_animal_base()),
            Animal#animal_base{bomber_type = Type, rate = Rate};
        _Animal -> _Animal
    end;
get_one_annimal(List, _TaskId) ->
    OnlyList = [Id || #animal_base{base_id = Id} <- List, lists:member(Id, ?animal_only_one_list)],
    NewList = [A||A = #animal_base{base_id = Id} <-get_animal_base(), not lists:member(Id, OnlyList)],
    case sys_rand:rand_list(NewList, #animal_base.pre) of
        Animal = #animal_base{base_id = type_bomber, bomber_type = List1} ->
            Type = sys_rand:rand_list(List1),
            #animal_base{rate = Rate} = lists:keyfind(Type, #animal_base.base_id, get_animal_base()),
            Animal#animal_base{bomber_type = Type, rate = Rate};
        _Animal -> _Animal
    end.




%% 动物是否走出去了
do_animal_out([], NewAnimal, OutAnimal, CreateNum) -> {NewAnimal, OutAnimal, CreateNum};
do_animal_out([Animal = #animal_base{route_id = Id, end_time = _End, post = Pos, status = 0, is_horn = Horn} | L], NewAnimal, OutAnimal, CreateNum) ->
    case get_xy(Id, Pos + 1) of
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
    XY = get_xy(Id, Post),
    #animal_route{id = Id, post = Post, xy = XY}.


%% 转换前端数据
to_p_animal_role(List) when is_list(List)->
    [to_p_animal_role(Role) || Role <-List];
to_p_animal_role(#animal_role{role_id = RoleId, name = Name, icon = Icon, vip = Vip, skill_id = SkillId, vip_effect = VipEffect}) ->
    Now = date:unixtime(),
    #p_animal_role{role_id = RoleId, name = Name, icon = Icon, vip_effect = VipEffect, skill_list = [ #p_skill{type = Type, effect = Effect, time = max(0, Time - Now)}|| #role_skill{type = Type, effect = Effect, end_time = Time} <- SkillId], vip = Vip}.

to_p_animal(List) when is_list(List) ->
    [to_p_animal(Animal) || Animal <-List];
to_p_animal(#animal_base{id = Id, base_id = self_elephant, route_id = LineId, post = Point, status = Status, red_bag = RedBag, self_id = SelfId, self_name = SelfName}) ->
    #p_animal{id = Id, base_id = self_elephant, line_id = LineId, point = Point, status = Status, red_bag = RedBag, self_id = SelfId, self_name = SelfName};
to_p_animal(#animal_base{id = Id, base_id = BaseId, route_id = LineId, post = Point, status = Status, red_bag = RedBag, bomber_type = 0}) ->
    #p_animal{id = Id, base_id = BaseId, line_id = LineId, point = Point, status = Status, red_bag = RedBag};
to_p_animal(#animal_base{id = Id, base_id = BaseId, route_id = LineId, post = Point, status = Status, red_bag = RedBag, bomber_type = Type}) ->
    #p_animal{id = Id, base_id = BaseId, line_id = LineId, point = Point, status = Status, red_bag = RedBag, bomber_type = Type}.

to_p_animal_die(List) when is_list(List) ->
    [to_p_animal_die(Animal) || Animal <-List];
to_p_animal_die(#animal_base{id = Id, drop_list = List}) ->
    #p_animal_die{id = Id, item_list = List}.

to_p_animal_status(List) when is_list(List) ->
    [to_p_animal_status(A)||A <-List];
to_p_animal_status(#animal_base{id = Id, status = Status}) ->
    #p_animal_status{id = Id, status = Status}.

%% 是否打爆
%% 特殊处理皮卡丘和炸弹人
do_hit(Animal = #animal_base{base_id = pikachu},  AnimalList, Coin, Vip,  Flag, _) ->
    NewList = lists:delete(Animal, AnimalList),
    {Rate, HitList0} = do_hit_pikachu([Animal | NewList], 0, []),
    case do_rate(Rate/10, Coin, Flag) of
        true ->
            {HitList, NewAnimalList, ItemList, CreateNum} = do_drop(HitList0, AnimalList, Coin, Vip, [], [], 0),
            {HitList, NewAnimalList, 1, ItemList, CreateNum, Rate * 10};
        _ ->
            false
    end;
%% 全屏炸弹
do_hit(_Animal = #animal_base{base_id = bomber},  AnimalList, Coin, Vip,  Flag, RoleId) ->
    {Rate, HitList0} = do_hit_bomber(AnimalList, 0, [], RoleId),
    case do_rate(Rate/10, Coin, Flag) of
        true ->
            {HitList, NewAnimalList, ItemList, CreateNum} = do_drop(HitList0, AnimalList, Coin, Vip, [], [], 0),
            {HitList, NewAnimalList, 2, ItemList, CreateNum, Rate * 10};
        _ ->
            false
    end;
%% 同类型炸弹人
do_hit(_Animal = #animal_base{base_id = type_bomber, bomber_type = Type}, AnimalList, Coin, Vip, Flag, _) ->
    {Rate, HitList0} = do_hit_type_bomber(AnimalList, 0, [], Type),
    case do_rate(Rate/10, Coin, Flag) of
        true ->
            {HitList, NewAnimalList, ItemList, CreateNum} = do_drop(HitList0, AnimalList, Coin, Vip, [], [], 0),
            {HitList, NewAnimalList, 2, ItemList, CreateNum, Rate * 10};
        _ ->
            false
    end;
%% 局部炸弹
do_hit(_Animal = #animal_base{base_id = area_bomber, route_id = Id, post = Post},  AnimalList, Coin, Vip, Flag, RoleId) ->
    Point = get_xy(Id, Post),
    {Rate, HitList0} = do_hit_area_bomber(AnimalList, Point, [], 0, RoleId),
    case do_rate(Rate/10, Coin, Flag) of
        true ->
            {HitList, NewAnimalList, ItemList, CreateNum} = do_drop(HitList0, AnimalList, Coin, Vip, [], [], 0),
            {HitList, NewAnimalList, 2, ItemList, CreateNum, Rate * 10};
        _ ->
            false
    end;
do_hit(Animal = #animal_base{rate = Rate}, AnimalList, Coin, Vip, Flag, _) ->
    case do_rate(Rate/10, Coin, Flag) of
        true ->
            {HitList, NewAnimalList, ItemList, CreateNum} = do_drop([Animal], AnimalList, Coin, Vip, [], [], 0),
            {HitList, NewAnimalList, 0, ItemList, CreateNum, Rate * 10};
        _ ->
            false
    end.

%% 计算掉落
do_drop([], AnimalList, _Coin, _Vip, HitList, ItemList, CreateNum) -> {HitList, AnimalList, ItemList, CreateNum};
do_drop([Animal = #animal_base{is_horn = Horn} | L], AnimalList, Coin, Vip, HitList, ItemList, CreateNum) ->
    NewAnimalList = lists:delete(Animal, AnimalList),
    NewCreateNum = case Horn of
        0 -> CreateNum + 1;
        _ -> 
            self() ! {delete_skill, Horn},
            CreateNum
    end,
    {NewAnimal, NewItemList} = do_drop_item(Animal, ItemList, Coin, Vip),
    do_drop(L, NewAnimalList, Coin, Vip, [NewAnimal | HitList], NewItemList, NewCreateNum).

%% 根据倍率计算是否打中 true | false
%% 小于100金币的送分
%%do_rate(Rate, Coin, Flag) when Flag =:= 0 andalso Coin =< 100 ->
%%    Pre1 = case Coin of
%%        5 -> 1.2;
%%        10 -> 1.1;
%%        20 -> 1.05;
%%        40 -> 1.025;
%%        60 -> 1.016;
%%        _ -> 1
%%    end,
%%    N = sys_rand:rand(?animal_rand_num),
%%    Pre = 1/Rate * Pre1,
%%    Num = Pre * ?animal_rand_num,
%%    N =< Num;
%% 目前设置白名单为99
do_rate(Rate, _Coin, 99)->
    Pre1  = case setting_mgr:get(?setting_animal_white_pre) of
        {ok, Value} -> Value/1000;
        _ -> ?animal_white_pre
    end,
    N = sys_rand:rand(?animal_rand_num),
    Pre = 1/Rate * Pre1,
    Num = Pre * ?animal_rand_num,
    N =< Num;
do_rate(Rate, _Coin, _)->
    Pre1  = case setting_mgr:get(?setting_animal_pre) of
        {ok, Value} -> Value/1000;
        _ -> ?animal_pre
    end,
    N = sys_rand:rand(?animal_rand_num),
    Pre = 1/Rate * Pre1,
    Num = Pre * ?animal_rand_num,
    N =< Num.



%% 计算皮卡丘闪电技能,最多打150倍动物
do_hit_pikachu([], Rate, List) -> {Rate, List};
do_hit_pikachu([_Animal = #animal_base{rate = 0} | L], Rate, List) -> 
    do_hit_pikachu(L, Rate, List);
do_hit_pikachu([_Animal = #animal_base{base_id = area_bomber} | L], Rate, List) -> 
    do_hit_pikachu(L, Rate, List);
do_hit_pikachu([Animal = #animal_base{rate = N} | L], Rate, List) -> 
    case N + Rate =< 1500 of
        true ->
            do_hit_pikachu(L, Rate + N, [Animal| List]);
        _ ->
            {Rate, List}
    end.

%% 炸弹人,计算倍率
do_hit_bomber([], Rate, List, _)-> {Rate, List}; 
do_hit_bomber([#animal_base{base_id = self_elephant, self_id = Id} | L], Rate, List, RoleId) when Id =/= RoleId-> 
    do_hit_bomber(L, Rate, List, RoleId);
do_hit_bomber([Animal = #animal_base{rate = N} | L], Rate, List, RoleId)-> 
    do_hit_bomber(L, N + Rate, [Animal | List], RoleId).

%% 同类型炸弹
do_hit_type_bomber([], Rate, List, _Type)-> {Rate, List}; 
do_hit_type_bomber([Animal = #animal_base{base_id = Type, rate = N} | L], Rate, List, Type)-> 
    do_hit_type_bomber(L, N + Rate, [Animal | List], Type);
do_hit_type_bomber([Animal = #animal_base{base_id = type_bomber, rate = N} | L], Rate, List, Type)-> 
    do_hit_type_bomber(L, N + Rate, [Animal | List], Type);
do_hit_type_bomber([_ | L], Rate, List, Type)-> 
    do_hit_type_bomber(L, Rate, List, Type).

%% 局部炸弹
do_hit_area_bomber([], _Point, List, Rate, _) -> {Rate, List};
do_hit_area_bomber([#animal_base{base_id = self_elephant, self_id = Id} | L], Point, List, Rate, RoleId) when Id =/= RoleId->
    do_hit_area_bomber(L, Point, List, Rate, RoleId);
do_hit_area_bomber([#animal_base{rate = 0} | L], Point, List, Rate, RoleId) ->
    do_hit_area_bomber(L, Point, List, Rate, RoleId);
do_hit_area_bomber([Animal = #animal_base{route_id = Id, rate = N, post = Post} | L], Point, List, Rate, RoleId) ->
    Point1 = get_xy(Id, Post),
    case util:in_circle(Point1, Point, 300) of
        true ->
            do_hit_area_bomber(L, Point, [Animal | List], Rate + N, RoleId);
        _ ->
            do_hit_area_bomber(L, Point, List, Rate, RoleId)
    end.


%% 计算所获得的金币和红包
calc_coin_red(Rate, Coin, 0) ->
    Win = trunc(Rate * Coin/10),
    [#p_assets{type = coin, num = Win}];
calc_coin_red(Rate, Coin, 1) ->
    N = sys_rand:rand(10, 22),
    Win = trunc(Rate * Coin/10),
    RedBag = min(2000, trunc(N * Win/100000)),
    Coin1 = Win - trunc(RedBag * 1.2 * 1000),
    [#p_assets{type = red_bag, num = RedBag}, #p_assets{type = coin, num = Coin1}].


%% 合并所有道具数量,并且转换人物所需要的格式
do_sort_item([], ItemList) -> ItemList;
do_sort_item([#p_assets{type = Type, num = Num} | L], ItemList) ->
    case lists:keyfind(Type, 1, ItemList) of
        {Type, Num1} ->
            NewList = lists:keyreplace(Type, 1, ItemList, {Type, Num + Num1}),
            do_sort_item(L, NewList);
        _ ->
            do_sort_item(L, [{Type, Num} | ItemList])
    end.


%% 计算所有掉落 
do_drop_item(Animal = #animal_base{rate = Rate}, ItemList, Coin, _Vip)->
    Coins  = calc_coin_red(Rate, Coin, 0),
%%    {Lollipops,NewLuck} = calc_lollipop(Coin, Rate, Vip, Luck),
%%    Items = calc_item(Coin, List, Vip),
%%    DropList = Coins ++ Lollipops ++ Items,
    NewItemList = do_sort_item(Coins, ItemList),
    {Animal#animal_base{drop_list = Coins}, NewItemList}.


%% 检查道具是否足够, 不足够用钻石代替
check_item_num(#role{vip = Vip}, rage) when Vip < 3->
    {false, ?error_act};
check_item_num(#role{vip = Vip}, auto) when Vip < 2->
    {false, ?error_act};
check_item_num(#role{vip = Vip}, self_horn) when Vip < 4->
    {false, ?error_act};
check_item_num(#role{vip = Vip}, horn) when Vip < 5->
    {false, ?error_act};
check_item_num(Role, Item) ->
    case role_lib:do_cost(Role, [{Item, 1}]) of
        {ok, NewRole} ->
            {ok, NewRole};
        _ ->
            Gold = get_item_gold(Item),
            role_lib:do_cost_gold(Role, Gold)
    end.

%% 获取道具价格
get_item_gold(ice) -> 2;
get_item_gold(horn) -> 10;
get_item_gold(self_horn) -> 88;
get_item_gold(rage) -> 20;
get_item_gold(trumpet) -> 20;
get_item_gold(locking) -> 2;
get_item_gold(auto) -> 50.

%% 处理动物园使用技能效果
%% 全屏的
%% 冰冻
do_use_skill(_Role = #animal_role{role_id = RoleId, icon = Icon}, Item = ice, State = #state{role_list = RoleList, animal_list = AnimalList, skill = Skill}) ->
    NewAnimal = [A#animal_base{status = 1}||A = #animal_base{} <-AnimalList],
    erlang:send_after(10000, self(), {delete_skill, Item}),
    push_use_skill(RoleId, Icon, Item, RoleList),
    pus_animal_status(NewAnimal, RoleList),
    {ok, State#state{animal_list = NewAnimal, skill = [Item | Skill]}};
%% 号角
do_use_skill(_Role = #animal_role{role_id = RoleId, icon = Icon}, Item = horn, State = #state{role_list = RoleList, animal_list = AnimalList, skill = Skill, pre_list = List}) ->
    case lists:keyfind(elephant, #animal_base.base_id, List ++ AnimalList) of
        false ->
            push_use_skill(RoleId, Icon, Item, RoleList),
            erlang:send_after(2000, self(), use_horn),
            {ok, State#state{skill = [Item | Skill]}};
        _ ->
            {false, ?error_horn}
    end;

%% 私有号角
do_use_skill(_Role = #animal_role{role_id = RoleId, icon = Icon, name = RoleName}, Item = self_horn, State = #state{role_list = RoleList, animal_list = AnimalList, pre_list = List}) ->
    case lists:keyfind(RoleId, #animal_base.self_id, List ++ AnimalList) of
        false ->
            push_use_skill(RoleId, Icon, Item, RoleList),
            erlang:send_after(2000, self(), {use_self_horn, RoleId, RoleName}),
            {ok, State};
        _ ->
            {false, ?error_self_horn}
    end;

%% 私有的
%% 狂暴
do_use_skill(Role = #animal_role{role_id = RoleId, icon = Icon, skill_id = Skill}, Item = rage, State = #state{role_list = RoleList}) ->
    Now = date:unixtime(),
    N = sys_rand:rand(2, 4),
    NewSkill = #role_skill{type = Item, effect = N, end_time =  Now + 30},
    NewList = lists:keyreplace(RoleId, #animal_role.role_id, RoleList, Role#animal_role{skill_id = [NewSkill| Skill], effect = N}),
    push_use_skill(RoleId, Icon, Item, N, RoleList),
    {ok, {ok, NewSkill}, State#state{role_list = NewList}};
%% 锁定
do_use_skill(Role = #animal_role{role_id = RoleId, skill_id = Skill, icon = Icon}, Item = locking, State = #state{role_list = RoleList}) ->
    Now = date:unixtime(),
    NewSkill = #role_skill{type = Item, end_time =  Now + 30},
    NewList = lists:keyreplace(RoleId, #animal_role.role_id, RoleList, Role#animal_role{skill_id = [NewSkill | Skill]}),
    push_use_skill(RoleId, Icon, Item, RoleList),
    {ok, {ok, NewSkill}, State#state{role_list = NewList}};
%% 自动
do_use_skill(Role = #animal_role{role_id = RoleId, skill_id = Skill, icon = Icon}, Item = auto, State = #state{role_list = RoleList}) ->
    Now = date:unixtime(),
    NewSkill = #role_skill{type = Item, end_time =  Now + 1800},
    NewList = lists:keyreplace(RoleId, #animal_role.role_id, RoleList, Role#animal_role{skill_id = [NewSkill | Skill]}),
    push_use_skill(RoleId, Icon, Item, RoleList),
    {ok, {ok, NewSkill},  State#state{role_list = NewList}};
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
        ,#animal_base{base_id = horse,   name = "马", rate = [60, 60],         pre = 1500}
        ,#animal_base{base_id = ox,      name = "奶牛", rate = [100, 100],     pre = 1000}
        ,#animal_base{base_id = panda,   name = "熊猫", rate = [200, 200],     pre = 800, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
        ,#animal_base{base_id = area_bomber,   name = "局部炸弹", rate = [300, 300], pre = 800, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
        ,#animal_base{base_id = xsx,   name = "小四喜", rate = [400, 400],     pre = 800, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
        ,#animal_base{base_id = dsy,   name = "大三元", rate = [600, 600],     pre = 800, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
        ,#animal_base{base_id  = hippo,  name = "河马", rate = [1000, 1000],   pre = 500, is_notice = 1, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
        ,#animal_base{base_id = lion,    name = "狮子", rate = [2000, 2000],   pre = 300, is_notice = 1, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
        ,#animal_base{base_id = elephant,name = "大象", rate = [10000, 10000], pre = 100, is_notice = 1, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
        ,#animal_base{base_id = self_elephant,name = "专属大象", rate = [10000, 10000], pre = 0, is_notice = 1, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
        ,#animal_base{base_id = pikachu, name = "皮卡丘", rate = [500, 500],     pre = 500, is_notice = 1, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
        ,#animal_base{base_id = bomber,  name = "炸弹人", rate = [0, 0],         pre = 200}
        ,#animal_base{base_id = type_bomber,  name = "同类型炸弹人", rate = [0, 0], bomber_type = [cock, dog, monkey, horse, ox, panda], pre = 800}
    ].

get_task_animal(_Id = 1)  ->
    [
        #animal_base{base_id = turtle,   name = "乌龟", rate = [8, 15],        pre = 500}
        ,#animal_base{base_id = cock,    name = "小鸡", rate = [12, 12],       pre = 3000}
        ,#animal_base{base_id = dog,     name = "小狗", rate = [20, 20],       pre = 500}
        ,#animal_base{base_id = monkey,  name = "猴子", rate = [40, 40],       pre = 500}
        ,#animal_base{base_id = horse,   name = "马", rate =   [60, 60],       pre = 500}
        ,#animal_base{base_id = ox,      name = "奶牛", rate = [100, 100],     pre = 500}
        ,#animal_base{base_id = panda,   name = "熊猫", rate = [200, 200],     pre = 500, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
    ];
get_task_animal(Id) when Id =< 5 ->
    [
        #animal_base{base_id = turtle,   name = "乌龟", rate = [8, 15],        pre = 500}
        ,#animal_base{base_id = cock,    name = "小鸡", rate = [12, 12],       pre = 500}
        ,#animal_base{base_id = dog,     name = "小狗", rate = [20, 20],       pre = 500}
        ,#animal_base{base_id = monkey,  name = "猴子", rate = [40, 40],       pre = 500}
        ,#animal_base{base_id = horse,   name = "马", rate = [60, 60],         pre = 500}
        ,#animal_base{base_id = ox,      name = "奶牛", rate = [100, 100],     pre = 500}
        ,#animal_base{base_id = panda,   name = "熊猫", rate = [200, 200],     pre = 500, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
    ];
get_task_animal(_Id = 6) ->
    [
        #animal_base{base_id = turtle,   name = "乌龟", rate = [8, 15],        pre = 2000}
        ,#animal_base{base_id = cock,    name = "小鸡", rate = [12, 12],       pre = 1500}
        ,#animal_base{base_id = dog,     name = "小狗", rate = [20, 20],       pre = 1500}
        ,#animal_base{base_id = monkey,  name = "猴子", rate = [40, 40],       pre = 1500}
        ,#animal_base{base_id = horse,   name = "马", rate =   [60, 60],       pre = 1500}
        ,#animal_base{base_id = ox,      name = "奶牛", rate = [100, 100],     pre = 1000}
        ,#animal_base{base_id = panda,   name = "熊猫", rate = [200, 200],     pre = 800, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}]}
        ,#animal_base{base_id = xsx,   name = "小四喜", rate = [400, 400],     pre = 10000, item_list = [{ice, 1, 500}, {locking, 1, 500}, {gold, 2, 200}], bonus = 1}
    ].


get_xy(Id, Point) ->
    List = animal_route:get(Id),
    case catch lists:nth(Point, List) of
        {X, Y} when is_integer(X)-> {X, Y};
        _ -> {0, 0}
    end.

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

%% 计算大奖赛积分
do_calc_score(BaseScore, Role = #role{vip = Vip, great_match = Great = #great_match{daily_times = Times, vip_add = VipAdd, repeat_add = RepeatAdd, high_add = HighAdd, base_score = BaseScore0, once_score = Score, num = Num}}, Coin) ->
    VipScore = trunc(get_vip_add(Vip) * BaseScore/100),
    RepeatScore = trunc(min(15, (Times - 1)) * BaseScore/100),
    HighScore = trunc(min(20, get_coin_add(Coin)) * BaseScore/100),
    NewGreat = Great#great_match{vip_add = VipAdd + VipScore, repeat_add = RepeatAdd + RepeatScore, high_add = HighAdd + HighScore, base_score = BaseScore + BaseScore0, once_score = Score + BaseScore + VipScore + RepeatScore + HighScore, num = Num - 1},
    NewRole = Role#role{great_match = NewGreat},
    case Num - 1 =:= 0 of
        false -> 
            NewRole;
        true ->
            #great_match{week_score = WeekScore, once_score = OnceScore, daily_score = DailyScore} = NewGreat,
            NewRole1 = NewRole#role{great_match = NewGreat#great_match{week_score = WeekScore + OnceScore, daily_score = DailyScore + OnceScore}},
            rank:handle(?rank_great_match, NewRole1),
            rank:handle(?rank_week_great_match, NewRole1),
            NewRole1
    end.

%% 获取vip等级积分加成%比
get_vip_add(Vip) when Vip < 9 -> 0;
get_vip_add(9) -> 3;
get_vip_add(10) -> 4;
get_vip_add(11) -> 5;
get_vip_add(12) -> 6;
get_vip_add(13) -> 7;
get_vip_add(14) -> 8;
get_vip_add(15) -> 9;
get_vip_add(_) -> 10.

%% 获取金币积分加成%比
get_coin_add(Coin) when Coin < 10000 -> 0;
get_coin_add(Coin) ->
    trunc((Coin - 10000)/5000) + 1.

%% 主动提出房间
do_out(RoleList) ->
    [role:apply(async, Pid, {?MODULE, apply_out, []})||#animal_role{pid = Pid} <-RoleList].

apply_out(Role = #role{great_match = Great}) ->
    sys_conn:pack_send(2019, #m_2019_toc{}),
    {ok, Role#role{room_pid = undefined, status = ?status_normal, great_match = Great#great_match{num = 0}}}.

