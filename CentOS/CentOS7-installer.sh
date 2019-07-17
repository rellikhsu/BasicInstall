#!/bin/bash
#Centos 7 installation scripts
# required programs
AWK="/bin/awk"
AUTHCONFIG="/usr/sbin/authconfig"
CAT="/bin/cat"
CHRONYC="/usr/bin/chronyc"
ECHO="/bin/echo"
GREP="/bin/grep"
HWCLOCK="/sbin/hwclock"
LN="/bin/ln"
LOCALECTL="/bin/localectl"
NTPDATE="/sbin/ntpdate"
RM="/bin/rm"
SYSCTL="/sbin/sysctl"
SYSTEMCTL="/usr/bin/systemctl"
TIMEDATECTL="/bin/timedatectl"
SED="/bin/sed"
YUM="/bin/yum"
GROUPADD="/sbin/groupadd"
GRUBBY="/usr/sbin/grubby"
USERADD="/sbin/useradd"


# installed programes
INST_PACKAGE_LIST="
bash-completion \
bind-utils \
chrony \
dstat \
e2fsprogs \
epel-release \
fping \
gawk \
glibc-common \
ioping \
iotop \
iptables \
iptraf-ng \
jemalloc \
jq \
less \
lsof \
mtr \
net-snmp \
net-snmp-utils \
net-tools \
nss-pam-ldapd \
ntpdate \
openldap \
openldap-clients \
openssh-server \
pam_ldap \
pigz \
procps-ng \
psmisc  \
python-requests \
redhat-lsb \
rsync \
smartmontools \
socat \
sudo \
sysstat \
telnet \
tcpdump \
util-linux \
vim-enhanced \
xfsprogs \
xz \
yum-plugin-post-transaction-actions \
yum-plugin-rpm-warm-cache \
yum-versionlock
"

# remove programs
REMOVE_PACKAGE_LIST="
firewalld \
irqbalance \
NetworkManager-glib \
NetworkManager \
NetworkManager-tui \
samba-common \
sssd \
sssd-client
"

# Unset $LANG $LC_ALL $LC_CTYPE
unset LANG
unset LC_CTYPE
unset LC_ALL

# Update and enable fasttrack repo
${YUM} update -y
${SED} -i s/enabled=0/enabled=1/ /etc/yum.repos.d/CentOS-fasttrack.repo
${YUM} update -y
${YUM} -y install epel-release
${YUM} -y remove ${REMOVE_PACKAGE_LIST}
${YUM} -y install ${INST_PACKAGE_LIST}

# SElinux
${SED} -i s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config

# Timezone
${TIMEDATECTL} set-timezone "Asia/Taipei"
# Adjust system time and write to hardware clock
${NTPDATE} time.stdtime.gov.tw && ${HWCLOCK} -w

# Enable Chrony Daemon
${CAT} > /etc/chrony.conf << EOF
# These servers were defined in the installation:
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
server 0.centos.pool.ntp.org iburst
server time.stdtime.gov.tw iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF

${SYSTEMCTL} enable chronyd.service
# Show chrony
${CHRONYC} sourcestats -v

# Setting DNS
${CAT} >> /etc/resolv.conf << EOF
nameserver      8.8.4.4
nameserver      8.8.8.8
EOF


# Basic /etc/sysctl.conf settings
echo "Appending to /etc/sysctl.conf..."
${CAT} > /etc/sysctl.conf << EOF
kernel.core_uses_pid = 1
net.core.default_qdisc=fq
net.ipv4.ip_forward = 0
net.ipv4.ip_local_port_range = 1025 65534
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_frto = 0
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
vm.swappiness = 1
EOF

# snmpd.conf
echo "Appending to /etc/snmp/snmpd.conf . . ."
${CAT} > /etc/snmp/snmpd.conf << EOF
rocommunity monitor
com2sec notConfigUser  default  monitor
com2sec mynetwork 10.0.0.0/8    monitor
group   notConfigGroup v1       notConfigUser
group   notConfigGroup v2c      notConfigUser
group   MyROGroup       v2c     monitor
view    systemview    included  .1.3.6.1.2.1.1
view    systemview    included  .1.3.6.1.2.1.25.1.1
access  notConfigGroup ""      any       noauth    exact  systemview none none
syslocation Unknown (edit /etc/snmp/snmpd.conf)
syscontact Root <root@localhost> (configure /etc/snmp/snmp.local.conf)
dontLogTCPWrappersConnects yes
disk /
disk /var
EOF
#
${SYSTEMCTL} enable snmpd.service

# update ioScheduler
${GRUBBY} --update-kernel=ALL --args="elevator=noop"

# update ldap
#${AUTHCONFIG} --enableldap --ldapserver="ldap://<ip>" --ldapbasedn="ou=<ou>,dc=<dc>,dc=<dc>,dc=<dc>" --updateall --disablesssd --enableldapauth  --enablemkhomedir

# bash profile
${CAT} > /etc/skel/.profile << EOF
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
EOF

# bashrc
${CAT} > /etc/skel/.bashrc << EOF
#bash completion
if [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
fi
#
bold=$(tput -Txterm bold)
reset=$(tput -Txterm sgr0)
blue=$(tput -Txterm setaf 4)
green=$(tput -Txterm setaf 2)
yellow=$(tput -Txterm setaf 3)
red=$(tput -Txterm setaf 1)
#
export PS1='\[$bold\]\u\[$blue\]@\[$reset\]\h\[$green\](\T)\[$red\]\[$reset\][\w]$\[$reset\] '
export LANG=en_US.UTF-8
export LANGUAGE=en_US:us
export GREP_COLORS='ms=01;32:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36'
export HISTFILESIZE=10000
export HISTSIZE=10000
export PAGER="/usr/bin/less"
export EDITOR="/usr/bin/vim"
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;38;5;208m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[04;38;5;111m'
shopt -s autocd
shopt -s cmdhist
shopt -s histappend
shopt -s hostcomplete
unset PROMPT_COMMAND
# my alias
alias ls='ls -F --color=auto'
alias l='ls -alhiF --color=auto'
alias ll='ls -alhiF --color=auto'
alias count='find . -maxdepth 1 -type d -exec du -s {} \; | sort -g'
alias ssh='ssh -2 -4 -e none -o ForwardAgent=yes'
alias e='/usr/bin/clear && exit'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias less='less -r'
alias most='most +u -s'
alias p='pwd -P'
alias s='/bin/sync;/bin/sync;/bin/sync;/bin/sync'
alias vi='vim'
alias ..='cd ..'
alias ...='cd ../..'
alias top='sudo top'
EOF
