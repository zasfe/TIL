# windows wsl 상황에서 사용

  * vagrant 사용시 오류가 빈번하여 wsl 로 환경 구성후 사용하도록 환경 구성을 변경했음
  * 교재: [[packtpub] Learning Ansible 2.7 - Third Edition](https://www.packtpub.com/product/learning-ansible-27-third-edition/9781789954333)
  * 코드: https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition




## ansible 설치 - Ubuntu on wsl
```bash
$apt-get install ansible
```

## ansible 설치 - pip (windows 가능)
```bash
$ sudo easy_install pip
$ sudo pip install ansible
```

## 테스트 환경 구성 - Container CentOS7 On WSL
  - vagrant 오동작으로 wsl에 CentOS7 컨테이너를 구동해서 사용함
  - 기본 centos7 컨테이너 이미지에 일부 네트워크 도구와 sshd-server 설치하고 vagrant 계정 설정함
  - **Failed to get D-Bus connection: No such file or directory** 오류 방지를 위한 systemctl 교체함

```bash
docker run -d --privileged --name centos7 centos:centos7 /usr/sbin/init
cat <<EOF > ./centos7_vagrant
mv /usr/bin/systemctl /usr/bin/systemctl.old;
curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl;
chmod +x /usr/bin/systemctl;
yum install -y iproute net-tools openssh-server sudo;
ssh-keygen -A;
systemctl enable sshd; systemctl start sshd;
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config
useradd vagrant
echo "vagrant" | passwd --stdin vagrant
chmod u+w /etc/sudoers.d
echo "vagrant        ALL=NOPASSWD:       ALL" >> /etc/sudoers.d/vagrant
chmod u-w /etc/sudoers.d
EOF

docker cp ./centos7_vagrant centos7:/root/centos7_vagrant.sh
docker exec -u 0 centos7 /bin/bash /root/centos7_vagrant.sh


ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''
cp -pa ~/.ssh/id_rsa ~/.ssh/id_rsa_vagrant_centos7.pub
# ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa_vagrant_centos7.pub -q -N ''

# SSH keypass 
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa_vagrant_centos7.pub vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" centos7`

# 연결할 호스트 정보 추가
echo "[web]" > HOST
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" centos7`" >> HOST

echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" centos7` test01.fale.io" >> /etc/hosts
```

## vagrant 계정을 통한 정상 연결 확인

```bash
[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]# ansible all -i HOST --user vagrant -m ping
172.17.0.2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]#
```

## Variables in playbooks 챕터

```
[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]# ansible-playbook -i 172.17.0.2, --user vagrant variables.yaml

PLAY [all] *****************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
ok: [172.17.0.2]

TASK [Set variable 'name'] *************************************************************************************************************************************
ok: [172.17.0.2]

TASK [Print variable 'name'] ***********************************************************************************************************************************
ok: [172.17.0.2] => {
    "msg": "Test machine"
}

PLAY RECAP *****************************************************************************************************************************************************
172.17.0.2                 : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]#
```


## Creating the Ansible user 챕터

  * ansible 계정을 만들고 key 인증설정 추가

```bash
cat <<EOF > firstrun.yaml
--- 
- hosts: all 
  user: vagrant 
  tasks: 
    - name: Ensure ansible user exists 
      user: 
        name: ansible 
        state: present 
        comment: Ansible 
      become: True
    - name: Ensure ansible user accepts the SSH key 
      authorized_key: 
        user: ansible 
        key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        state: present 
      become: True
    - name: Ensure the ansible user is sudoer with no password required 
      lineinfile: 
        dest: /etc/sudoers 
        state: present 
        regexp: '^ansible ALL\=' 
        line: 'ansible ALL=(ALL) NOPASSWD:ALL' 
        validate: 'visudo -cf %s'
      become: True
EOF
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
ansible-playbook -i 172.17.0.2, --user vagrant firstrun.yaml -b
```


  * host fingerprint 저장 묻지 않기
    * 방법1. ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
    * 방법2. ansible.cfg 파일내 설정
```
[defaults]
host_key_checking = False
```


## Configuring a basic server 챕터

```bash
[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]# cat common_tasks.yaml
---
- hosts: all
  remote_user: ansible
  tasks:
    - name: Ensure EPEL is enabled
      yum:
        name: epel-release
        state: present
      become: True
    - name: Ensure libselinux-python is present
      yum:
        name: libselinux-python
        state: present
      become: True
    - name: Ensure libsemanage-python is present
      yum:
        name: libsemanage-python
        state: present
      become: True
    - name: Ensure we have last version of every package
      yum:
        name: "*"
        state: latest
      become: True
    - name: Ensure NTP is installed
      yum:
        name: ntp
        state: present
      become: True
    - name: Ensure the timezone is set to UTC
      file:
        src: /usr/share/zoneinfo/GMT
        dest: /etc/localtime
        state: link
      become: True
    - name: Ensure the NTP service is running and enabled
      service:
        name: ntpd
        state: started
        enabled: True
      become: True
    - name: Ensure FirewallD is installed
      yum:
        name: firewalld
        state: present
      become: True
    - name: Ensure FirewallD is running
      service:
        name: firewalld
        state: started
        enabled: True
      become: True
    - name: Ensure SSH can pass the firewall
      firewalld:
        service: ssh
        state: enabled
        permanent: True
        immediate: True
      become: True
    - name: Ensure the MOTD file is present and updated
      template:
        src: motd
        dest: /etc/motd
        owner: root
        group: root
        mode: 0644
      become: True
    - name: Ensure the hostname is the same of the inventory
      hostname:
        name: "{{ inventory_hostname }}"
      become: True
[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]# ansible-playbook -i test01.fale.io, common_tasks.yaml

PLAY [all] *****************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure EPEL is enabled] **********************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure libselinux-python is present] *********************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure libsemanage-python is present] ********************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure we have last version of every package] ************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure NTP is installed] *********************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure the timezone is set to UTC] ***********************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure the NTP service is running and enabled] ***********************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure FirewallD is installed] ***************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure FirewallD is running] *****************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure SSH can pass the firewall] ************************************************************************************************************************
ok: [test01.fale.io]

TASK [Ensure the MOTD file is present and updated] *************************************************************************************************************
changed: [test01.fale.io]

TASK [Ensure the hostname is the same of the inventory] ********************************************************************************************************
fatal: [test01.fale.io]: FAILED! => {"changed": false, "msg": "Command failed rc=1, out=, err=Could not set property: Failed to set static hostname: Device or resource busy\n"}

PLAY RECAP *****************************************************************************************************************************************************test01.fale.io             : ok=12   changed=1    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0

[root@ubuntu:~/workaround/Learning-Ansible-2.X-Third-Edition-master/Chapter02]#
```
  * ansible client인 test01.fale.io 가 컨테이너라서 hostname 변경이 되지 않는다.


---

**여기까지 했음 - 2024-04-16**

  * https://subscription.packtpub.com/book/cloud-and-networking/9781789954333/3/ch03lvl1sec20/installing-and-configuring-a-web-server



