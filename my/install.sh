#!/bin/env bash
# print command before executing, and exit when any command fails
set -e

read -e -p "Please enter passwd for root:" -i "123" root_passwd

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


# 1.1 键安装准备-连盘布局
print_title "1.1 Set the keyboard layout"
print_line


# 1.2 验安装准备-连证启动模式
print_title "1.2 Verify the boot mode"
print_line

# " 1.3 安装准备-连接到因特网"
print_title "1.3 Connect to the Internet"
ping -c 3 baidu.com
print_line


# 1.4 安装准备-更新系统时间
print_title "1.4 Update the system clock"
timedatectl set-ntp true
timedatectl status
print_line


# 1.5-1.7 安装准备-建立硬盘分区\格式化分区\挂载分区
print_title "1.5-1.7 Partition the disks\Format the partitions\Mount the file systems"
DISK="/dev/sda"
# 创建分区表
parted "$DISK" mktable msdos 
# 创建分区
echo "parttion 1 : /boot (100MiB)"
# 注意第一个分区起始扇区要从1M开始，即留有一部分空间，否则grub-install时显示如下错误提示:
# “this msdos-style partition label has no post-MBR gap; embedding won't be possible.”
parted -s "$DISK" mkpart primary ext4 1M 100M
parted -s "$DISK" set 1 boot on
echo "parttion 2 : /即root (20Gib)"
parted -s "$DISK" mkpart primary ext4 100M 20G
echo "parttion 3 : swap (4GiB)"
parted -s "$DISK" mkpart primary linux-swap 20G 25G
echo "parttion 4 : 剩下的给 /home"
parted -s "$DISK" mkpart primary ext4 25G 100%

# 格式化分区
# 格式化分区为ext4格式
mkfs.ext4 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
# 格式化为swap
mkswap "${DISK}3" 
# 启用swap
swapon "${DISK}3"

# 挂载分区
mount "${DISK}2" /mnt 
mkdir /mnt/{boot,home} 
mount "${DISK}1" /mnt/boot 
mount "${DISK}4" /mnt/home

# 查看分区情况
parted "$DISK" print
fdisk -l "$DISK"
lsblk
print_line


# 安装-2.1 选择镜像
print_title "2.1 Select the mirrors"
# you can find your closest server from: https://www.archlinux.org/mirrorlist/all/
# 如下原版可能不能用
# echo 'Server = http://mirror.internode.on.net/pub/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlisti
# 下面的方法需yay安装reflector，准确但很麻烦。
# sudo reflector --verbose --country 'CN' -l 50 -p https -p http --sort rate --save /etc/pacman.d/mirrorlist
# pacman -S --noconfirm --needed reflector
# reflector --latest 200 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist	

# 如下方法是取中国境内的服务器(镜像源)
# curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=http&protocol=https&ip_version=4&use_mirror_status=on' | sed 's/^#Server/Server/g' > /etc/pacman.d/mirrorlist
# 注释所有非中国的软件源,这个比上面用curl下载要快很多	
sed -i '/China/!{n;/Server/s/^/#/};t;n' /etc/pacman.d/mirrorlist	
cat /etc/pacman.d/mirrorlist
pacman -Syyu
print_line


# 安装-2.2 安装基本系统
print_title "2.2 Install the base packages"
# would recommend to use linux-lts kernel if you are running a server environment, otherwise just use "linux"
# pacstrap /mnt $(pacman -Sqg base | sed 's/^linux$/&-lts/') base-devel
# pacstrap -i /mnt $(pacman -Sqg base) base-devel
pacstrap /mnt base base-devel
pacman -Syu --noconfirm
print_line


# 配置系统-3.1 生成Fstab
print_title "3.1 Fstab"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
print_line


# 配置系统-3.2 Chroot进入新系统
print_title "3.2 Chroot"
# arch-chroot /mnt
print_line


arch_chroot() { #{{{
    arch-chroot /mnt /bin/bash -c "${1}"
}
#}}}
print_line


# 配置系统-3.3 时区设置
print_title "3.3 Time zone"
arch_chroot "rm -f /etc/localtime"
arch_chroot "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
# arch_chroot "timedatectl set-timezone Asia/Shanghai"   #此命令会创建一个/etc/localtime软链接，指向/usr/share/zoneinfo/中的时区文件
arch_chroot "hwclock --systohc"
# 时间同步
pacstrap /mnt ntp
# systemctl start ntpd.service
arch-chroot /mnt systemctl enable ntpd.service
print_line


# 配置系统-3.4 语言设置(本地化)
print_title "3.4 Localization"
arch_chroot "sed -i 's/^#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen"
arch_chroot "sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen"
arch_chroot "locale-gen"
arch_chroot "echo 'LANG=en_US.UTF-8' > /etc/locale.conf"
cat /etc/locale.conf
print_line


# 配置系统-3.5 网络配置
print_title "3.5 Network configuration"
# 主机名设置
host_name=wms_arch
# echo $host_name > /mnt/etc/hostname
arch_chroot "echo $host_name > /etc/hostname"
arch_chroot "echo '127.0.0.1  localhost.localdomain  localhost' >> /etc/hosts"
arch_chroot "echo '::1        localhost.localdomain  localhost' >> /etc/hosts"
arch_chroot "echo '127.0.1.1  $host_name.localdomain    $host_name' >> /etc/hosts"
arch_chroot "cat /etc/hostname"
arch_chroot "cat /etc/hosts"

# 网络配置
# https://ubos.net/docs/developers/install-arch.html
# rm /mnt/etc/resolv.conf
# ln -s /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf
# arch-chroot /mnt systemctl enable systemd-networkd systemd-resolved

# ping
arch-chroot /mnt systemctl enable dhcpcd

# ssh
pacstrap /mnt openssh
arch-chroot /mnt systemctl enable sshd
arch_chroot "sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
print_line


# 配置系统-3.6 创建Initramfs
print_title "3.6 Initramfs"
arch_chroot "mkinitcpio -p linux"
print_line


# 配置系统-3.7 Root密码
print_title ""3.7 Root password
# arch-chroot /mnt passwd
# arch_chroot "echo -e '123456\n123456' | passwd"
arch_chroot "echo 'root:$root_passwd' | chpasswd"
print_line


# 配置系统-3.8 安装引导程序
print_title "3.8 Boot loader"
# 安装引导程序grub\os-prober\intel-ucode
# arch-chroot /mnt grub os-prober intel-ucode 
pacstrap /mnt grub os-prober intel-ucode 

# 将引导信息写到 sda 
arch_chroot "grub-install --target=i386-pc /dev/sda"
# 生成配置文件 grub.cfg
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
echo "如果报warning failed to connect to lvmetad，falling back to device scanning.错误,将下面文件中的use_lvmetad = 1将1修改为0"
arch_chroot "sed -i 's/use_lvmetad = 1/use_lvmetad = 0/g' /etc/lvm/lvm.conf"	
print_line


# 4、重启系统
print_title "4 Reboot"
cp -R `pwd` /mnt/root
# 退出 chroot 环境
# exit   #这个exit将会直接退出本脚本，后面的等等命令如reboot根本无法执行。
# 卸载挂载点
umount /mnt/{boot,home}
umount /mnt
echo "Congratulations! You have successfully installed a minimal command line Arch Linux."
# 重启系统
reboot

print_line
# 恭喜！您已成功安装了最小命令行Arch Linux。

