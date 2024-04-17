# 2024.04.18 ansible 3일차

- 교재: Learning Ansible 2.7 - Third Edition [(packtpub)](https://www.packtpub.com/product/learning-ansible-27-third-edition/9781789954333) [(github)](https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition)

- TODO
  - 중지되어 있는 WSL 컨테이너 시작하고 hosts 파일들 재설정하는 스크립트 작성
  - ansible 계정 설정관련 YAML 파일 수정

## 중지되어 있는 WSL 컨테이너 시작하고 hosts 파일들 재설정

```bash
cat <<EOF > ./add_hosts.sh
#!/usr/bin/env bash
LANG=C

docker start ws01 ws02 db01

if ! grep -q ws01.fale.io "/etc/hosts"; then
  echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01` ws01.fale.io" >> /etc/hosts
fi

if ! grep -q ws02.fale.io "/etc/hosts"; then
  echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02` ws02.fale.io" >> /etc/hosts
fi

if ! grep -q db01.fale.io "/etc/hosts"; then
  echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` db01.fale.io" >> /etc/hosts
fi
EOF
chmod +x ./add_hosts.sh
./add_hosts.sh
```

## ansible 계정 설정관련 YAML 파일 수정

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

sed -i 's/^host_key_checking/#host_key_checking/g' /etc/ansible/ansible.cfg
sed -i 's/\[defaults\]/\[defaults\]\nhost_key_checking = False/g' /etc/ansible/ansible.cfg

ansible-playbook -i hosts --user vagrant firstrun.yaml -b
```
