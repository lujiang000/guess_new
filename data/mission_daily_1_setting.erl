%% 文件根据Excel配置表自动生成,修改可能会产生意外的问题,并且任何改动将在文件重新生成时丢失
%% 每日任务
-module(mission_daily_1_setting).
-export([
		get_data/1
		,get_level/1
		,get_all/0
	]).

%% 获取所有id列表
get_all() -> [1000,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1046,1047,1048,1049,1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070,1071,1072,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093,1094].


%% 获取指定类型的id列表
get_level(1) -> [1000,1001,1002,1006,1007,1008,1012,1013,1014,1015,1019,1020,1021,1022,1026,1027,1028,1029,1033,1041];
get_level(2) -> [1003,1004,1005,1009,1010,1011,1016,1017,1018,1023,1024,1025,1030,1031,1032,1034,1035,1036,1037,1042,1043];
get_level(3) -> [1038,1039,1040,1044,1045,1073,1074,1075,1079,1080,1085,1086];
get_level(4) -> [1046,1047,1048,1049,1064,1065,1066,1076,1077,1081,1082,1083,1087,1088,1089,1091];
get_level(5) -> [1050,1051,1055,1067,1078,1084,1090,1092];
get_level(6) -> [1052,1053,1056,1057,1058,1061,1068,1069,1070,1093];
get_level(7) -> [1054,1059,1060,1062,1063,1071,1072,1094].


