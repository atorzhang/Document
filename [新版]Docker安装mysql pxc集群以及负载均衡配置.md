# [新版]Docker安装mysql8.0 pxc集群以及负载均衡配置
参考博客:[docker安装pxc集群_fly7632785的专栏-CSDN博客](https://blog.csdn.net/fly7632785/article/details/114025288)
## 1.环境配置
* 部署的mysql集群为pxc模式,该模式下所有mysql主机都为主,都可以同步数据到其他mysql主机,同步完成后才算操作成功,可用性高
* 2台主机系统为unbuntu18.04(centos装了docker大部分操作都一直,nginx相关配置可能有所不同),pc1为集群master主机,都安装了docker环境version 20.10.7

|主机 | ip地址 | 系统|
|-|-|-|
|pc1|192.168.3.119|ubuntu18.04|
|pc2|192.168.3.139|ubuntu18.04|

### 1.1.<font color=#D2691E>所有主机</font>都开放如下防火墙端口
* 如下端口是PXC集群之间互相通信时要用到的端口
~~~c
//pxc所需端口
# firewall-cmd --zone=public --add-port=3306/tcp --permanent
# firewall-cmd --zone=public --add-port=4567/tcp --permanent
# firewall-cmd --zone=public --add-port=4444/tcp --permanent
# firewall-cmd --zone=public --add-port=4568/tcp --permanent
//docker集群所需端口
# firewall-cmd --zone=public --add-port=2377/tcp --permanent
# firewall-cmd --zone=public --add-port=4789/tcp --permanent
# firewall-cmd --zone=public --add-port=7946/tcp --permanent
//自定义的dokcer映射mysql端口
# firewall-cmd --zone=public --add-port=9001/tcp --permanent

# firewall-cmd --reload
~~~

* 附防火墙操作方法
~~~c
//查询防火墙状态
# systemctl status firewalld
//查询防火墙状态
# firewall-cmd --state
// 查询8080端口是否开放
# firewall-cmd --query-port=8080/tcp
// 开放80端口
# firewall-cmd --permanent --add-port=80/tcp
//移除端口8080
# firewall-cmd --permanent --remove-port=8080/tcp
~~~

### 1.2 <font color=#D2691E>所有主机</font>都拉取percona/percona-xtradb-cluster:8.0.23
~~~c
# docker pull percona/percona-xtradb-cluster:8.0.23
~~~

### 1.3 <font color=#D2691E>所有主机</font>都将刚下载的镜像重命名镜像为pxc
~~~c
# docker tag percona/percona-xtradb-cluster:8.0.23 pxc
# docker rmi percona/percona-xtradb-cluster:8.0.23
//若有强迫症可删除pxc更名前的源镜像
~~~

### 1.4 <font color=#D2691E>所有主机</font>都创建目录
~~~c
//证书
# mkdir -m 777 /docker/pxc/pxc_cert 
//mysql自定义配置文件
# mkdir -m 777 /docker/pxc/pxc_config
//数据
# mkdir -m 777 /docker/pxc/pxc_data      
~~~

### 1.5 <font color=#D2691E>所有主机</font>都创建custom.cnf文件
~~~c
# cd /docker/pxc/pxc_config
# vi custom.cnf 
~~~
* custom.cnf内容如下
~~~c
[mysqld]
lower_case_table_names=0
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
ssl-ca = /cert/ca.pem
ssl-cert = /cert/server-cert.pem
ssl-key = /cert/server-key.pem

[client]
ssl-ca = /cert/ca.pem
ssl-cert = /cert/client-cert.pem
ssl-key = /cert/client-key.pem

[sst]
encrypt = 4
ssl-ca = /cert/ca.pem
ssl-cert = /cert/server-cert.pem
ssl-key = /cert/server-key.pem
~~~
### 1.6 单主机<font color=#D2691E>pc1</font>创建pxc需要的证书,建好拷贝到其他主机
~~~c
# docker run --name pxc-cert --rm -v /docker/pxc/pxc_cert:/cert \
pxc mysql_ssl_rsa_setup -d /cert
~~~
* 给所有证书文件权限
~~~c
# cd /docker/pxc/pxc_cert
# chmod 777 *
~~~
* **注意: 创建好证书后在/docker/pxc/pxc_cert目录下将出现8个.pem文件,将这些文件全部拷贝到集群其他服务器同目录,并给所有证书文件权限**

## 2. Docker集群配置(若已配置可忽略)

### 2.1 单主机<font color=#D2691E>pc1</font>创建并初始化集群
~~~c
// 初始化集群,若提示This node is already part of a swarm. Use "docker swarm leave" to leave this swarm and join another one则表示已经创建了
# docker swarm init
~~~

### 2.2 单主机<font color=#D2691E>pc2</font>加入集群
~~~c
// 若上一步成功执行,则复制docker集群加入语句到这边执行,语句类似,若还有其他主机,则都加入
# docker swarm join --token xxxxxx ip地址+端口结尾
~~~

### 2.3 单主机<font color=#D2691E>pc1</font>创建集群网络
~~~c
# docker network create -d overlay --attachable swarm_mysql
~~~

## 3. Mysql pxc集群配置

### 3.1 单主机<font color=#D2691E>pc1</font>执行命令创建mysql

* 运行容器创建mysql集群
~~~c
# docker run -d -p 9001:3306  \
-e MYSQL_ROOT_PASSWORD=123qwe@ \
-e CLUSTER_NAME=pxc_cluster \
-e XTRABACKUP_PASSWORD=123qwe@ \
-v /docker/pxc/pxc_data:/var/lib/mysql \
-v /docker/pxc/pxc_cert:/cert \
-v /docker/pxc/pxc_config:/etc/percona-xtradb-cluster.conf.d  \
--privileged \
--name=pxc1 \
--net=swarm_mysql \
pxc
~~~

### 3.2 单主机<font color=#D2691E>pc2</font>执行,确保上一步成功执行(外部可连接pc1创建的mysql)后再执行以下语句

* 运行容器加入mysql集群
~~~c
# docker run -d -p 9001:3306 \
-e MYSQL_ROOT_PASSWORD=123qwe@ \
-e CLUSTER_NAME=pxc_cluster \
-e XTRABACKUP_PASSWORD=123qwe@ \
-e CLUSTER_JOIN=pxc1 \
-v /docker/pxc/pxc_data:/var/lib/mysql \
-v /docker/pxc/pxc_cert:/cert \
-v /docker/pxc/pxc_config:/etc/percona-xtradb-cluster.conf.d  \
--privileged \
--name=pxc2 \
--net=swarm_mysql \
pxc
~~~

### 3.3 完成docker mysql pxc集群创建,若还有其他主机,按照上面pc2配置修改下继续执行即可
* 可测试修改一个主机库表内的数据另一个主机库表内的数据也同步修改了

## 4.配置nginx对mysql集群进行负载均衡(可选)

* 在主机pc1做为mysql服务入口,以下操作在pc1执行
* 在目录 /etc/nginx 目录下编辑nginx.conf文件,在http节点结束后新增一个stream节点(注意和http节点是同级别)
~~~
# cd /etc/nginx
# vi nginx.conf
~~~

* 编辑内容参考
~~~
http {
  //原来节点内容
}
stream {
    include vstream/*.conf;
}
~~~

* 创建vstream目录
~~~c
# mkdir vstream
# cd vstream
~~~

* 创建mysql.conf文件
~~~c
# vi mysql.conf
~~~

* 复制内容如下,若还有其他mysql示例则在这补充
~~~c
upstream mysql_server {
  server 192.168.3.119:9001 max_fails=3 fail_timeout=30s;
  server 192.168.3.139:9001 max_fails=3 fail_timeout=30s;
}
server {
 listen 33066;
 proxy_pass mysql_server;
}
~~~

* 保存mysql.conf文件,:wq回车保存
~~~c
# :wq +回车
~~~

* 重启nginx
~~~c
# service nginx restart
~~~

* 即可使用33066来负载均衡访问mysql集群

