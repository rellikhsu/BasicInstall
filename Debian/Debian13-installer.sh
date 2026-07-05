#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

APT="/usr/bin/apt"
CAT="/bin/cat"
DPKGRECONFIGURE="/usr/sbin/dpkg-reconfigure"
ECHO="/bin/echo"
LN="/bin/ln"
LOCALEGEN="/usr/sbin/locale-gen"
SYSTEMCTL="/usr/bin/systemctl"

PRE_INST_PACKAGE_LIST="
		apt-transport-https \
		locales \
		tzdata"

INST_PACKAGE_LIST="
		bash-completion \
		chrony \
		dnsutils \
		dpkg-awk \
		dstat \
		firmware-linux-free \
		gawk \
		gcc \
		httping \
		inetutils-tools \
		iotop-c \
		iproute2 \
		iptraf-ng \
		irqbalance \
		jq \
		lsof \
		make \
		mosh \
		most \
		mtr-tiny \
		netcat-openbsd \
		pigz \
		psmisc \
		rsync \
		sharutils \
		socat \
		sysstat \
		tcpdump \
		tcsh \
		telnet \
		util-linux \
		vim-nox" 

# Unset $LANG $LC_ALL $LC_CTYPE
unset LANG
unset LC_CTYPE
unset LC_ALL

# Install /etc/apt/sources.list.d
${CAT} > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb deb-src
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: https://deb.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF


# update & install pre-install packages
${APT} clean
${APT} update
${APT} install -y ${PRE_INST_PACKAGE_LIST}
${APT} install -y ${INST_PACKAGE_LIST}

#
${ECHO} "Setting timezone to Asia/Taipei..."
${LN} -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
${ECHO} "Asia/Taipei" > /etc/timezone
${ECHO} "tzdata tzdata/Areas select Asia" | debconf-set-selections
${ECHO} "tzdata tzdata/Zones/Asia select Taipei" | debconf-set-selections

#
DEBIAN_FRONTEND=noninteractive apt install -y tzdata

#
${DPKGRECONFIGURE} -fnoninteractive tzdata


# 這裡插入：避免 timesyncd 跟 chrony 打架
${SYSTEMCTL} disable --now systemd-timesyncd 2>/dev/null || true

# 塞入 chrony config
${CAT} > /etc/chrony/conf.d/00-bootstrap.conf <<EOF
# 開機初期允許 step（不限制次數），確保時間能先回到合理範圍
makestep 1 -1

# 開機先用 Google 拉回時間（避免 TLS/NTS 因時間錯而卡死）
initstepslew 30 time1.google.com time2.google.com time3.google.com time4.google.com
EOF

${CAT} > /etc/chrony/conf.d/99-auth.conf <<EOF
authselectmode prefer
EOF

${CAT} > /etc/chrony/sources.d/99-time.sources <<EOF
# NTS（可驗證）
server time.cloudflare.com iburst nts
server sth1.nts.netnod.se iburst nts
server sth2.nts.netnod.se iburst nts

# Google（無 NTS）當 fallback/對照
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOF

#啟動 chrohny
${SYSTEMCTL} enable --now chrony.service

# Install locales
${CAT} /dev/null > /etc/default/locale
${CAT} > /etc/locale.gen <<EOF
en_US.UTF-8 UTF-8
en_US ISO-8859-1
zh_TW.UTF-8 UTF-8
EOF
${LOCALEGEN}
update-locale LANG=en_US.UTF-8

# Basic /etc/sysctl.conf settings
echo "Appending to /etc/sysctl.conf..."
${CAT} > /etc/sysctl.d/99-local.conf << EOF
vm.swappiness = 1
EOF

# bashrc
${CAT} > /etc/skel/.bashrc << EOF
#bash completion
if [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
fi
#
bold=\$( tput -Txterm bold )
reset=\$( tput -Txterm sgr0 )
blue=\$( tput -Txterm setaf 4 )
green=\$( tput -Txterm setaf 2 )
yellow=\$( tput -Txterm setaf 3 )
red=\$( tput -Txterm setaf 1 )
#
export PS1='\[\$bold\]\u\[\$blue\]@\[\$reset\]\h\[\$green\](\T)\[\$red\]\[\$reset\][\w]\$\[\$reset\] '
export EDITOR="/usr/bin/vim"
export GREP_COLORS='ms=01;32:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36'
export HISTFILESIZE=10000
export HISTSIZE=10000
export LANG="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:us"
export LC_TERMINAL="iTerm2"
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
alias ssh='ssh -4 -e none -o ForwardAgent=yes'
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

# screenrc
${CAT} > /etc/skel/.screenrc << EOF
defc1 off
caption always "%-w%<%{=B GK}%n %t%{= KW}%+w"
hardstatus alwayslastline "%{=b BW} {%l}%018=%{=b WK} %n %t %-029=%{YK} %Y %M %d(%D) %{RW} %C %A"
defencoding utf-8
defutf8 on
shelltitle shell
bind b encoding big5 utf8
bind u encoding utf8 utf8
bind w height -w 24
bind m height -w
termcapinfo screen 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
termcapinfo xterm-256color 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
defscrollback 20000
EOF

# vimrc
${CAT} > /etc/skel/.vimrc << EOF
autocmd FileType c set expandtab
autocmd FileType cpp set expandtab
filetype on
syntax on
set autoindent
set background=dark
set enc=utf-8
set encoding=utf8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set fileformat=unix
set nocompatible
set nomodeline
set paste
set showmatch
set tenc=utf8
set termencoding=utf-8
EOF
