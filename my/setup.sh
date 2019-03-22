#!/bin/env bash
# print command before executing, and exit when any command fails
set -e

# cheshixiugai

# 更新系统
pacman -Syu

read -e -p "Please enter username:" -i "wangms" username
read -e -p "Please enter passed for user:" -i "123" password

print_line() { #{{{
   printf "%$(tput cols)s\n"|tr ' ' '-'
} #}}}

print_title() { #{{{
    clear
    print_line
    echo -e "# ${Bold}$1${Reset}"
    print_line
    echo ""
} #}}}

pause_function() { #{{{
    print_line
    if [[ $AUTOMATIC_MODE -eq 0 ]]; then
    read -e -sn 1 -p "Press enter to continue..."
    fi
} #}}}


# 1.1用户和用户组
print_title "1.1 Users and groups"
useradd -m -g users -G wheel -s /bin/bash $username
echo "$username:$password" | chpasswd
# 将安装脚本文件所在文件夹移到新建用户目录下
mv `pwd` /home/$username
pacman -S --noconfirm xdg-user-dirs-gtk
pause_function


# 1.2权限提升
print_title "1.2 Privilege escalation"
sed -i 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
pause_function


# 一、安装显示服务器x-server
# pacman -S --noconfirm xorg-server xorg-xinit xorg-utils xorg-server-utils xorg-twm xterm xorg-xclock
pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput


# 二、安装显卡驱动程序
# lspci | grep VGA # 确定显卡型号
# 查看所有开源驱动：$ pacman -Ss xf86-video

# vmware驱动、窗口自适应、VM与主机间复制黏贴
pacman -S --noconfirm xf86-video-vmware xf86-input-vmmouse open-vm-tools gtkmm gtkmm3
cat /proc/version > /etc/arch-release
systemctl enable vmtoolsd
mkinitcpio -p linux


# 三、安装显示/登录/桌面管理器
# pacman -S --noconfirm gdm
# systemctl enable gdm.service

# pacman -S --noconfirm sddm
# systemctl enable sddm.service

pacman -noconfirm slim slim-themes archlinux-themes-slim
ls /usr/share/slim/themes/
sed -i '/default user/s/^#//' /etc/slim.conf
sed -i '/default user/s/simone/${username}/' /etc/slim.conf
sed -i '/current_theme/s/default/lake/' /etc/slim.conf
sed -i '/exec/s/^/#/' /home/${username}/.xinitrc
echo 'exec $1' >> /home/${suername}/.xinitrc

# 四、安装xfce
pacman -S --noconfirm xfce4 xfce4-goodies xarchiver mupdf

# 安装字体
pacman -S --noconfirm ttf-dejavu ttf-liberation ttf-bitstream-vera ttf-hack wqy-microhei noto-fonts-cjk wqy-zenhei

# reboot重启系统
reboot


:<<!EOF!

# bash-completion git
sudo acman -S bash-completion git

# zsh
sudo pacman -S zsh
chsh -s $(which zsh)
cd wms
cp .zshrc ..

cat <<EOF >>.zshrc
# 我的PS1
# autoload -U promptinit
# promptinit
# prompt fade magenta

# 将这些配置放在 %{ [...] %}  里面确保光标不移动
PS1=$'%{\e[1;37m[ \e[1;31m%n\e[1;37m@\e[1;33m%m \e[1;35m%~ \e[1;37m]\e[0m%#%} '
EOF

# reboot后运行下zsh安装一些插件
# systemctl reboot -i


# 用非root帐户在其主目录下安装yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# 安装 pamac
yay -S pamac-aur

# 安装字体
yay -S ttf-fira-code ttf-google-fonts-git ttf-mac-fonts ttf-ms-fonts

sudo pacman -S ttf-bitstream-vera
yay -S tff-emojione-color
yay -S ttf-twemoji-color

# 中文输入法
sudo pacman -S fcitx
sudo pacman -S fcitx-configtool
sudo pacman -S fcitx-gtk2 fcitx-gtk3 fcitx-qt4 fcitx-qt5

# 将本地化语言改为中文
echo 'LANG=zh_CN.UTF-8' > /etc/locale.conf
# 重启后中文环境即生效
reboot

# 声音
sudo pacman -S alsa-utils alsa-plugins
sudo pacman -S pulseaudio pulseaudio-alsa

# 网易音乐
yay -S netease-cloud-music 

# 用于appearance
sudo pacman -S arc-gtk-theme
# 用于wm
yay -S numix-frost-theme

# 快捷启动docky或plank
sudo pacman -S docky
sudo pacman -S plank

# 显示基本信息
sudo pacman -S conky
sudo pacman -S neofetch

sudo pacman -S firefox 

# spf13-vim
sudo pacman -S vim
sh <(curl https://j.mp/spf13-vim3 -L)

# emacs
sudo pacman -S emacs
git clone https://github.com/RenChunhui/.emacs.d.git

# web服务
sudo pacman -S apache
systemctl start httpd.service
systemctl enable httpd

# teamviewer
yay -S teamviewer
systemctl enable teamviewerd.service
systemctl start teamviewerd.service

!EOF!
