%%----------------------------------------------------
%% @doc 任务
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(task).
-export([
        login/1
        ,handle/4
        ,get_task/1
        ,do_task_over/1
        ,get_guide_task/1
        ,get_daily_task/1
        ,do_fire_task/2
    ]
).

-include("common.hrl").
-include("role.hrl").
-include("all_pb.hrl").
-include("animal.hrl").

%% 登陆处理,处理过期任务,初始化新手指引任务
login(Role = #role{task = Task = #role_task{time = Time}, guide_task = #guide_task{id = Id}}) ->
    Now = date:unixtime(),
    NewRole = case Time > Now of
        true ->
            Ref = erlang:send_after((Time - Now) * 1000, self(), task_over),
            put(task, Ref),
            Role;
        _ ->
            Role#role{task = Task#role_task{process_list = [], reward = [], time = 0}}
    end,
    case Id of
        0 ->
            NewGuideTask = accept_guide_task(Id + 1),
            NewRole#role{guide_task = #guide_task{id = 6}};
        _ ->
            NewRole#role{guide_task = #guide_task{id = 6}}
    end.



%% 获取任务
get_task(_Role = #role{task = #role_task{time = 0}}) ->
    #m_1701_toc{list = [], time = 0, reward = []};
get_task(_Role = #role{task = #role_task{time = Time, process_list = Process, reward = Reward}}) ->
    Now = date:unixtime(),
    #m_1701_toc{list = to_p_process(Process), reward = [#p_assets{type  = Type, num = Num}|| {Type, Num}<-Reward], time = max(0, Time - Now)}.

to_p_process(List) ->
    [#p_process{id = Id, value = Value, target = Target, type = Type}||#task_process{id = Id, value = Value, target = Target, type = Type} <-List].

%% 推送触发任务
push_task(#role_task{time = Time, process_list = Process, reward = Reward}) ->
    Now = date:unixtime(),
    Data = #m_1702_toc{list = to_p_process(Process), reward = [#p_assets{type  = Type, num = Num}|| {Type, Num}<-Reward], time = max(0, Time - Now)},
    sys_conn:pack_send(1702, Data).

%% 任务过期
do_task_over(Role = #role{task = Task}) ->
    Role#role{task = Task#role_task{process_list = [], reward = [], time = 0}}.


%% 推送新手务进度
push_guide_task_process(#guide_task{value = Value}) ->
    Data = #m_1706_toc{value = Value},
    sys_conn:pack_send(1706, Data).

%% 推送接受新手任务
push_new_guide_task(#guide_task{id = Id, value = Value, target = Target}) ->
    Data = #m_1705_toc{id = Id, value = Value, target = Target},
    sys_conn:pack_send(1705, Data).

%% 增加新手任务的进度
add_guide_task(Role = #role{role_id = _RoleId, parent_id = ParentId, room_pid = Pid, use_coin = Coin, guide_task = Task = #guide_task{id = Id, value = Value, target = Target, reward = Reward}}, Add) ->
    push_guide_task_process(Task#guide_task{value  = Value + Add}),
    case Add + Value >= Target of
        true ->
            NewGuideTask = #guide_task{target  = Target1, type = Type} = accept_guide_task(Id + 1),
            case Target1 =:= 0 of
                true ->
                     friend_mgr:add_friend(ParentId);
                _ ->
                    Pid ! {guide_task, Id + 1}
            end,
            {ok, NewRole} = role_lib:do_add(Role, Reward),
            account_mgr:output(?guide_task_coin, Reward),
            NewRol1 = NewRole#role{guide_task = NewGuideTask},
            case Type of
                open_fire ->
                    do_guide_task(NewRol1, Type, Coin);
                _ ->
                    NewRol1
            end;
        _ ->
            NewGuideTask  = Task#guide_task{value  = Value + Add},
            Role#role{guide_task = NewGuideTask}
    end.

%% 获取新手任务信息
get_guide_task(_Role  = #role{guide_task = #guide_task{id = Id, value = Value, target = Target}}) ->
    #m_1704_toc{id = Id, value = Value, target = Target}.

%% 获取每日任务信息
get_daily_task(#role{daily_task = {List, _}, room_type = Type}) ->
    case lists:keyfind(Type, #role_daily_task.type, List) of
        #role_daily_task{list = List1, finish = List2} ->
            #m_1707_toc{list = to_daily_task(List2 ++ List1)};
        _ ->
            []
    end.

to_daily_task(List) when is_list(List)->
    [#p_daily_task{id = Id, value = Value} ||#daily_task{id = Id, value = Value} <-List];
to_daily_task(#daily_task{id = Id, value = Value}) ->
    #p_daily_task{id = Id, value = Value}.


%% 任务入口
%% 新手任务
handle(Role = #role{guide_task = #guide_task{id = Id}}, Type, _, Value) when Id < 6->
    do_guide_task(Role, Type, Value);

%% 每日任务
handle(Role, animal_die, Type, List) ->
    do_daily_task(Role, Type, List);
handle(Role, _Type, _RoomType, _Value) ->
    Role.

%% 每日任务
do_daily_task(Role = #role{daily_task = {TaskList, Time}}, Type, List) -> 
    case lists:keyfind(Type, #role_daily_task.type, TaskList) of
        #role_daily_task{list = []} -> Role;
        RoleTask = #role_daily_task{list = [Task | L], finish = Finish} -> 
            case add_daily_task(Task, List) of
                {update, Task} ->
                    Role;
                {update, NewTask} ->
                    NewRoleTask = RoleTask#role_daily_task{list = [NewTask | L]},
                    NewList = lists:keyreplace(Type, #role_daily_task.type, TaskList, NewRoleTask),
                    Role#role{daily_task = {NewList, Time}};
                {finish, NewTask = #daily_task{reward = Reward}} ->
                    animal_account_mgr:update_task(Reward),
                    {ok, NewRole} = role_lib:do_add(Role, Reward),
                    NewRoleTask = RoleTask#role_daily_task{list = L, finish = Finish ++ [NewTask]},
                    NewList = lists:keyreplace(Type, #role_daily_task.type, TaskList, NewRoleTask),
                    NewRole#role{daily_task = {NewList, Time}}
            end;
        _ -> Role
    end.


%% 增加每日任务进度
add_daily_task(Task, []) -> 
    push_daily_task(Task),
    {update, Task};
add_daily_task(Task = #daily_task{type = elephant, value = Value, target = Target}, [#animal_base{base_id = self_elephant} | L]) ->
    case Value + 1 >= Target of
        true ->
            push_daily_task(Task#daily_task{value = Value + 1}),
            {finish, Task#daily_task{value = Value + 1}};
        _ ->
            add_daily_task(Task#daily_task{value = Value + 1}, L)
    end;
add_daily_task(Task = #daily_task{type = Type, value = Value, target = Target}, [#animal_base{base_id = Type} | L]) ->
    case Value + 1 >= Target of
        true ->
            push_daily_task(Task#daily_task{value = Value + 1}),
            {finish, Task#daily_task{value = Value + 1}};
        _ ->
            add_daily_task(Task#daily_task{value = Value + 1}, L)
    end;
add_daily_task(Task, [_ | L]) ->
    add_daily_task(Task, L).

%% 推送每日任务
push_daily_task(Task) ->
    Data = #m_1708_toc{task = to_daily_task(Task)},
    sys_conn:pack_send(1708, Data).




%% 动物击杀任务
do_guide_task(Role = #role{guide_task = #guide_task{type = animal_die, type_1 = Type}}, animal_die, AnimalList)->
    Add = case Type of
        all ->
            erlang:length(AnimalList);
        bonus ->
            erlang:length([1|| #animal_base{bonus = 1}<-AnimalList]);
        _ ->
            erlang:length([1|| #animal_base{base_id = Type1}<-AnimalList, Type1 =:= Type])
    end,
    add_guide_task(Role, Add);
%% 解锁任务
do_guide_task(Role = #role{guide_task = #guide_task{type = open_fire, type_1 = Type1}}, open_fire, Type) when Type >= Type1->
    add_guide_task(Role, 1);
%% 使用技能
do_guide_task(Role = #role{guide_task = #guide_task{type = use_skill, type_1 = Type}}, use_skill, Type)->
    add_guide_task(Role, 1);
do_guide_task(Role , _, _)->
    Role.


%% 击打
%% 还没有触发任务,增加点击量看是否需要触发任务
do_fire_task(Role = #role{task = Task = #role_task{hit = Hit, time = 0}}, _TypeList) ->
    case Hit + 1 >= 500 of
        true ->
            NewTask = fire_task(Task),
            push_task(NewTask),
            Role#role{task = NewTask};
        _ ->
            Role#role{task = Task#role_task{hit = Hit + 1}}
    end;
do_fire_task(Role = #role{task = Task = #role_task{process_list = ProcessList}}, TypeList) ->
    {Finish, NewProcessList} = do_add_process(ProcessList, TypeList, []),
    NewRole = Role#role{task = Task#role_task{process_list = NewProcessList}},
    case Finish of
        1 ->
            task_reward(NewRole);
        _ ->
            NewRole
    end.


%% 任务完成发奖励
task_reward(Role = #role{task = Task, great_match = Great = #great_match{task_add = TaskAdd, once_score = Score}}) ->
    Ref = get(task),
    erlang:cancel_timer(Ref),
    Add = 10000, 
    Role#role{task = Task#role_task{process_list = [], reward = [], time = 0}, great_match = Great#great_match{task_add = TaskAdd + Add, once_score = Score + Add}}.




%% 增加进度
do_add_process(ProcessList, [], PushList) -> 
    case PushList of
        [] -> 
            {0, ProcessList};
        _ ->
            Finish = case [1||#task_process{finish = 0} <-ProcessList] of
                [] -> 
                    1;
                _ ->
                    0
            end,
            do_push_list(PushList),
            {Finish, ProcessList}
    end;
do_add_process(ProcessList, [#animal_base{base_id = Type} | L], PushList) -> 
    {NewProcessList, NewPushList} = case lists:keyfind(Type, #task_process.type, ProcessList) of
        Process = #task_process{value = Value, target = Target} when Value < Target->
            NewProcess = case Value  + 1 >= Target of
                true ->
                    Process#task_process{value = Target, finish = 1};
                _ ->
                    Process#task_process{value = Value + 1}
            end,
            NewList = lists:keystore(Type, #task_process.type, PushList, NewProcess),
            {lists:keyreplace(Type, #task_process.type, ProcessList, NewProcess), NewList};
        _ ->
            {ProcessList, PushList}
    end,
    do_add_process(NewProcessList, L, NewPushList).


%% 推送进度改变
do_push_list(List) ->
    Data = #m_1703_toc{list = to_p_process(List)},
    sys_conn:pack_send(1703, Data).

%% 接受新手指引任务
accept_guide_task(Id) ->
    case catch zoo_new_player_task_setting:get_data(Id) of
        {Reward, {Type, Type1}, Target} ->
            Task = #guide_task{id = Id, type = Type, target = Target, type_1 = Type1, reward = Reward},
            push_new_guide_task(Task),
            Task;
        _ ->
            #guide_task{id = Id}
    end.



%% 触发任务
fire_task(Task = #role_task{}) ->
    Now = date:unixtime(),
    Process = get_process(1, []),
    %%            Reward = get_reward(),
    Ref = erlang:send_after(2 * 60 * 1000, self(), task_over),
    put(task, Ref),
    Task#role_task{process_list = Process, reward = [], start_time = Now, time = Now + 2 * 60, hit = 0}.


%% 获取触发任务进度列表
get_process(4, List) -> List;
get_process(N, List) ->
    List1 = arena_mission_setting:get_level(N),
    Id = sys_rand:rand_list(List1),
    {_, {Type, Target}} = arena_mission_setting:get_data(Id),
    case lists:keyfind(Type, #task_process.type, List) of
        false ->
            get_process(N + 1, [#task_process{id = Id, target = Target, type = Type} | List]);
        _ ->
            get_process(N, List)
    end.

%% 获取触发任务奖励
get_reward()->
    List = mission_time_limit_reward_setting:get_all(),
    Id = sys_rand:rand_list(List),
    Reward = mission_time_limit_reward_setting:get_data(Id),
    [Reward].

