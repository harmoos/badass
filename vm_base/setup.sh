#!/usr/bin/env bash
set -e

# 🇫🇷 Empêche les outils d'installation Debian d'ouvrir des questions interactives.
# 🇵🇹 Impede que as ferramentas de instalação do Debian façam perguntas interativas.
export DEBIAN_FRONTEND=noninteractive

# 🇫🇷 Prépare la réponse de GRUB : installer son chargeur sur le disque /dev/sda.
# 🇵🇹 Prepara a resposta do GRUB: instalar o carregador no disco /dev/sda.
echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
echo "grub-pc grub-pc/install_devices_empty boolean true" | debconf-set-selections
# 🇫🇷 Bloque les mises à jour des paquets GRUB pour éviter leur reconfiguration pendant l'upgrade.
# 🇵🇹 Bloque as atualizações dos pacotes GRUB para evitar a sua reconfiguração durante a atualização.
apt-mark hold grub-common grub2-common

dpkg --configure -a
apt-get update -y
# 🇫🇷 Met les paquets à jour, accepte les nouvelles dépendances et privilégie les configurations déjà présentes.
# 🇵🇹 Atualiza os pacotes, aceita novas dependências e dá prioridade às configurações já existentes.
apt-get --with-new-pkgs upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

apt-get install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xrdp dbus-x11 x11-xserver-utils telnet curl git
systemctl enable lightdm
systemctl enable xrdp
# 🇫🇷 Donne à XRDP accès au certificat TLS ; ignore l'erreur si l'ajout échoue.
# 🇵🇹 Dá ao XRDP acesso ao certificado TLS; ignora o erro se esta alteração falhar.
adduser xrdp ssl-cert || true
# 🇫🇷 Définit le mot de passe du compte vagrant à « vagrant » pour la connexion RDP.
# 🇵🇹 Define a palavra-passe da conta vagrant como « vagrant » para a ligação RDP.
echo "vagrant:vagrant" | chpasswd

# 🇫🇷 Demande à la session graphique de l'utilisateur vagrant de lancer XFCE.
# 🇵🇹 Indica à sessão gráfica do utilizador vagrant que deve iniciar o XFCE.
echo "startxfce4" > /home/vagrant/.xsession
chown vagrant:vagrant /home/vagrant/.xsession

apt-get install -y ca-certificates gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
# 🇫🇷 Télécharge la clé de signature Docker et la convertit au format utilisé par APT.
# 🇵🇹 Descarrega a chave de assinatura do Docker e converte-a para o formato usado pelo APT.
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 🇫🇷 Ajoute le dépôt Docker pour l'architecture détectée par dpkg et la version détectée par lsb_release.
# 🇵🇹 Adiciona o repositório Docker para a arquitetura detetada pelo dpkg e a versão detetada pelo lsb_release.
# 🇫🇷 « signed-by » limite ce dépôt à la clé de signature Docker.
# 🇵🇹 « signed-by » restringe este repositório à chave de assinatura do Docker.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 🇫🇷 Autorise les membres du groupe Wireshark à capturer les paquets sans lancer toute l'interface en root.
# 🇵🇹 Permite aos membros do grupo Wireshark capturar pacotes sem iniciar toda a interface como root.
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt-get install -y wireshark

apt-get install -y python3-pip python3-venv pipx libpcap-dev build-essential libcap2-bin

# 🇫🇷 ubridge relie les interfaces GNS3 ; sa compilation est évitée s'il est déjà installé.
# 🇵🇹 O ubridge liga as interfaces do GNS3; a compilação é evitada se já estiver instalado.
if [ ! -f /usr/local/bin/ubridge ]; then
  cd /tmp
  rm -rf ubridge
  git clone https://github.com/GNS3/ubridge.git
  cd ubridge
  make
  make install
  cd /
fi
# 🇫🇷 Autorise ubridge à administrer les interfaces et à utiliser les paquets bruts ; ignore un échec.
# 🇵🇹 Permite ao ubridge gerir interfaces e usar pacotes brutos; ignora uma eventual falha.
setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge || true

# 🇫🇷 Place les exécutables installés par pipx dans un chemin système.
# 🇵🇹 Coloca os executáveis instalados pelo pipx num diretório do sistema.
export PIPX_BIN_DIR=/usr/local/bin
# 🇫🇷 Stocke les environnements Python isolés de pipx dans /opt/pipx.
# 🇵🇹 Guarda os ambientes Python isolados do pipx em /opt/pipx.
export PIPX_HOME=/opt/pipx
# 🇫🇷 Évite de réinstaller GNS3 lorsque le provisionnement est relancé.
# 🇵🇹 Evita reinstalar o GNS3 quando a preparação da VM é executada novamente.
if ! pipx list --short | grep -q '^gns3-server '; then
  pipx install gns3-server
fi
if ! pipx list --short | grep -q '^gns3-gui '; then
  pipx install gns3-gui
fi
# 🇫🇷 Ajoute Qt et les modules du serveur à l'environnement Python isolé de l'interface GNS3.
# 🇵🇹 Adiciona o Qt e os módulos do servidor ao ambiente Python isolado da interface GNS3.
pipx inject gns3-gui gns3-server PyQt6

# 🇫🇷 Écrit le fichier qui ajoute GNS3 au menu des applications du bureau.
# 🇵🇹 Escreve o ficheiro que adiciona o GNS3 ao menu de aplicações do ambiente gráfico.
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

# 🇫🇷 Ajoute vagrant aux groupes Docker et Wireshark sans retirer ses autres groupes.
# 🇵🇹 Adiciona vagrant aos grupos Docker e Wireshark sem o retirar dos outros grupos.
usermod -aG docker,wireshark vagrant
systemctl set-default graphical.target

systemctl enable lightdm
# 🇫🇷 Démarre ou relance LightDM maintenant ; l'échec éventuel ne bloque pas le provisionnement.
# 🇵🇹 Inicia ou reinicia o LightDM agora; uma eventual falha não interrompe a preparação da VM.
systemctl restart lightdm || true
