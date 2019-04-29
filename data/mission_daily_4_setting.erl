%% 文件根据Excel配置表自动生成,修改可能会产生意外的问题,并且任何改动将在文件重新生成时丢失
%% 每日任务-黄金场
-module(mission_daily_4_setting).
-export([
		get_data/1
		,get_level/1
		,get_all/0
	]).

%% 获取所有id列表
get_all() -> [4095,4096,4097,4098,4099,4100,4101,4102,4103,4104,4105,4106,4107,4108,4109,4110,4111,4112,4113,4114,4115,4116,4117,4118,4119,4120,4121,4122,4123,4124,4125,4126,4127,4128,4129,4130,4131,4132,4133,4134,4135,4136,4137,4138,4139,4140,4141,4142,4143,4144,4145,4146,4147,4148,4149,4150,4151,4152,4153,4154,4155,4156,4157,4158,4159,4160,4161,4162,4163,4164,4165,4166,4167,4168,4169,4170,4171,4172,4173,4174,4175,4176,4177].


%% 获取指定类型的id列表
get_level(1) -> [4095,4096,4097,4098,4102,4103,4104,4105,4109,4110,4111,4112,4116,4124];
get_level(2) -> [4099,4100,4101,4106,4107,4108,4113,4114,4115,4117,4118,4119,4120,4125,4126];
get_level(3) -> [4121,4122,4123,4127,4128,4156,4157,4158,4162,4163,4168,4169];
get_level(4) -> [4129,4130,4131,4132,4147,4148,4149,4159,4160,4164,4165,4166,4170,4171,4172,4174];
get_level(5) -> [4133,4134,4138,4150,4161,4167,4173,4175];
get_level(6) -> [4135,4136,4139,4140,4141,4144,4151,4152,4153,4176];
get_level(7) -> [4137,4142,4143,4145,4146,4154,4155,4177].


