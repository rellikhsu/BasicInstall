#!/bin/bash
APT="/usr/bin/apt"
AWK="/usr/bin/awk"
CAT="/bin/cat"
DPKGRECONFIGURE="/usr/sbin/dpkg-reconfigure"
ECHO="/bin/echo"
GREP="/bin/grep"
IFCONFIG="/sbin/ifconfig"
LN="/bin/ln"
LOCALEGEN="/usr/sbin/locale-gen"
PASSWD="/usr/bin/passwd"
SED="/bin/sed"
SYSTEMD="/bin/systemd"

PRE_INST_PACKAGE_LIST="
		apt-transport-https \
		locales \
		ntpdate \
		tzdata"

INST_PACKAGE_LIST="
		aptitude \
		autofs5 \
		bash-completion \
		chrony \
		cron-apt \
		dnsutils \
		dpkg-awk \
		dstat \
		firmware-linux-free \
		gawk \
		gcc \
		httping \
		inetutils-tools \
		iotop \
		iproute2 \
		iptraf-ng \
		irqbalance \
		jq \
		less \
		lsb-release \
		lsof \
		make \
		mosh \
		most \
		mtr-tiny \
		netcat-openbsd \
		openssh-server \
		pigz \
		postfix \
		psmisc \
		pxz \
		python-requests \
		rsync \
		sharutils \
		smartmontools \
		socat \
		sudo \
		sysstat \
		tcpdump \
		tcsh \
		telnet \
		util-linux \
		vim-nox \
		xfsdump \
		xfsprogs \
		xz-utils"

# Unset $LANG $LC_ALL $LC_CTYPE
unset LANG
unset LC_CTYPE
unset LC_ALL

# Install /etc/apt/sources.list
${CAT} > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian buster main contrib non-free
deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free
deb http://deb.debian.org/debian buster-backports main contrib non-free
deb-src http://deb.debian.org/debian buster-backports main contrib non-free
EOF

# update & install pre-install packages
${APT} clean
${APT} update
${APT} install -y ${PRE_INST_PACKAGE_LIST}
${APT} install -y ${INST_PACKAGE_LIST}

#
echo "Setting timezone to Asia/Taipei..."
${LN} -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
echo "Asia/Taipei" > /etc/timezone
echo "tzdata tzdata/Areas select Asia\ntzdata tzdata/Zones/Asia select Taipei" | debconf-set-selections
${DPKGRECONFIGURE} -fnoninteractive tzdata

# Chrony.conf
${CAT} > /etc/chrony/chrony.conf <<EOF
pool 2.debian.pool.ntp.org iburst
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
hwclockfile /etc/adjtime
rtcsync
makestep 1 3
EOF

${SYSTEMD} enable chrony.service
${SYSTEMD} start chrony.service

# Install locales
${CAT} /dev/null > /etc/default/locale
${CAT} > /etc/locale.gen <<EOF
en_US.UTF-8 UTF-8
en_US ISO-8859-1
zh_TW.UTF-8 UTF-8
EOF
${LOCALEGEN}

# Basic /etc/sysctl.conf settings
echo "Appending to /etc/sysctl.conf..."
${CAT} > /etc/sysctl.conf << EOF
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
export TERM=xterm
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

