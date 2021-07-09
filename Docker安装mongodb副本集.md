# Docker安装mongodb副本集
## 1.环境配置
* 部署的mongodb集群为副本集模式,该模式下只有一台mongo服务作为主服务器,其他都为副本集和一台仲裁服务,当主服务挂了仲裁服务检测到将自动切换副服务为临时的主服务.
* 2台主机系统为unbuntu18.04(centos装了docker大部分操作都一直,nginx相关配置可能有所不同),都安装了docker环境version 20.10.7

|主机 | ip地址 | 系统|
|-|-|-|
|pc1|192.168.3.119|ubuntu18.04|
|pc2|192.168.3.139|ubuntu18.04|

## 2.文件准备
* 
* 在pc1(192.168.3.119)上创建目录,作为主服务

~~~c
# mkdir /docker/mongo/db0
//在db0下新建2个文件夹
# cd /docker/mongo/db0
# mkdir configdb db 
//在configdb文件夹内新增配置文件mongod.conf
# cd configdb
# vi mongod.conf
~~~
* mongod.conf文件配置如下
~~~c
net:
 port: 27017 # 这是启动端口
 bindIp: 0.0.0.0 # 允许哪些ip连接（好像和下面的命令参数 --bind_ip_all 相类似的作用）
systemLog:
 logAppend: true # 重新启动的mongodb的时候日志拼接在以前的日志文件上，不用新建
replication:
 replSetName: "rs" # 副本集的名称
~~~

* 在pc2(192.168.3.139)上创建目录,作为备用服务和仲裁服务
~~~c
# mkdir /docker/mongo/db2  /docker/mongo/db3
//在db2和db3下新建2个文件夹
# cd /docker/mongo/db2
# mkdir configdb db
//在configdb文件夹内新增配置文件mongod.conf,配置内容同上面
# cd configdb
# vi mongod.conf
~~~

## 3.创建容器
* 若没有mongo镜像需要先拉取下镜像,有了可忽略以下步骤
~~~c
# docker pull mongo
~~~

* 主机pc1(192.168.3.119)执行,生成1个容器用作主服务
~~~c
# docker run -di --name=mongo0 -p 27001:27017 --restart=always -v /docker/mongo/db0/configdb:/data/configdb/ -v /docker/mongo/db0/db:/data/db mongo --replSet "rs" --bind_ip_all -f /data/configdb/mongod.conf
~~~
* 主机pc2(192.168.3.139)执行,生成2个mogno容器
~~~c
# docker run -di --name=mongo2 -p 27003:27017 --restart=always -v /docker/mongo/db2/configdb:/data/configdb/ -v /docker/mongo/db2/db:/data/db mongo --replSet "rs" --bind_ip_all -f /data/configdb/mongod.conf

# docker run -di --name=mongo3 -p 27004:27017 --restart=always -v /docker/mongo/db3/configdb:/data/configdb/ -v /docker/mongo/db3/db:/data/db mongo --replSet "rs" --bind_ip_all -f /data/configdb/mongod.conf
~~~

## 4.创建集群

* 在pc1进入容器mongo0内执行
~~~c
//进入容器命令
# docker exec -it mongo0 /bin/bash
//进入容器中执行
# mongo
//创建集群,priority为优先级,高到低,当主服务宕机,
//通过这个值去判断哪个从服务升级为临时主服务
//arbiterOnly指定哪个为仲裁节点
# rs.initiate(
{"_id":"rs",members:
[{_id:0,host:"192.168.3.119:27001",priority:9},
{_id:1,host:"192.168.3.139:27003",priority:1},
{_id:2,host:"192.168.3.139:27004",arbiterOnly:true}]
});
//返回ok就成功了
//查看集群状态
# rs.status();
~~~

* 在pc1中创建用户名和密码
~~~c
//在刚才mongo环境下继续执行
# use admin;
//创建账户,这样就可以用这个用户名去登录mongo客户端了
# db.createUser({ user: 'admin', pwd: 'admin123456', roles: [ { role: "root", db: "admin" } ] });
~~~