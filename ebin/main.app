{application, main,
    [
        {description, "server"},
        {vsn, "0.1"},
        {modules, []},
        {registered, [main]},
        {applications, [kernel, stdlib]},
        {mod, {main, []}},
        {start_phases, []},
        {env, [
                {server_no, 1}
                ,{port, 8001}  %% 游戏端口
                ,{web_port, 10000} %%后台端口
                ,{game_ready, true} %%是否开放端口
                ,{gm, false} %%是否开放GM
                ,{ip, "127.0.0.1"}   %% 自己的ip
                ,{web_ip, [{192, 168, 0, 152}, {192, 168, 0, 123}, {120,76,28,170}, {134,175,80,79}, {127, 0, 0, 1}]}  %% 游戏后台ip

                %% 聚合信息
                ,{juhekey, "ae02449fa59b713e8927ed270998cbfd"} %% %%聚合礼品卡key
                ,{juheopenid, "JH59ef701f72c4e1c3cbc991266f36862a"} %% %%聚合openid
                ,{juheacc, "13428281"} %% 聚合账号
                ,{juhetpl, "93167"}  %% 聚合信息模板
                ,{juhesjkey, "e6e821af0efadc521ba4fbf07d51533a"}  %% 聚合话费直冲key
                ,{juhemsgkey, "a8443292c5d8f5cd7ea14f49ac940c4e"} %% 聚合短信的key

                %% 登陆公众号
                ,{loginAppId, "wx6550285d3b5d797f"}                  
                ,{loginAppSecret, "b5cb3a1b3b0891aca88106175ac7f4d2"}
                %% 红包公众号，商户号，密匙
                ,{redAppId, "wx5f94b1370d1abdb8"}
                ,{redAppSecret, "6c7363f45828132c63f2a05577b7d74f"}
                ,{redMachId, "1511880951"}
                ,{redMachKey, "d9oPC3A6VI17J7vxtB3v98DGqUw12N7J"}
                %% 官方支付公众号，商户号，密匙
                ,{payAppId, "wxc1384a875174cb3c"}
                ,{payAppSecret, "72290d6096f0eb490fc29389c04c46f3"}
                ,{payMachId, "174520003257"}
                ,{payMachKey, "7a465c9d4eb2c9f37a3e2bcfc1e65933"}
                %% 易宝
                ,{ybMachId, "8901108436"}
                ,{ybMachKey, "gHuytl9eEKDihaXcptxqlPqa8Vo9wju5"}
                %% 摇钱树
                ,{yqsMachId, "10000240"}
                ,{yqsMachKey, "a47f3edf4egf65356gad016c4e46e5f4"}
                %% 个人码
                ,{paysapi_uid, ""}
                ,{paysapi_token, ""}
                ,{robot, []}
                ,{db_cfg,                          %% 数据库配置
                        {
                        "127.0.0.1"                  %% ip
                        ,3306                        %% 端口
                        ,"root"                      %% 用户名
                        ,"123456"                    %% 密码
                        ,"guess_new"                 %% 表名
                        ,utf8mb4                     %% 数据格式
                        ,5                           %% 最小连接数
                        ,10                          %% 最大连接数
                      }
                }
            ]}
    ]
}.
