# Docker安装redis集群
参考来自博客 [Docker 搭建 Redis Cluster 集群环境 - 哈喽沃德先生 - 博客园](https://www.cnblogs.com/mrhelloworld/p/docker12.html)

## 1.环境配置
* 2台主机系统为unbuntu18.04(centos装了docker大部分操作都一致),都安装了docker环境version 20.10.7

|主机 | ip地址 | 系统|
|-|-|-|
|pc1|192.168.3.119|ubuntu18.04|
|pc2|192.168.3.139|ubuntu18.04|

## 2.创建目录及文件
* 分别在 192.168.3.119 和 192.168.3.139 两台机器上执行以下操作。
~~~c
//创建目录
# mkdir -p /docker/redis
//切换至指定目录
# cd /docker/redis
//编写 redis-cluster.tmpl 文件
# vi redis-cluster.tmpl
~~~
* 192.168.3.119 机器的 redis-cluster.tmpl 文件内容如下：
~~~c
port ${PORT}
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 192.168.3.119
cluster-announce-port ${PORT}
cluster-announce-bus-port 1${PORT}
~~~
* 192.168.3.139 机器的 redis-cluster.tmpl 文件内容如下：
~~~c
port ${PORT}
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 192.168.3.139
cluster-announce-port ${PORT}
cluster-announce-bus-port 1${PORT}
~~~
* <font color=#D2691E>注意:这里用到2个端口,637x以及1637x,确保防火墙都可以通过 </font>

## 3.执行命令初始化配置环境
* 在 192.168.3.119 机器的/docker/redis目录下执行以下命令
~~~c
for port in `seq 6371 6373`; do \
  mkdir -p ${port}/conf \
  && PORT=${port} envsubst < redis-cluster.tmpl > ${port}/conf/redis.conf \
  && mkdir -p ${port}/data;\
done
~~~
* 在 192.168.3.139 机器的/docker/redis目录下执行以下命令：
~~~c
for port in `seq 6374 6376`; do \
  mkdir -p ${port}/conf \
  && PORT=${port} envsubst < redis-cluster.tmpl > ${port}/conf/redis.conf \
  && mkdir -p ${port}/data;\
done
~~~

## 4.创建容器
* 在 192.168.3.119 机器执行以下命令：
~~~c
for port in $(seq 6371 6373); do \
  docker run -di --restart always --name redis-${port} --net host \
  -v /docker/redis/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
  -v /docker/redis/${port}/data:/data \
  redis redis-server /usr/local/etc/redis/redis.conf; \
done
~~~
* 在 192.168.3.139 机器执行以下命令：
~~~c
for port in $(seq 6374 6376); do \
  docker run -di --restart always --name redis-${port} --net host \
  -v /docker/redis/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
  -v /docker/redis/${port}/data:/data \
  redis redis-server /usr/local/etc/redis/redis.conf; \
done
~~~
## 5.创建redis集群
* 随便进入一个容器节点，并进入 /usr/local/bin/ 目录
~~~c
//进入容器
# docker exec -it redis-6371 bash
//切换至指定目录
# cd /usr/local/bin/
~~~
* 通过Redis Cluster 创建集群,自动会分配主从库,可观察哪个是主哪个是从,把主库拿出来用nginx负债均衡
~~~c
redis-cli -a 1234 --cluster create 192.168.3.119:6371 192.168.3.119:6372 192.168.3.119:6373 192.168.3.139:6374 192.168.3.139:6375 192.168.3.139:6376 --cluster-replicas 1
~~~
* 检测集群状态
~~~c
redis-cli -a 1234 --cluster check 192.168.3.119:6371
~~~