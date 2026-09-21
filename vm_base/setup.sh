#!/usr/bin/env bash
# La première ligne demande à l'environnement de trouver Bash pour exécuter ce script.
# Arrête le provisionnement dès qu'une commande échoue, sauf si son erreur est ignorée explicitement.
set -e

# Empêche les outils d'installation Debian d'ouvrir des questions interactives.
export DEBIAN_FRONTEND=noninteractive

# Prépare la réponse de GRUB : installer son chargeur sur le disque /dev/sda.
echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
# Autorise aussi GRUB à accepter une sélection vide si son paquet le demande.
echo "grub-pc grub-pc/install_devices_empty boolean true" | debconf-set-selections
# Bloque les mises à jour des paquets GRUB pour éviter leur reconfiguration pendant l'upgrade.
apt-mark hold grub-pc grub-common grub2-common

# Termine la configuration de paquets qui serait restée inachevée.
dpkg --configure -a
# Actualise la liste des paquets disponibles dans les dépôts Debian.
apt-get update -y
# Met les paquets à jour, accepte les nouvelles dépendances et privilégie les configurations déjà présentes.
apt-get --with-new-pkgs upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Installe le bureau XFCE, le gestionnaire de connexion, l'accès RDP et quelques outils réseau.
apt-get install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xrdp dbus-x11 x11-xserver-utils telnet curl git
# Active LightDM pour les prochains démarrages de la VM.
systemctl enable lightdm
# Active le serveur RDP pour les prochains démarrages de la VM.
systemctl enable xrdp
# Donne à XRDP accès au certificat TLS ; ignore l'erreur si l'ajout échoue.
adduser xrdp ssl-cert || true
# Définit le mot de passe du compte vagrant à « vagrant » pour la connexion RDP.
echo "vagrant:vagrant" | chpasswd

# Demande à la session graphique de l'utilisateur vagrant de lancer XFCE.
echo "startxfce4" > /home/vagrant/.xsession
# Rend le fichier de session graphique accessible au bon propriétaire.
chown vagrant:vagrant /home/vagrant/.xsession

# Installe les certificats HTTPS et les outils nécessaires au dépôt Docker.
apt-get install -y ca-certificates gnupg lsb-release
# Crée le dossier où APT lira les clés des dépôts tiers, avec des droits adaptés.
install -m 0755 -d /etc/apt/keyrings
# Télécharge la clé de signature Docker et la convertit au format utilisé par APT.
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
# Permet à APT de lire cette clé de signature.
chmod a+r /etc/apt/keyrings/docker.gpg

# Ajoute le dépôt Docker pour l'architecture détectée par dpkg et la version détectée par lsb_release.
# « signed-by » désigne la clé Docker ; tee écrit la ligne dans le fichier APT.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Recharge les listes de paquets pour inclure le nouveau dépôt Docker.
apt-get update -y
# Installe le moteur Docker, son client, containerd et les extensions Buildx et Compose.
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Autorise les membres du groupe Wireshark à capturer les paquets sans lancer toute l'interface en root.
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
# Installe Wireshark pour analyser le trafic des topologies GNS3.
apt-get install -y wireshark

# Installe Python, pipx et les bibliothèques/outils nécessaires à GNS3 et à ubridge.
apt-get install -y python3-pip python3-venv pipx libpcap-dev build-essential libcap2-bin

# Compile ubridge seulement s'il n'est pas déjà installé à cet emplacement.
if [ ! -f /usr/local/bin/ubridge ]; then
  # Utilise le dossier temporaire pour récupérer et compiler le code source.
  cd /tmp
  # Supprime une ancienne copie temporaire pour repartir d'un dépôt propre.
  rm -rf ubridge
  # Récupère le code source de ubridge, utilisé par GNS3 pour relier les interfaces.
  git clone https://github.com/GNS3/ubridge.git
  # Entre dans le dossier du code source téléchargé.
  cd ubridge
  # Compile le programme avec les outils installés plus haut.
  make
  # Copie le programme compilé dans les chemins système.
  make install
  # Quitte le dossier temporaire une fois l'installation terminée.
  cd /
# Termine la condition qui évite une nouvelle compilation.
fi
# Autorise ubridge à administrer les interfaces et à utiliser les paquets bruts ; ignore un échec.
setcap cap_net_admin,cap_net_raw=ep /usr/local/bin/ubridge || true

# Place les exécutables installés par pipx dans un chemin système.
export PIPX_BIN_DIR=/usr/local/bin
# Stocke les environnements Python isolés de pipx dans /opt/pipx.
export PIPX_HOME=/opt/pipx
# Installe le serveur GNS3 dans un environnement Python isolé.
pipx install gns3-server
# Installe l'interface graphique GNS3 avec ses dépendances Qt 5.
pipx install gns3-gui[qt5]

# Écrit le fichier qui ajoute GNS3 au menu des applications du bureau.
# [Desktop Entry] ouvre la définition du raccourci.
# Type=Application indique qu'il lance un programme.
# Encoding=UTF-8 précise l'encodage du fichier.
# Name=GNS3 définit le nom visible dans le menu.
# Comment donne la description affichée par le bureau.
# Exec indique la commande lancée quand on clique sur le raccourci.
# Icon demande l'icône nommée gns3.
# Terminal=false évite d'ouvrir un terminal ; Categories choisit les menus d'affichage.
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

# Ajoute vagrant aux groupes Docker et Wireshark sans retirer ses autres groupes.
usermod -aG docker,wireshark vagrant
# Choisit l'interface graphique comme cible de démarrage par défaut.
systemctl set-default graphical.target

# Réactive explicitement LightDM au démarrage, comme plus haut.
systemctl enable lightdm
# Démarre ou relance LightDM maintenant ; l'échec éventuel ne bloque pas le provisionnement.
systemctl restart lightdm || true
