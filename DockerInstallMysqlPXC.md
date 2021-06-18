# Docker安装mysql pxc集群以及负载均衡配置
参考博客 [Docker多机集群部署之MySQL集群(PXC)_南半球首席搬砖师的博客-CSDN博客_docker pxc多主机](https://blog.csdn.net/weixin_43960618/article/details/107619765)
## 1.环境配置
* 部署的mysql集群为pxc模式,该模式下所有mysql主机都为主,都可以同步数据到其他mysql主机,同步完成后才算操作成功,可用性高
* 2台主机系统为unbuntu18.04(centos装了docker大部分操作都一直,nginx相关配置可能有所不同),都安装了docker环境version 20.10.7

|主机 | ip地址 | 系统|
|-|-|-|
|pc1|192.168.3.119|ubuntu18.04|
|pc2|192.168.3.139|ubuntu18.04|

## 2.<font color=#D2691E>所有主机</font>都拉取最新mysql镜像
~~~c
# docker pull mysql:latest
~~~

## 3. <font color=#D2691E>所有主机</font>都拉取percona/percona-xtradb-cluster:5.6镜像,一定是5.6版本不然需要k8s环境
~~~c
# docker pull percona/percona-xtradb-cluster:5.6
~~~

## 4. <font color=#D2691E>所有主机</font>都将刚下载的镜像重命名镜像为pxc
~~~c
# docker tag percona/percona-xtradb-cluster:5.6 pxc
# docker rmi percona/percona-xtradb-cluster:5.6 //若有强迫症可删除pxc更名前的源镜像
~~~

## 5. <font color=#D2691E>所有主机</font>都创建本机目录,并赋予目录权限,用于docker映射目录
~~~c
# mkdir -p /docker/pxc/mysql /docker/pxc/data
# cd /docker/pxc
# chmod 777 mysql
# chmod 777 data
~~~

## 6. 单主机<font color=#D2691E>pc1</font>执行命令创建mysql,需要外部可连接mysql后才能执行下一步
~~~c
# docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -e CLUSTER_NAME=PXC -e XTRABACKUP_PASSWORD=123456 --restart=always -v /docker/pxc/mysql:/var/lib/mysql -v /docker/pxc/data:/data  --privileged --name=db1 --net=host pxc
# netstat -nultp -p //看到3306端口已经开启了就可以执行下一步
~~~

## 7. 单主机<font color=#D2691E>pc2</font>执行,确保上一步成功执行后在执行以下语句
~~~c
# docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -e CLUSTER_NAME=PXC -e XTRABACKUP_PASSWORD=123456 -e CLUSTER_JOIN=192.168.3.119 --restart=always -v /docker/pxc/mysql:/var/lib/mysql -v /docker/pxc/data:/data --privileged --name=db2 --net=host pxc
~~~
### 若还有其他主机,按照上面pc2配置修改下继续执行即可

## 8. 完成docker mysql pxc集群创建
* 可测试修改一个主机库表内的数据另一个主机库表内的数据也同步修改了

## 9.配置nginx对mysql集群进行负载均衡(可选)
~~~c
// 在主机pc1做为mysql服务入口,以下操作在pc1执行
// 在目录 /etc/nginx 目录下编辑nginx.conf文件,在http节点结束后新增一个stream节点(注意和http节点是同级别)
# cd /etc/nginx
# vi nginx.conf
//编辑内容参考开始
http {
  //原来节点内容
}
stream {
    include vstream/*.conf;
}
//编辑内容参考结束
//创建vstream目录
#mkdir vstream
#cd vstream
//创建mysql.conf文件
# vi mysql.conf
//复制内容如下,若还有其他mysql示例则在这补充
upstream mysql_server {
  server 192.168.3.119:3306 max_fails=3 fail_timeout=30s;
  server 192.168.3.139:3306 max_fails=3 fail_timeout=30s;
}
server {
 listen 33066;
 proxy_pass mysql_server;
}
# :wq //:wq回车保存
//重启nginx
# service nginx restart
//即可使用33066来负载均衡访问mysql集群
~~~ 
