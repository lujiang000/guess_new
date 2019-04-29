%%----------------------------------------------------
%%  大奖赛管理进程
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(great_match_mgr).
-behaviour(gen_server).
-export([start_link/0
        ,enter_room/1
        ,get_status/0
    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
        id = 0
        ,list =  []
        ,status = 0  %%0活动未开启，1活动进行，2活动报名结束
    }
).

-include("role.hrl").
-include("common.hrl").
-include("animal.hrl").
-include("error_msg.hrl").

-define(great_match_start, 7 * 60 * 60).   %% 7点开始
-define(great_match_end, 23 * 60 * 60).   %% 23点结束
-define(great_match_over, trunc(22.5 * 60 * 60)).   %% 22:30 结束报名


%% 进入房间
enter_room(Role = #role{status = ?status_normal, use_coin = Coin, great_match = #great_match{num = Num}}) when Coin >= 16 andalso Num > 0->
    case catch gen_server:call(?MODULE, get_room_pid) of
        {ok, Pid} ->
            case catch gen_server:call(Pid, {enter, role_conver:to_animal_role(Role)}) of
                {ok, Data} ->
                    {ok, Data, Role#role{room_pid = Pid, status = ?status_great_match}};
                _Err ->
                    {false, ?error_busy}
            end;
        {false, Reason} ->
            {false, Reason};
        _Err ->
            {false, ?error_busy}
    end;
enter_room(_) ->
    {false, ?error_act}.


%% 获取活动状态
get_status() ->
    case catch gen_server:call(?MODULE, get_status) of
        {ok, Status} -> 
            {ok, Status};
        _ ->
            {false, ?error_busy}
    end.



start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ?INFO("[~w] 正在启动", [?MODULE]),
    process_flag(trap_exit, true),
    Status = do_init(),
    erlang:send_after(date:next_diff(7, 0, 0) * 1000, self(), game_start),
    erlang:send_after(date:next_diff(22, 30, 0) * 1000, self(), game_over),
    erlang:send_after(date:next_diff(23, 0, 0) * 1000, self(), game_end),
    State = #state{status = Status},
    ?INFO("[~w] 启动完成", [?MODULE]),
    {ok, State}.


%% 初始化活动状态
do_init() ->
    Zero = date:unixtime(zero),
    Now = date:unixtime(),
    Time = Now - Zero,
    if Time < ?great_match_start ->
            0;
        Time < ?great_match_over ->
            1;
        Time < ?great_match_end ->
            2;
        true ->
            0
    end.


handle_call(get_room_pid, _From, State = #state{status = 0}) ->
    {reply, {false, ?error_act_time}, State};
handle_call(get_room_pid, _From, State = #state{id = NextId, list = List}) ->
    case find_room(List) of
        Room = #animal_room{id = Id, pid = Pid, num = Num} ->
            NewList = lists:keydelete(Id, #animal_room.id, List),
            NewList1 = [Room#animal_room{num = Num + 1} | NewList],
            {reply, {ok, Pid}, State#state{list = NewList1}};
        _ ->
            case start_room(NextId) of
                Room = #animal_room{pid = Pid} ->
                    NewList = [Room | List],
                    {reply, {ok, Pid}, State#state{id = NextId + 1, list = NewList}};
                _ ->
                    {reply, false, State}
            end
    end;

handle_call(get_status, _From, State = #state{status = Status}) ->
    {reply, {ok, Status}, State};

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 房间人数减少通知
handle_info({delete_room_num, Id}, State = #state{list = List}) ->
    case lists:keyfind(Id, #animal_room.id, List) of
        #animal_room{num = Num, pid = Pid} when Num =< 1->             %% 房间没有人了 房间进程结束
            NewList = lists:keydelete(Id, #animal_room.id, List),
            Pid ! stop,
            {noreply, State#state{list = NewList}};
        Room = #animal_room{num = Num} ->
            NewList = lists:keyreplace(Id, #animal_room.id, List, Room#animal_room{num = Num - 1}),
            {noreply, State#state{list = NewList}};
        _ ->
            {noreply, State}
    end;

%% 房间异常关闭
handle_info({delete, Id}, State = #state{list = List}) ->
    case lists:keyfind(Id, #animal_room.id, List) of
        #animal_room{}->            
            NewList = lists:keydelete(Id, #animal_room.id, List),
            {noreply, State#state{list = NewList}};
        _ ->
            {noreply, State}
    end;

handle_info(game_start, State) ->
    erlang:send_after(date:next_diff(7, 0, 0) * 1000, self(), game_start),
    {noreply, State#state{status = 1}};

handle_info(game_over, State) ->
    erlang:send_after(date:next_diff(22, 30, 0) * 1000, self(), game_over),
    {noreply, State#state{status = 2}};

handle_info(game_end, State) ->
    erlang:send_after(date:next_diff(23, 0, 0) * 1000, self(), game_end),
    {noreply, State#state{status = 0}};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% 找房间有空位置的房间
find_room([]) -> false; 
find_room([Room = #animal_room{num = Num}| _L]) when Num < ?animal_max_num->
    Room;
find_room([_Room | L]) ->
    find_room(L).


%% 新开一个房间
start_room(Id) ->
    case catch great_match:start_link(Id) of
        {ok, Pid} ->
            #animal_room{id = Id, num = 1, pid = Pid};
        _ ->
            false
    end.
            


