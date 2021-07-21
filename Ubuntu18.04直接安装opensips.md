# Ubuntu18.04直接安装opensips
* 本人实践亲测有效，用docker安装opensips尝试多次均无法连接mysql数据库，故舍弃，直接在主机上安装opensips
* 部分内容参考自：https://www.jianshu.com/p/db19658a02a1
## 创建目录，下载程序解压，切换到解压目录
* opensips目前最新是3.2.x，但由于3.x版本后砍了opensipsctlrc配置项，无法自动生成数据库，官方是3.0后版本推荐手动新增库、新增表2张表，但没看到用户怎么新增，故只实践2.4.11版本。
* [官方推荐的3.x的mysql配置文件以及2张表数据结构，参考，本项目未使用](https://github.com/OpenSIPS/opensips/blob/master/examples/acc-mysql.cfg)
![下载图](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_001.png)

~~~c
# mkdir /home/opensips
# cd /home/opensips
# wget http://download.opensips.org/2.4.11/opensips-2.4.11.tar.gz
//解压
# tar -zxvf opensips-2.4.11.tar.gz
//切换目录
# cd  opensips-2.4.11
~~~

## 安装依赖
~~~c
# apt update
# apt install gcc -y
# apt install g++ -y
# apt install build-essential -y
//mysql必须为5.7版本，服务端已经装好docker，这里就不装了，若要安装，则安装下，要去配置文件中注释监听地址 # 127.0.0.1
// #apt-get install mysql-server 
# apt install mysql-client
# apt install libmysqlclient-dev -y
# apt install pkg-config
# apt install libssl-dev

# apt-get install perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl libfrontier-rpc-perl libterm-readline-gnu-perl libberkeleydb-perl

# apt-get install bison flex libncurses5 libncurses5-dev
~~~

## 编译代码

### 1. mark编译包
~~~c
# make menuconfig
~~~
* mark过程应该不报错，应为这样
![成功mark的提示](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_002.png)

### 2. 进入菜单
![成功进入菜单](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_003.png)
* **操作提示：空格/回车选择，q返回上一级**
#### 2.1 选择mysql模块
* 选择Configure Compile Options，再选择 Configure Excluded Modules，按空格选中安装mysql模块
![选择mysql模块](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_004.png)

#### 2.2 设置配置文件安装位置
* 选择mysql模块后按q返回，选择Configure Install Prefix，回车默认安装在/usr/local/下
![设置配置文件安装位置](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_005.png)

#### 2.3 保存修改
* 选择Save Changes 保存修改，提示需要libmysqlclient-dev不用理会，前面已经安装了
![Save Changes 保存修改](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_006.png)

#### 2.4 编译安装
* 按q返回，选择Compile And Install OpenSIPS后回车，等待3分钟左右编译，正常依赖都装好了不会提示依赖问题，若有提示可能是某依赖装失败了需要重装，按Ctrl+c退出界面后用apt安装包，若包安装失败原因有很多，或许是apt源没配置对ubuntu的版本，又或许是兼容性，具体需要百度查询。
![编译安装](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_007.png)

* 安装完成，提示Press any to return to menuconfig后按Exit & Save All Changes后退出

![安装完成](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_008.png)

## 配置数据库

### 切换目录
~~~c
# cd /usr/local/etc/opensips
~~~

### 编辑opensipsctlrc文件(3.0版本后无此文件)
~~~c
# vim opensipsctlrc
~~~
* 配置项里的内容修改了只对本工具有效，这个工具用来生成opensips数据库和sip的用户名和密码用的工具
![参考文件](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_009.png)

### 登录mysql，创建oepnsips用户
* 登录mysql后，创建opensips要用的新用户opensips，这里用他默认用户名opensips和密码opensipsrw
~~~c
CREATE USER 'opensips'@'%' IDENTIFIED BY 'opensipsrw';

GRANT ALL ON opensips.* TO 'opensips'@'%';

flush privileges;
~~~

### 创建opensips数据库
~~~c
//进入文件夹
# cd /usr/local/sbin
//创建数据库，这时候如果mysql版本为8.0以上的话会列出一系列编码选择，得mysql5.7版本不会出现这问题
opensipsdbctl create
//表创建完成后（提示的两个问题都选n）
~~~
![参考](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_011.png)

* 创建的表结构如下

![表结构](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_010.png)

### 生成特定配置文件
~~~c
//进入目录
# cd /usr/local/etc/opensips
# osipsconfig
~~~
![osipsconfig](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_012.png)

* 操作内容
~~~c
//依次选择—> Generate OpenSIPS Script —> Residential Script —> Configure Residential Script

//选中如下几项[*] ENABLE_TCP[*] USE_AUTH[*] USE_DBACC[*] USE_DBUSRLOC[*] USE_DIALOG

//按q返回，选择 —> Generate Residential Script 回车，生成新的配置文件，文件格式为opensips_residential_xxxxx.cfg，按qqq退出命令，生成新的配置文件
~~~

![osipsconfig](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_013.png)

![osipsconfig](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_014.png)

### 备份旧文件，修改新文件
~~~c
//备份原配置文件
# mv opensips.cfg opensipsold.cfg1
//用生成的opensips_residential_xxx.cfg替换原先的opensips.cfg：
# mv opensips_residential_2021-7-21_6:35:0.cfg opensips.cfg
//编辑新生成的配置文件,修改监听端口和ip,ip把127.0.0.1改为自己的ip，保存
# vim opensips.cfg
~~~
![修改配置文件](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_015.png)

### 注意配置数据库连接,若都用默认且mysql服务在本机可不用配置
* 前面配置的opensipsctlrc只是辅助工具用的不是opensips主程序用的
* 官网说明配置文件opensips.cfg配置数据库方式为，故前一步打开的opensips.cfg文件内有关于mysql相关的配置要修改（可修改地方通常标记CUSTOMIZE ME），比如mysql的地址，端口，库名称按如下格式修改，例如：mysql://root:123456@192.168.1.10:3360/opensips

![数据库连接配置](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/_20210721092841.png)

![修改配置文件](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_016.png)

### 创建账号
~~~c
opensipsctl add 1000 123456  //创建账号1000 密码123456
opensipsctl add 1001 123456  //创建账号1001 密码123456
//创建账号将在表subscriber新增一条记录，也可以在数据库直接修改
~~~

### 常用命令
~~~c
sudo opensipsctl start 启动服务

sudo opensipsctl stop 停止服务

sudo opensipsctl restart 重启服务
~~~

### 启用
~~~c
# opensipsctl start
~~~

### 手机安装软件测试

* 安卓手机可以装个Linphone或者
* 苹果手机可以装个PortSIP UC
* 设置苹果手机账号为1000
<img src="https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/sip_ios.jpg" width="30%" height="auto">
* 设置苹果手机账号为1001
<img src="https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/sip_andriod.jpg" width="30%" height="auto">

* 用苹果手机拨通安卓手机, PortSIP UC通话界面
<img src="https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/call_ios.jpg" width="30%" height="auto">
* 安卓手机, Linphone通话界面
<img src="https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/call_andriod.jpg" width="30%" height="auto">


* 通话完成后在acc表会新增1条INVITE记录和一条BYE记录

![通话记录](https://raw.githubusercontent.com/atorzhang/Document/main/Imgs/20210721_017.png)

### 附录：注意事项，异常项

~~~c
//后面启动时候一直提示：ERROR: PID file /var/run/opensips.pid does not exist -- OpenSIPS start failed
//应该是mysql版本问题，再装一个5.7版本的mysql试试
//docker装mysql5.7  
# docker pull mysql:5.7

# docker run -itd --name mysql57 \
-p 3360:3306 \
-e MYSQL_ROOT_PASSWORD=123456 \
mysql:5.7

//如果创建用户时提示“ERROR: domain unknown: use usernames with domain or set default domain in SIP_DOMAIN”，
//可修改opensipsctlrc文件将SIP_DOMAIN设为本机域名或IP地址

//查看本机apt可安装的mysql版本，如果最新的版本为5.7就安装5.7
apt-cache madison mysql-server
~~~