%% 根据id获取一条数据
%% 1 任务id
%% 2 任务等级
%% 3 动物
%% 4 奖励列表
get_data(4095) -> {1,{dog,4},[{locking,1}]};
get_data(4096) -> {1,{dog,5},[{coin,10000}]};
get_data(4097) -> {1,{dog,6},[{locking,1}]};
get_data(4098) -> {1,{dog,7},[{coin,14800}]};
get_data(4099) -> {2,{dog,8},[{locking,2}]};
get_data(4100) -> {2,{dog,9},[{coin,18000}]};
get_data(4101) -> {2,{dog,10},[{locking,2}]};
get_data(4102) -> {1,{monkey,4},[{coin,16800}]};
get_data(4103) -> {1,{monkey,5},[{locking,1}]};
get_data(4104) -> {1,{monkey,6},[{coin,23000}]};
get_data(4105) -> {1,{monkey,7},[{locking,1}]};
get_data(4106) -> {2,{monkey,8},[{coin,26000}]};
get_data(4107) -> {2,{monkey,9},[{trumpet,1}]};
get_data(4108) -> {2,{monkey,10},[{coin,32000}]};
get_data(4109) -> {1,{horse,4},[{ice,1}]};
get_data(4110) -> {1,{horse,5},[{coin,30000}]};
get_data(4111) -> {1,{horse,6},[{ice,1}]};
get_data(4112) -> {1,{horse,7},[{coin,36000}]};
get_data(4113) -> {2,{horse,8},[{auto,1}]};
get_data(4114) -> {2,{horse,9},[{trumpet,1}]};
get_data(4115) -> {2,{horse,10},[{rage,1}]};
get_data(4116) -> {1,{ox,3},[{gold,20}]};
get_data(4117) -> {2,{ox,4},[{gold,30}]};
get_data(4118) -> {2,{ox,5},[{gold,40}]};
get_data(4119) -> {2,{ox,6},[{gold,50}]};
get_data(4120) -> {2,{ox,7},[{gold,60}]};
get_data(4121) -> {3,{ox,8},[{gold,65}]};
get_data(4122) -> {3,{ox,9},[{gold,70}]};
get_data(4123) -> {3,{ox,10},[{gold,75}]};
get_data(4124) -> {1,{panda,3},[{gold,20}]};
get_data(4125) -> {2,{panda,4},[{gold,30}]};
get_data(4126) -> {2,{panda,5},[{gold,40}]};
get_data(4127) -> {3,{panda,6},[{gold,50}]};
get_data(4128) -> {3,{panda,7},[{gold,60}]};
get_data(4129) -> {4,{panda,8},[{gold,70}]};
get_data(4130) -> {4,{panda,9},[{gold,80}]};
get_data(4131) -> {4,{panda,10},[{horn,2}]};
get_data(4132) -> {4,{hippo,3},[{tel_fare,350}]};
get_data(4133) -> {5,{hippo,4},[{tel_fare,400}]};
get_data(4134) -> {5,{hippo,5},[{tel_fare,450}]};
get_data(4135) -> {6,{hippo,6},[{tel_fare,500}]};
get_data(4136) -> {6,{hippo,7},[{tel_fare,550}]};
get_data(4137) -> {7,{hippo,8},[{tel_fare,600}]};
get_data(4138) -> {5,{lion,3},[{gold,500}]};
get_data(4139) -> {6,{lion,4},[{gold,600}]};
get_data(4140) -> {6,{lion,5},[{gold,700}]};
get_data(4141) -> {6,{lion,6},[{gold,800}]};
get_data(4142) -> {7,{lion,7},[{gold,900}]};
get_data(4143) -> {7,{lion,8},[{gold,1000}]};
get_data(4144) -> {6,{elephant,1},[{red_bag,1000}]};
get_data(4145) -> {7,{elephant,2},[{red_bag,1500}]};
get_data(4146) -> {7,{elephant,3},[{red_bag,2000}]};
get_data(4147) -> {4,{pikachu,3},[{horn,1}]};
get_data(4148) -> {4,{pikachu,4},[{rage,1}]};
get_data(4149) -> {4,{pikachu,5},[{trumpet,2}]};
get_data(4150) -> {5,{pikachu,6},[{auto,1}]};
get_data(4151) -> {6,{pikachu,7},[{auto,2}]};
get_data(4152) -> {6,{pikachu,8},[{auto,3}]};
get_data(4153) -> {6,{bomber,1},[{red_bag,200}]};
get_data(4154) -> {7,{bomber,2},[{red_bag,250}]};
get_data(4155) -> {7,{bomber,3},[{red_bag,300}]};
get_data(4156) -> {3,{type_bomber,3},[{gold,15}]};
get_data(4157) -> {3,{type_bomber,4},[{gold,20}]};
get_data(4158) -> {3,{type_bomber,5},[{gold,30}]};
get_data(4159) -> {4,{type_bomber,6},[{gold,40}]};
get_data(4160) -> {4,{type_bomber,7},[{gold,50}]};
get_data(4161) -> {5,{type_bomber,8},[{gold,60}]};
get_data(4162) -> {3,{xsx,3},[{horn,1}]};
get_data(4163) -> {3,{xsx,4},[{rage,1}]};
get_data(4164) -> {4,{xsx,5},[{trumpet,2}]};
get_data(4165) -> {4,{xsx,6},[{auto,2}]};
get_data(4166) -> {4,{xsx,7},[{auto,2}]};
get_data(4167) -> {5,{xsx,8},[{auto,2}]};
get_data(4168) -> {3,{dsy,3},[{coin,80000}]};
get_data(4169) -> {3,{dsy,4},[{auto,1}]};
get_data(4170) -> {4,{dsy,5},[{coin,150000}]};
get_data(4171) -> {4,{dsy,6},[{auto,2}]};
get_data(4172) -> {4,{dsy,7},[{coin,220000}]};
get_data(4173) -> {5,{dsy,8},[{gold,200}]};
get_data(4174) -> {4,{area_bomber,2},[{coin,18000}]};
get_data(4175) -> {5,{area_bomber,3},[{coin,28000}]};
get_data(4176) -> {6,{area_bomber,4},[{coin,38000}]};
get_data(4177) -> {7,{area_bomber,5},[{coin,48000}]}.

