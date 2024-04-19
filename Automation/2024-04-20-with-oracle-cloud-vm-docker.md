# oracle vm + docker 상황에서 사용

* 교재: Learning Ansible 2.7 - Third Edition [(packtpub)](https://www.packtpub.com/product/learning-ansible-27-third-edition/9781789954333) [(github)](https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition) - [(Chapter03)](https://subscription.packtpub.com/book/cloud-and-networking/9781789954333/5/ch05lvl1sec27/working-with-inventory-files)
* Code: https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition/tree/master/Chapter03.

## container 공통 설정 파일 생성 및 실행

* 처음 ssh 접속할 때 known_host 등록 알림 방지용 옵션 추가 필요함 - %%-o StrictHostKeyChecking=no%%


```bash
cat <<EOF > ./centos7_vagrant
mv /usr/bin/systemctl /usr/bin/systemctl.old;
curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl;
chmod +x /usr/bin/systemctl;
yum install -y iproute net-tools openssh-server sudo;
ssh-keygen -A;
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config
systemctl enable sshd; systemctl restart sshd;
useradd vagrant
echo "vagrant" | passwd --stdin vagrant
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

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01.fale.io

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa  -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01`
```
