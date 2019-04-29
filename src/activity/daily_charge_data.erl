%%----------------------------------------------------
%% @doc 每日充值数据
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(daily_charge_data).
-export([
        get_gift_by_type/1
        ,get_gift_by_id/1
    ]
).

-include("all_pb.hrl").
-include("common.hrl").



%% 根据挡位获取礼包信息
get_gift_by_type(1) ->
    [101, 102];
get_gift_by_type(2) ->
    [104, 106];
get_gift_by_type(3) ->
    [107, 109];
get_gift_by_type(4) ->
    [110, 112];
get_gift_by_type(5) ->
    [114, 115];
get_gift_by_type(6) ->
    [117, 118];
get_gift_by_type(_) ->
    [].

%% 根据id获取礼包信息
get_gift_by_id(Id = 101) ->
    #p_daily_gift{id = Id, type = 1, price = 12, list = [#p_assets{type = coin, num = 120000}, #p_assets{type = gold, num = 10}, #p_assets{type = box1, num = 1}]};
get_gift_by_id(Id = 102) ->
    #p_daily_gift{id = Id, type = 1, price = 12, list = [#p_assets{type = coin, num = 20000}, #p_assets{type = gold, num = 120}, #p_assets{type = box1, num = 1}]};
get_gift_by_id(Id = 103) ->
    #p_daily_gift{id = Id, type = 1, price = 12, list = [#p_assets{type = coin, num = 70000}, #p_assets{type = gold, num = 60}, #p_assets{type = box1, num = 1}]};

get_gift_by_id(Id = 104) ->
    #p_daily_gift{id = Id, type = 2, price = 36, list = [#p_assets{type = coin, num = 360000}, #p_assets{type = gold, num = 20}, #p_assets{type = box1, num = 2}]};
get_gift_by_id(Id = 105) ->
    #p_daily_gift{id = Id, type = 2, price = 36, list = [#p_assets{type = coin, num = 20000}, #p_assets{type = gold, num = 360}, #p_assets{type = box1, num = 2}]};
get_gift_by_id(Id = 106) ->
    #p_daily_gift{id = Id, type = 2, price = 36, list = [#p_assets{type = coin, num = 200000}, #p_assets{type = gold, num = 180}, #p_assets{type = box1, num = 2}]};

get_gift_by_id(Id = 107) ->
    #p_daily_gift{id = Id, type = 3, price = 98, list = [#p_assets{type = coin, num = 980000}, #p_assets{type = gold, num = 30}, #p_assets{type = box2, num = 1}]};
get_gift_by_id(Id = 108) ->
    #p_daily_gift{id = Id, type = 3, price = 98, list = [#p_assets{type = coin, num = 900000}, #p_assets{type = gold, num = 110}, #p_assets{type = box2, num = 1}]};
get_gift_by_id(Id = 109) ->
    #p_daily_gift{id = Id, type = 3, price = 98, list = [#p_assets{type = coin, num = 980000}, #p_assets{type = tel_fare, num = 10}, #p_assets{type = box2, num = 1}]};

get_gift_by_id(Id = 110) ->
    #p_daily_gift{id = Id, type = 4, price = 188, list = [#p_assets{type = coin, num = 1880000}, #p_assets{type = gold, num = 40}, #p_assets{type = box2, num = 2}]};
get_gift_by_id(Id = 111) ->
    #p_daily_gift{id = Id, type = 4, price = 188, list = [#p_assets{type = coin, num = 1800000}, #p_assets{type = gold, num = 120}, #p_assets{type = box2, num = 2}]};
get_gift_by_id(Id = 112) ->
    #p_daily_gift{id = Id, type = 4, price = 188, list = [#p_assets{type = coin, num = 1880000}, #p_assets{type = tel_fare, num = 20}, #p_assets{type = box2, num = 2}]};

get_gift_by_id(Id = 113) ->
    #p_daily_gift{id = Id, type = 5, price = 368, list = [#p_assets{type = coin, num = 3680000}, #p_assets{type = gold, num = 40}, #p_assets{type = box3, num = 1}]};
get_gift_by_id(Id = 114) ->
    #p_daily_gift{id = Id, type = 5, price = 368, list = [#p_assets{type = coin, num = 3600000}, #p_assets{type = gold, num = 130}, #p_assets{type = box3, num = 1}]};
get_gift_by_id(Id = 115) ->
    #p_daily_gift{id = Id, type = 5, price = 368, list = [#p_assets{type = coin, num = 3680000}, #p_assets{type = tel_fare, num = 30}, #p_assets{type = box3, num = 1}]};

get_gift_by_id(Id = 116) ->
    #p_daily_gift{id = Id, type = 6, price = 728, list = [#p_assets{type = coin, num = 7280000}, #p_assets{type = gold, num = 60}, #p_assets{type = box3, num = 2}]};
get_gift_by_id(Id = 117) ->
    #p_daily_gift{id = Id, type = 6, price = 728, list = [#p_assets{type = coin, num = 7200000}, #p_assets{type = gold, num = 140}, #p_assets{type = box3, num = 2}]};
get_gift_by_id(Id = 118) ->
    #p_daily_gift{id = Id, type = 6, price = 728, list = [#p_assets{type = coin, num = 7280000}, #p_assets{type = tel_fare, num = 50}, #p_assets{type = box3, num = 2}]}.
