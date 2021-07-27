#安装docker
echo "开始安装Docker";
sudo apt-get update;
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common;
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable";
sudo apt-get update;
sudo apt-get install docker-ce -y;
docker --version;
echo "完成安装Docker";
#docker安装mysql5.7,设置默认密码为123qaq321，数据存放位置/home/mysql57/data
echo "开始安装Mysql5.7";
sudo docker pull mysql:5.7;
sudo docker run --name mysql57 --restart=always -v /home/mysql57/data:/var/lib/mysql --privileged=true -e MYSQL_ROOT_PASSWORD=123qaq321 -d -i -p 3360:3306  mysql:5.7;
echo "完成安装Mysql5.7";
echo "开始安装opensips";
#用docker安装opensips
sudo docker pull 459741134/opensips2.4_with_mysql_rest:latest;
#运行容器
sudo docker run -d -it --name sip -p 5060:5060/udp -v /home/opensips/opensips.cfg:/etc/opensips/opensips.cfg 459741134/opensips2.4_with_mysql_rest:latest;
echo "完成安装opensips";
echo "全部安装完成";