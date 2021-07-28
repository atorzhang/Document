#安装docker
cd /home/opensips/package;
echo "开始安装Docker";
sudo dpkg -i containerd.io_1.4.6-1_amd64.deb
sudo dpkg -i docker-ce-cli_20.10.7_3-0_ubuntu-xenial_amd64.deb
sudo dpkg -i docker-ce_20.10.7_3-0_ubuntu-xenial_amd64.deb
echo "完成安装Docker";
#docker安装mysql5.7,设置默认密码为123qwe!，数据存放位置/home/mysql57/data
echo "开始安装Mysql5.7";
sudo docker load -i mysql57.tar;
sudo docker run --name mysql57 --restart=always -v /home/mysql57/data:/var/lib/mysql --privileged=true -e MYSQL_ROOT_PASSWORD=123qwe! -d -i -p 3306:3306  mysql:5.7;
echo "完成安装Mysql5.7";
echo "开始安装opensips";
#用docker安装opensips
sudo docker load -i opensips.tar;
#运行容器
sudo docker run -d -it --name sip --restart=always -p 5060:5060/udp -v /home/opensips/opensips.cfg:/etc/opensips/opensips.cfg 459741134/opensips2.4_with_mysql_rest:latest;
echo "完成安装opensips";
echo "全部安装完成";