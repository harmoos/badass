# BADASS

## VM de base

Depuis la racine du dépôt, aller dans `vm_base` :

```bash
cd vm_base
```

| Commande sur l'hôte | Utilité |
| --- | --- |
| `vagrant up` | Créer ou démarrer la VM ; le premier démarrage lance aussi `setup.sh`. |
| `vagrant status` | Voir si la VM est démarrée. |
| `vagrant ssh` | Ouvrir un terminal dans la VM. |
| `vagrant provision` | Relancer `setup.sh` après sa modification. |
| `vagrant reload` | Redémarrer la VM après une modification du `Vagrantfile`. |
| `vagrant halt` | Arrêter la VM. |

Après `vagrant ssh`, commandes utiles **dans la VM** :

| Commande dans la VM | Utilité |
| --- | --- |
| `cd /vagrant` | Accéder au dépôt partagé avec la VM. |
| `docker version` | Vérifier le client et le moteur Docker. |
| `docker ps` | Vérifier l'accès à Docker et afficher les conteneurs en cours. |
| `gns3 --version` | Vérifier l'installation de l'interface GNS3. |
| `gns3server --version` | Vérifier l'installation du serveur GNS3. |
| `systemctl is-active docker xrdp lightdm` | Vérifier les services Docker, RDP et graphiques. |

Pour ouvrir **l'interface graphique GNS3**, lancer `gns3` depuis un terminal du bureau XFCE de la VM. Le bureau est visible dans VirtualBox ou via RDP sur `localhost:3389` avec le compte `vagrant` (mot de passe `vagrant`).
