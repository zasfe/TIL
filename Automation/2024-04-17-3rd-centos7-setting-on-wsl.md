# [[2024.04.17] ansible 2일차 - wsl 에서 다수 컨테이너 환경 구성](2024-04-17-3rd-centos7-setting-on-wsl.md)

> 3장은 테스트 서버 3개가 필요하여 세팅간 오류를 잡아서 시간이 많아 소모됨

```bash
docker run -d --privileged --name ws01 centos:centos7 /usr/sbin/init
docker run -d --privileged --name ws02 centos:centos7 /usr/sbin/init
docker run -d --privileged --name db01 centos:centos7 /usr/sbin/init

cat <<EOF > ./centos7_vagrant
mv /usr/bin/systemctl /usr/bin/systemctl.old
curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl
chmod +x /usr/bin/systemctl
yum install -y iproute net-tools openssh-server sudo;
ssh-keygen -A;
systemctl enable sshd; systemctl start sshd;
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config
useradd vagrant
echo "vagrant" \| passwd --stdin vagrant
chmod u+w /etc/sudoers.d
echo "vagrant        ALL=NOPASSWD:       ALL" >> /etc/sudoers.d/vagrant
chmod u-w /etc/sudoers.d
EOF

docker cp ./centos7_vagrant ws01:/root/centos7_vagrant.sh
docker exec -u 0 ws01 /bin/bash /root/centos7_vagrant.sh

docker cp ./centos7_vagrant ws02:/root/centos7_vagrant.sh
docker exec -u 0 ws02 /bin/bash /root/centos7_vagrant.sh

docker cp ./centos7_vagrant db01:/root/centos7_vagrant.sh
docker exec -u 0 db01 /bin/bash /root/centos7_vagrant.sh

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa_vagrant_centos7.pub vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa_vagrant_centos7.pub vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa_vagrant_centos7.pub vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01`


cat <<EOF > ./hosts
[web]
ws01.fale.io
ws02.fale.io

[db]
db01.fale.io
EOF

echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01` ws01.fale.io" >> /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02` ws02.fale.io" >> /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` db01.fale.io" >> /etc/hosts
```
