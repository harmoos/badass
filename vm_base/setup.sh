#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
echo "grub-pc grub-pc/install_devices_empty boolean true" | debconf-set-selections
apt-mark hold grub-pc grub-common grub2-common

dpkg --configure -a
apt-get update -y
apt-get --with-new-pkgs upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

apt-get install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xrdp dbus-x11 x11-xserver-utils telnet curl git
systemctl enable lightdm
systemctl enable xrdp
adduser xrdp ssl-cert || true
echo "vagrant:vagrant" | chpasswd

echo "startxfce4" > /home/vagrant/.xsession
chown vagrant:vagrant /home/vagrant/.xsession

apt-get install -y ca-certificates gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt-get install -y wireshark

apt-get install -y python3-pip python3-venv pipx libpcap-dev build-essential libcap2-bin

if [ ! -f /usr/local/bin/ubridge ]; then
  cd /tmp
  rm -rf ubridge
  git clone https://github.com/GNS3/ubridge.git
  cd ubridge
  make
  make install
  cd /
fi
setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge || true

export PIPX_BIN_DIR=/usr/local/bin
export PIPX_HOME=/opt/pipx
pipx install gns3-server
pipx install gns3-gui[qt5]

cat <<EOF > /usr/share/applications/gns3.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GNS3
Comment=Graphical Network Simulator 3
Exec=/usr/local/bin/gns3
Icon=gns3
Terminal=false
Categories=Network;Development;
EOF

usermod -aG docker,wireshark vagrant
systemctl set-default graphical.target

systemctl enable lightdm
systemctl restart lightdm || true