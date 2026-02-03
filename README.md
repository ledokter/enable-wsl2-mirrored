# 🌐 WSL2 Network Bridge - Accès Réseau Local

Scripts pour permettre à WSL2 de communiquer directement avec le réseau local et effectuer des scans réseau (arp-scan, nmap, netdiscover).

## 🎯 Pourquoi ?

Par défaut, WSL2 utilise un réseau NAT virtualisé qui empêche :
- ❌ Les scans ARP du réseau local (`arp-scan -l`)
- ❌ La découverte de périphériques sur le LAN
- ❌ L'accès direct depuis d'autres machines du réseau
- ❌ Les scans réseau complets avec nmap

Cette solution configure WSL2 pour un accès réseau **direct** au LAN.

## 📋 Solutions Disponibles

### Solution 1 : Mode Mirrored (Windows 11 22H2+) ⭐ **Recommandé**

- ✅ Configuration automatique
- ✅ Persiste après redémarrage
- ✅ Support IPv6
- ✅ Meilleure performance
- ⚠️ Nécessite Windows 11 build 22621+

### Solution 2 : Mode Bridge Hyper-V (Windows 10)

- ✅ Compatible Windows 10
- ✅ Accès réseau complet
- ⚠️ Configuration manuelle nécessaire
- ⚠️ À refaire après chaque redémarrage Windows

## 🚀 Installation

### Windows 11 - Mode Mirrored (Recommandé)

**1. Exécuter le script PowerShell (Admin)**

