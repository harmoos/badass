#!/usr/bin/env bash
# 🇫🇷 La première ligne demande à l'environnement de trouver Bash pour exécuter ce script.
# 🇵🇹 A primeira linha pede ao sistema que encontre o Bash para executar este script.
# 🇫🇷 Arrête le provisionnement dès qu'une commande échoue, sauf si son erreur est ignorée explicitement.
# 🇵🇹 Interrompe a preparação da VM quando um comando falha, salvo se o erro for ignorado explicitamente.
set -e

# 🇫🇷 Empêche les outils d'installation Debian d'ouvrir des questions interactives.
# 🇵🇹 Impede que as ferramentas de instalação do Debian façam perguntas interativas.
export DEBIAN_FRONTEND=noninteractive

# 🇫🇷 Prépare la réponse de GRUB : installer son chargeur sur le disque /dev/sda.
# 🇵🇹 Prepara a resposta do GRUB: instalar o carregador no disco /dev/sda.
echo "grub-pc grub-pc/install_devices multiselect /dev/sda" | debconf-set-selections
# 🇫🇷 Autorise aussi GRUB à accepter une sélection vide si son paquet le demande.
# 🇵🇹 Também permite ao GRUB aceitar uma seleção vazia se o pacote a solicitar.
echo "grub-pc grub-pc/install_devices_empty boolean true" | debconf-set-selections
# 🇫🇷 Bloque les mises à jour des paquets GRUB pour éviter leur reconfiguration pendant l'upgrade.
# 🇵🇹 Bloque as atualizações dos pacotes GRUB para evitar a sua reconfiguração durante a atualização.
apt-mark hold grub-pc grub-common grub2-common

# 🇫🇷 Termine la configuration de paquets qui serait restée inachevée.
# 🇵🇹 Conclui a configuração de pacotes que tenha ficado por terminar.
dpkg --configure -a
# 🇫🇷 Actualise la liste des paquets disponibles dans les dépôts Debian.
# 🇵🇹 Atualiza a lista de pacotes disponíveis nos repositórios Debian.
apt-get update -y
# 🇫🇷 Met les paquets à jour, accepte les nouvelles dépendances et privilégie les configurations déjà présentes.
# 🇵🇹 Atualiza os pacotes, aceita novas dependências e dá prioridade às configurações já existentes.
apt-get --with-new-pkgs upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 🇫🇷 Installe le bureau XFCE, le gestionnaire de connexion, l'accès RDP et quelques outils réseau.
# 🇵🇹 Instala o ambiente gráfico XFCE, o gestor de sessões, o acesso RDP e algumas ferramentas de rede.
apt-get install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xrdp dbus-x11 x11-xserver-utils telnet curl git
# 🇫🇷 Active LightDM pour les prochains démarrages de la VM.
# 🇵🇹 Ativa o LightDM para os próximos arranques da VM.
systemctl enable lightdm
# 🇫🇷 Active le serveur RDP pour les prochains démarrages de la VM.
# 🇵🇹 Ativa o servidor RDP para os próximos arranques da VM.
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
# 🇫🇷 Rend le fichier de session graphique accessible au bon propriétaire.
# 🇵🇹 Atribui o ficheiro da sessão gráfica ao seu proprietário correto.
chown vagrant:vagrant /home/vagrant/.xsession

# 🇫🇷 Installe les certificats HTTPS et les outils nécessaires au dépôt Docker.
# 🇵🇹 Instala os certificados HTTPS e as ferramentas necessárias para o repositório Docker.
apt-get install -y ca-certificates gnupg lsb-release
# 🇫🇷 Crée le dossier où APT lira les clés des dépôts tiers, avec des droits adaptés.
# 🇵🇹 Cria a pasta onde o APT lê as chaves de repositórios externos, com as permissões adequadas.
install -m 0755 -d /etc/apt/keyrings
# 🇫🇷 Télécharge la clé de signature Docker et la convertit au format utilisé par APT.
# 🇵🇹 Descarrega a chave de assinatura do Docker e converte-a para o formato usado pelo APT.
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
# 🇫🇷 Permet à APT de lire cette clé de signature.
# 🇵🇹 Permite ao APT ler esta chave de assinatura.
chmod a+r /etc/apt/keyrings/docker.gpg

# 🇫🇷 Ajoute le dépôt Docker pour l'architecture détectée par dpkg et la version détectée par lsb_release.
# 🇵🇹 Adiciona o repositório Docker para a arquitetura detetada pelo dpkg e a versão detetada pelo lsb_release.
# 🇫🇷 « signed-by » désigne la clé Docker ; tee écrit la ligne dans le fichier APT.
# 🇵🇹 « signed-by » indica a chave Docker; tee escreve a linha no ficheiro do APT.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 🇫🇷 Recharge les listes de paquets pour inclure le nouveau dépôt Docker.
# 🇵🇹 Atualiza novamente as listas de pacotes para incluir o novo repositório Docker.
apt-get update -y
# 🇫🇷 Installe le moteur Docker, son client, containerd et les extensions Buildx et Compose.
# 🇵🇹 Instala o motor Docker, o seu cliente, o containerd e as extensões Buildx e Compose.
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 🇫🇷 Autorise les membres du groupe Wireshark à capturer les paquets sans lancer toute l'interface en root.
# 🇵🇹 Permite aos membros do grupo Wireshark capturar pacotes sem iniciar toda a interface como root.
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
# 🇫🇷 Installe Wireshark pour analyser le trafic des topologies GNS3.
# 🇵🇹 Instala o Wireshark para analisar o tráfego das topologias GNS3.
apt-get install -y wireshark

