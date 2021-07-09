# Docker部署RTM服务

## 1. 发布RTM

### 1.1 发布方式
* 采用vs的文件发布方式

### 1.2 发布
* 发布FJRH.RTM.Service项目到一个文件夹

## 2. 部署RTM

### 2.1 复制文件
* 将上面发布的文件夹下的所有内容,复制到ubuntu集群所有主机的目录/var/www/rtm

### 2.2 构建Docker镜像
* cd到rtm所在目录
~~~c
# cd /var/www/rtm
~~~

* 生成docker镜像(注意最后有个点,生成成功提示:Successfully tagged rtm:1.0.0)
~~~c
# docker build -t  rtm:1.0.0 .
~~~

### 2.3 运行Docker容器
* 运行命令,映射appsettings.json和Log目录到容器,--restart=always设置为挂了自动重启
~~~c
# docker run --name rtm \
-itd \
--restart=always \
-p 58000:58000 \
-v /var/www/rtm/appsettings.json:/app/appsettings.json \
-v /var/www/rtm/Log:/app/Log \
rtm:1.0.0
~~~

* 查看容器是否启动,若看到Names=rtm的记录且状态为UP* 则启动成功,完成docker部署
~~~c
# docker ps
//若上面命令看不到rtm这条记录就运行
# docker ps -a
~~~

* 若上一步rtm容器状态不为UP * ,需要查看错误日志,运行
~~~c
# docker logs rtm
~~~

### 2.4 更新RTM程序
* rtm程序由于使用nginx做负载均衡,故可以实现热更新,即一个服务停止了去更新,另一个旧服务还在运行.当一个服务更新完后再去更新下一个服务.直到集群内所有服务都更新完毕

#### 2.4.1 更新RTM程序大致步骤
| 顺序 | 内容                      |
| ---- | ------------------------- |
| 1    | 发布rtm程序,复制到ubuntu,构建新版本的RTM镜像 |
| 2    | 停止运行中的rtm容器 |
| 3    | 删除rtm容器 |
| 4    |  [可选]删除旧版本rtm镜像 |
| 5    |  运行新镜像生成新的rtm容器 |


#### 2.4.2 具体更新操作
1. 重复之前的2.1和2.2步骤,把2.2中生成镜像命令的版本号修改为rtm:1.0.1
2. 停止运行中的rtm容器
~~~
# docker stop rtm
~~~
3. 删除rtm容器
~~~
# docker rm rtm
~~~
4. [可选]删除旧版本rtm镜像
~~~
# docker rmi rtm:1.0.0
~~~
5. 运行新镜像(前面生成1.0.1版本)生成新的rtm容器
~~~
# docker run --name rtm \
-itd \
--restart=always \
-p 58000:58000 \
-v /var/www/rtm/appsettings.json:/app/appsettings.json \
-v /var/www/rtm/Log:/app/Log \
rtm:1.0.1
~~~
6. 用之前的命令docke ps检测是否运行成功,若成功则继续更新集群中的其他主机rtm服务