```powershell
# Télécharger
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ledokter/wsl2-network-bridge/main/enable-wsl2-mirrored.ps1" -OutFile "enable-wsl2-mirrored.ps1"

# Exécuter
Set-ExecutionPolicy Bypass -Scope Process -Force
.\enable-wsl2-mirrored.ps1
2. Dans WSL2, installer les outils

bash
# Télécharger le script
wget https://raw.githubusercontent.com/ledokter/wsl2-network-bridge/main/setup-wsl2-network.sh

# Rendre exécutable
chmod +x setup-wsl2-network.sh

# Exécuter
./setup-wsl2-network.sh
3. Tester

bash
sudo arp-scan -l
Windows 10 - Mode Bridge
1. Exécuter le script PowerShell (Admin)

powershell
.\enable-wsl2-bridge.ps1
2. Sélectionner votre adaptateur réseau

text
Adaptateurs réseau disponibles :
   Ethernet - Intel(R) Ethernet Connection[1]
   Wi-Fi - Realtek Wireless Adapter[2]

Sélectionnez l'adaptateur à bridge (numéro): 1
3. Dans WSL2, configurer le réseau

bash
sudo /tmp/wsl-network-setup.sh
4. Installer les outils

bash
./setup-wsl2-network.sh
💻 Utilisation
Scan ARP du Réseau Local
bash
# Scan complet du réseau local
sudo arp-scan -l

# Spécifier l'interface
sudo arp-scan --interface=eth0 -l

# Scan d'un sous-réseau spécifique
sudo arp-scan 192.168.1.0/24
Exemple de sortie :

text
Interface: eth0, type: EN10MB, MAC: 00:15:5d:xx:xx:xx, IPv4: 192.168.1.100
Starting arp-scan 1.9.7 with 256 hosts (https://github.com/royhills/arp-scan)
192.168.1.1     aa:bb:cc:dd:ee:ff       TP-LINK TECHNOLOGIES CO.,LTD.
192.168.1.10    11:22:33:44:55:66       Apple, Inc.
192.168.1.25    77:88:99:aa:bb:cc       Samsung Electronics Co.,Ltd
192.168.1.50    dd:ee:ff:00:11:22       Raspberry Pi Foundation

4 packets received by filter, 0 packets dropped by kernel
Ending arp-scan 1.9.7: 256 hosts scanned in 1.234 seconds (207.47 hosts/sec). 4 responded
Scan Nmap
bash
# Ping scan du réseau
sudo nmap -sn 192.168.1.0/24

# Scan détaillé d'un hôte
sudo nmap -A 192.168.1.1

# Scan de ports
sudo nmap -p 1-1000 192.168.1.1
Netdiscover
bash
# Découverte active
sudo netdiscover -i eth0

# Mode passif (écoute)
sudo netdiscover -i eth0 -p

# Scan d'un sous-réseau
sudo netdiscover -i eth0 -r 192.168.1.0/24
Script Rapide
bash
# Utiliser le script de scan rapide
~/network-scan.sh
🔧 Configuration Manuelle
Fichier .wslconfig (Windows 11)
Créez C:\Users\VotreNom\.wslconfig :

text
[wsl2]
networkingMode=mirrored
dnsTunneling=true
ipv6=true
autoProxy=true
firewall=true
memory=4GB
processors=2
Appliquez :

powershell
wsl --shutdown
Vérifier la Configuration
Windows :

powershell
# Voir l'IP Windows
ipconfig

# Voir l'IP WSL2
wsl hostname -I
WSL2 :

bash
# Voir les interfaces
ip addr show

# Voir les routes
ip route

# Voir la passerelle
ip route | grep default
🐛 Dépannage
Problème : arp-scan ne retourne rien
Solution 1 - Vérifier l'interface :

bash
# Lister les interfaces
ip link show

# Utiliser la bonne interface
sudo arp-scan --interface=eth0 -l
Solution 2 - Vérifier les permissions :

bash
# Ajouter les capabilities
sudo setcap cap_net_raw+ep /usr/sbin/arp-scan

# Ou utiliser sudo
sudo arp-scan -l
Problème : "No such device" (eth0)
Solution :

bash
# Voir les interfaces disponibles
ip link show

# Utiliser l'interface correcte (ex: eth1)
sudo arp-scan --interface=eth1 -l
Problème : Mode mirrored ne fonctionne pas
Solution :

bash
# Vérifier la version de Windows
winver
# Nécessite build 22621+

# Vérifier .wslconfig
cat /mnt/c/Users/$USER/.wslconfig

# Redémarrer complètement
powershell
wsl --shutdown
# Attendre 10 secondes
wsl
Problème : IP WSL2 change à chaque redémarrage (Mode Bridge)
Solution - Script de reconnexion automatique :

Créez un script Windows qui se lance au démarrage :

powershell
# Dans Task Scheduler : Au démarrage
Set-VMSwitch -Name "WSL" -NetAdapterName "Ethernet"
Start-Sleep -Seconds 5
wsl -e sudo dhclient eth0
Problème : Pare-feu bloque les scans
Solution Windows :

powershell
# Désactiver temporairement (pour test)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Ou ajouter une règle
New-NetFirewallRule -DisplayName "WSL2 Network" -Direction Inbound -Action Allow
Solution Linux :

bash
# Vérifier iptables
sudo iptables -L

# Désactiver temporairement
sudo iptables -F
📊 Comparaison des Modes
Caractéristique	Mode Mirrored (Win11)	Mode Bridge (Win10)
OS requis	Windows 11 22H2+	Windows 10/11
Installation	Simple (.wslconfig)	Complexe (Hyper-V)
Persistance	✅ Permanent	❌ À refaire à chaque boot
Performance	⚡ Excellente	🐢 Bonne
IPv6	✅ Oui	⚠️ Limité
Recommandé	⭐⭐⭐⭐⭐	⭐⭐⭐
🔒 Sécurité
Avertissements
⚠️ WSL2 sera visible sur le réseau local

⚠️ Ouvrez uniquement les ports nécessaires

⚠️ Utilisez un pare-feu dans WSL2

⚠️ Ne scannez que vos propres réseaux

Bonnes Pratiques
bash
# Installer un pare-feu
sudo apt install ufw -y

# Activer
sudo ufw enable

# Autoriser SSH seulement depuis le LAN
sudo ufw allow from 192.168.1.0/24 to any port 22
📚 Ressources
Documentation WSL Networking

Win 11 Mirrored Mode

arp-scan Documentation

Nmap Reference

🤝 Contribution
Les contributions sont bienvenues ! Testez sur différentes configurations et signalez les bugs.

⚖️ Licence
MIT License

📬 Contact
Auteur : ledokter

⭐ Si ce projet vous aide, donnez une étoile !

