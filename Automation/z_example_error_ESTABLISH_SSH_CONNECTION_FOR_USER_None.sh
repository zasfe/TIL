[opc@instance-20220112-0945 Chapter02]$ ansible -vvv all -i test01.fale.io, -m ping
ansible 2.9.27
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/opc/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.5 (default, Mar 12 2021, 14:55:44) [GCC 4.8.5 20150623 (Red Hat 4.8.5-44.0.3)]
Using /etc/ansible/ansible.cfg as config file
Parsed test01.fale.io, inventory source with host_list plugin
Skipping callback 'actionable', as we already have a stdout callback.
Skipping callback 'counter_enabled', as we already have a stdout callback.
Skipping callback 'debug', as we already have a stdout callback.
Skipping callback 'dense', as we already have a stdout callback.
Skipping callback 'dense', as we already have a stdout callback.
Skipping callback 'full_skip', as we already have a stdout callback.
Skipping callback 'json', as we already have a stdout callback.
Skipping callback 'minimal', as we already have a stdout callback.
Skipping callback 'null', as we already have a stdout callback.
Skipping callback 'oneline', as we already have a stdout callback.
Skipping callback 'selective', as we already have a stdout callback.
Skipping callback 'skippy', as we already have a stdout callback.
Skipping callback 'stderr', as we already have a stdout callback.
Skipping callback 'unixy', as we already have a stdout callback.
Skipping callback 'yaml', as we already have a stdout callback.
META: ran handlers
<test01.fale.io> ESTABLISH SSH CONNECTION FOR USER: None
<test01.fale.io> SSH: EXEC ssh -C -o ControlMaster=auto -o ControlPersist=60s -o KbdInteractiveAuthentication=no -o PreferredAuthentications=gssapi-with-mic,gssapi-keyex,hostbased,publickey -o PasswordAuthentication=no -o ConnectTimeout=10 -o ControlPath=/home/opc/.ansible/cp/3129765f43 test01.fale.io '/bin/sh -c '"'"'echo ~ && sleep 0'"'"''
<test01.fale.io> (255, '', 'Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).\r\n')
test01.fale.io | UNREACHABLE! => {
    "changed": false, 
    "msg": "Failed to connect to the host via ssh: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).", 
    "unreachable": true
}
[opc@instance-20220112-0945 Chapter02]$