# 🇫🇷 Installe Python, pipx et les bibliothèques/outils nécessaires à GNS3 et à ubridge.
# 🇵🇹 Instala Python, pipx e as bibliotecas/ferramentas necessárias para GNS3 e ubridge.
apt-get install -y python3-pip python3-venv pipx libpcap-dev build-essential libcap2-bin

# 🇫🇷 Compile ubridge seulement s'il n'est pas déjà installé à cet emplacement.
# 🇵🇹 Compila o ubridge apenas se ainda não estiver instalado neste local.
if [ ! -f /usr/local/bin/ubridge ]; then
  # 🇫🇷 Utilise le dossier temporaire pour récupérer et compiler le code source.
  # 🇵🇹 Usa a pasta temporária para descarregar e compilar o código-fonte.
  cd /tmp
  # 🇫🇷 Supprime une ancienne copie temporaire pour repartir d'un dépôt propre.
  # 🇵🇹 Elimina uma cópia temporária anterior para começar com um repositório limpo.
  rm -rf ubridge
  # 🇫🇷 Récupère le code source de ubridge, utilisé par GNS3 pour relier les interfaces.
  # 🇵🇹 Descarrega o código-fonte do ubridge, usado pelo GNS3 para ligar interfaces.
  git clone https://github.com/GNS3/ubridge.git
  # 🇫🇷 Entre dans le dossier du code source téléchargé.
  # 🇵🇹 Entra na pasta do código-fonte descarregado.
  cd ubridge
  # 🇫🇷 Compile le programme avec les outils installés plus haut.
  # 🇵🇹 Compila o programa com as ferramentas instaladas anteriormente.
  make
  # 🇫🇷 Copie le programme compilé dans les chemins système.
  # 🇵🇹 Copia o programa compilado para os diretórios do sistema.
  make install
  # 🇫🇷 Quitte le dossier temporaire une fois l'installation terminée.
  # 🇵🇹 Sai da pasta temporária quando a instalação terminar.
  cd /
# 🇫🇷 Termine la condition qui évite une nouvelle compilation.
# 🇵🇹 Termina a condição que evita uma nova compilação.
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
# 🇫🇷 Installe le serveur GNS3 dans un environnement Python isolé.
# 🇵🇹 Instala o servidor GNS3 num ambiente Python isolado.
pipx install gns3-server
# 🇫🇷 Installe l'interface graphique GNS3 avec ses dépendances Qt 5.
# 🇵🇹 Instala a interface gráfica do GNS3 com as suas dependências Qt 5.
pipx install gns3-gui[qt5]

# 🇫🇷 Écrit le fichier qui ajoute GNS3 au menu des applications du bureau.
# 🇵🇹 Escreve o ficheiro que adiciona o GNS3 ao menu de aplicações do ambiente gráfico.
# 🇫🇷 [Desktop Entry] ouvre la définition du raccourci.
# 🇵🇹 [Desktop Entry] inicia a definição do atalho.
# 🇫🇷 Type=Application indique qu'il lance un programme.
# 🇵🇹 Type=Application indica que o atalho inicia um programa.
# 🇫🇷 Encoding=UTF-8 précise l'encodage du fichier.
# 🇵🇹 Encoding=UTF-8 indica a codificação do ficheiro.
# 🇫🇷 Name=GNS3 définit le nom visible dans le menu.
# 🇵🇹 Name=GNS3 define o nome visível no menu.
# 🇫🇷 Comment donne la description affichée par le bureau.
# 🇵🇹 Comment define a descrição mostrada pelo ambiente gráfico.
# 🇫🇷 Exec indique la commande lancée quand on clique sur le raccourci.
# 🇵🇹 Exec indica o comando executado ao clicar no atalho.
# 🇫🇷 Icon demande l'icône nommée gns3.
# 🇵🇹 Icon indica o ícone com o nome gns3.
# 🇫🇷 Terminal=false évite d'ouvrir un terminal ; Categories choisit les menus d'affichage.
# 🇵🇹 Terminal=false evita abrir um terminal; Categories escolhe os menus onde o atalho aparece.
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
# 🇫🇷 Choisit l'interface graphique comme cible de démarrage par défaut.
# 🇵🇹 Define a interface gráfica como objetivo de arranque predefinido.
systemctl set-default graphical.target

# 🇫🇷 Réactive explicitement LightDM au démarrage, comme plus haut.
# 🇵🇹 Volta a ativar explicitamente o LightDM no arranque, como acima.
systemctl enable lightdm
# 🇫🇷 Démarre ou relance LightDM maintenant ; l'échec éventuel ne bloque pas le provisionnement.
# 🇵🇹 Inicia ou reinicia o LightDM agora; uma eventual falha não interrompe a preparação da VM.
systemctl restart lightdm || true