%% 根据id获取一条数据
%% 1 任务id
%% 2 任务等级
%% 3 动物
%% 4 奖励列表
get_data(1000) -> {1,{turtle,10},[{coin,8}]};
get_data(1001) -> {1,{turtle,12},[{locking,1}]};
get_data(1002) -> {1,{turtle,14},[{coin,18}]};
get_data(1003) -> {2,{turtle,16},[{locking,1}]};
get_data(1004) -> {2,{turtle,18},[{coin,20}]};
get_data(1005) -> {2,{turtle,20},[{locking,1}]};
get_data(1006) -> {1,{cock,15},[{ice,1}]};
get_data(1007) -> {1,{cock,16},[{coin,30}]};
get_data(1008) -> {1,{cock,17},[{ice,1}]};
get_data(1009) -> {2,{cock,18},[{coin,60}]};
get_data(1010) -> {2,{cock,19},[{ice,1}]};
get_data(1011) -> {2,{cock,20},[{coin,88}]};
get_data(1012) -> {1,{dog,8},[{locking,1}]};
get_data(1013) -> {1,{dog,10},[{coin,30}]};
get_data(1014) -> {1,{dog,12},[{locking,1}]};
get_data(1015) -> {1,{dog,14},[{coin,40}]};
get_data(1016) -> {2,{dog,16},[{locking,1}]};
get_data(1017) -> {2,{dog,18},[{coin,50}]};
get_data(1018) -> {2,{dog,20},[{locking,1}]};
get_data(1019) -> {1,{monkey,8},[{coin,30}]};
get_data(1020) -> {1,{monkey,10},[{locking,1}]};
get_data(1021) -> {1,{monkey,11},[{coin,48}]};
get_data(1022) -> {1,{monkey,12},[{locking,1}]};
get_data(1023) -> {2,{monkey,13},[{coin,50}]};
get_data(1024) -> {2,{monkey,14},[{trumpet,1}]};
get_data(1025) -> {2,{monkey,15},[{coin,60}]};
get_data(1026) -> {1,{horse,8},[{ice,1}]};
get_data(1027) -> {1,{horse,10},[{coin,80}]};
get_data(1028) -> {1,{horse,11},[{ice,1}]};
get_data(1029) -> {1,{horse,12},[{coin,90}]};
get_data(1030) -> {2,{horse,13},[{auto,1}]};
get_data(1031) -> {2,{horse,14},[{trumpet,1}]};
get_data(1032) -> {2,{horse,15},[{rage,1}]};
get_data(1033) -> {1,{ox,6},[{coin,30}]};
get_data(1034) -> {2,{ox,8},[{coin,32}]};
get_data(1035) -> {2,{ox,10},[{coin,35}]};
get_data(1036) -> {2,{ox,11},[{coin,38}]};
get_data(1037) -> {2,{ox,12},[{coin,40}]};
get_data(1038) -> {3,{ox,13},[{coin,42}]};
get_data(1039) -> {3,{ox,14},[{coin,45}]};
get_data(1040) -> {3,{ox,15},[{coin,50}]};
get_data(1041) -> {1,{panda,3},[{coin,30}]};
get_data(1042) -> {2,{panda,4},[{coin,32}]};
get_data(1043) -> {2,{panda,5},[{coin,35}]};
get_data(1044) -> {3,{panda,6},[{coin,38}]};
get_data(1045) -> {3,{panda,7},[{coin,40}]};
get_data(1046) -> {4,{panda,8},[{coin,42}]};
get_data(1047) -> {4,{panda,9},[{coin,45}]};
get_data(1048) -> {4,{panda,10},[{coin,50}]};
get_data(1049) -> {4,{hippo,5},[{coin,125}]};
get_data(1050) -> {5,{hippo,6},[{coin,150}]};
get_data(1051) -> {5,{hippo,7},[{coin,175}]};
get_data(1052) -> {6,{hippo,8},[{coin,200}]};
get_data(1053) -> {6,{hippo,9},[{coin,225}]};
get_data(1054) -> {7,{hippo,10},[{coin,250}]};
get_data(1055) -> {5,{lion,5},[{gold,2}]};
get_data(1056) -> {6,{lion,6},[{gold,3}]};
get_data(1057) -> {6,{lion,7},[{gold,3}]};
get_data(1058) -> {6,{lion,8},[{gold,4}]};
get_data(1059) -> {7,{lion,9},[{gold,4}]};
get_data(1060) -> {7,{lion,10},[{gold,5}]};
get_data(1061) -> {6,{elephant,1},[{coin,250}]};
get_data(1062) -> {7,{elephant,2},[{coin,500}]};
get_data(1063) -> {7,{elephant,3},[{coin,750}]};
get_data(1064) -> {4,{pikachu,3},[{horn,1}]};
get_data(1065) -> {4,{pikachu,4},[{rage,1}]};
get_data(1066) -> {4,{pikachu,5},[{trumpet,1}]};
get_data(1067) -> {5,{pikachu,6},[{auto,1}]};
get_data(1068) -> {6,{pikachu,8},[{auto,1}]};
get_data(1069) -> {6,{pikachu,10},[{auto,1}]};
get_data(1070) -> {6,{bomber,1},[{coin,30}]};
get_data(1071) -> {7,{bomber,2},[{coin,40}]};
get_data(1072) -> {7,{bomber,3},[{coin,50}]};
get_data(1073) -> {3,{type_bomber,3},[{gold,1}]};
get_data(1074) -> {3,{type_bomber,4},[{gold,2}]};
get_data(1075) -> {3,{type_bomber,5},[{gold,3}]};
get_data(1076) -> {4,{type_bomber,6},[{gold,4}]};
get_data(1077) -> {4,{type_bomber,8},[{gold,5}]};
get_data(1078) -> {5,{type_bomber,10},[{gold,6}]};
get_data(1079) -> {3,{xsx,3},[{horn,1}]};
get_data(1080) -> {3,{xsx,4},[{rage,1}]};
get_data(1081) -> {4,{xsx,5},[{trumpet,1}]};
get_data(1082) -> {4,{xsx,6},[{auto,1}]};
get_data(1083) -> {4,{xsx,8},[{auto,1}]};
get_data(1084) -> {5,{xsx,10},[{auto,1}]};
get_data(1085) -> {3,{dsy,3},[{coin,45}]};
get_data(1086) -> {3,{dsy,4},[{auto,1}]};
get_data(1087) -> {4,{dsy,5},[{coin,75}]};
get_data(1088) -> {4,{dsy,6},[{auto,1}]};
get_data(1089) -> {4,{dsy,8},[{coin,120}]};
get_data(1090) -> {5,{dsy,10},[{gold,2}]};
get_data(1091) -> {4,{area_bomber,2},[{coin,118}]};
get_data(1092) -> {5,{area_bomber,3},[{coin,128}]};
get_data(1093) -> {6,{area_bomber,4},[{coin,158}]};
get_data(1094) -> {7,{area_bomber,5},[{coin,168}]}.

