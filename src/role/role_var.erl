%%----------------------------------------------------
%% @doc 人物版本控制
%% 
%% @author weichengjun(527070307@qq.com)
%% @end
%%----------------------------------------------------
-module(role_var).
-export([
        update_var/1
    ]).

-include("common.hrl").
-include("role.hrl").

update_var({role, Var = 0, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum}) -> 
    DailyTask = {[], [], 0},
    Channel = 0,
    update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel});
    
update_var({role, Var = 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel}) ->
    Charge_today = 0,
    Charge_tomorrow = 0,
    Candy = 0,
    Lolly = 0,
    update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly});

 update_var({role, Var = 2, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly}) ->
     HitNum = 0,
     AnimalFlag = 0,
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin * 10 ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag});

update_var({role, Var = 3, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag}) ->
     PhoneScreat = "",
     GiftCode = 0,
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode});

update_var({role, Var = 4, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode}) ->
     CoinTreeTime = 0,
     SelfHorn = 0,
     TalkList = [],
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList});

update_var({role, Var = 5, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList}) ->
    DailyKill = 0,
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill});

update_var({role, Var = 6, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin ,Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill}) ->
    GreatMatch = #great_match{},
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch});

update_var({role, Var = 7, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch}) ->
    WeekKill = 0,
    Xin = 0,
    Nian = 0,
    Kuai = 0,
    Le = 0,
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le});

update_var({role, Var = 8, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le}) ->
    VipEffect = Vip,
     update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le, VipEffect});

update_var({role, Var = 9, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le, VipEffect}) ->
    Pick = 0,
    ActiveCard = 0,
    update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le, VipEffect, Pick, ActiveCard});
update_var({role, Var = 10, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le, VipEffect, Pick, ActiveCard}) ->
    Box1 = 0,
    Box2 = 0,
    Box3 = 0,
    DailyGiftType = 1,
    DailyGiftFlush = 0,
    update_var({role, Var + 1, RoleId, Name, Pid, SocketPid, Icon, Gold ,Coin, Screat, Type ,OpendId ,Ip ,ParentId ,Loop ,Sync ,Vip ,VipCharge ,Sex ,Regist ,Login ,OffTime ,Charge ,RoomType ,RoomPid ,Item ,Profit ,Status ,IdCard ,TrueName ,UseCoin ,BonusPool ,BonusNum ,BonusReward ,Gift ,Mail ,SendLog ,ExchangeLog ,UseLog ,DailyValue ,FirstGift ,SkillList ,Sign ,RedOpenId ,PayOpendId ,Task ,Phone ,Guide ,GuideGift ,GuideTask ,GuideGiftTime ,Off  ,FirstCharge ,Exchange ,Luck ,LuckNum, DailyTask, Channel, Charge_today, Charge_tomorrow, Candy, Lolly, HitNum, AnimalFlag, PhoneScreat, GiftCode, CoinTreeTime, SelfHorn, TalkList, DailyKill, GreatMatch, WeekKill, Xin, Nian, Kuai, Le, VipEffect, Pick, ActiveCard, Box1, Box2, Box3, DailyGiftType, DailyGiftFlush});
update_var(Role = #role{var = ?role_var}) -> {ok, Role};
update_var(_Role) -> 
    ?ERR("玩家信息版本升级失败:~w", [_Role]),
    false.


