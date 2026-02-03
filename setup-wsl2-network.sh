#!/bin/bash

###############################################################################
# Script de configuration réseau pour WSL2
# Installe les outils de scan réseau et configure l'interface
###############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header "CONFIGURATION RÉSEAU WSL2"

# Vérifier si on est sous WSL2
if ! grep -qi microsoft /proc/version; then
    print_error "Ce script doit être exécuté dans WSL2"
    exit 1
fi

print_success "Environnement WSL2 détecté"

# Mise à jour du système
print_header "Mise à jour du système"
sudo apt update
sudo apt upgrade -y

# Installation des outils réseau
print_header "Installation des outils de scan réseau"
echo -e "${YELLOW}Installation : arp-scan, nmap, netdiscover, net-tools${NC}"

sudo apt install -y \
    arp-scan \
    nmap \
    netdiscover \
    net-tools \
    iproute2 \
    iputils-ping \
    traceroute \
    tcpdump \
    dnsutils \
    ethtool

print_success "Outils installés"

# Configuration réseau
print_header "Configuration de l'interface réseau"

# Détecter l'interface principale
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi

print_success "Interface détectée : $INTERFACE"

# Afficher la configuration actuelle
echo -e "\n${BLUE}Configuration actuelle :${NC}"
ip addr show $INTERFACE
echo ""
ip route
echo ""

# Vérifier la connectivité
print_header "Test de connectivité"

# Ping vers la passerelle
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)

if [ -n "$GATEWAY" ]; then
    echo -e "${YELLOW}Test ping vers la passerelle ($GATEWAY)...${NC}"
    if ping -c 3 $GATEWAY > /dev/null 2>&1; then
        print_success "Ping vers la passerelle : OK"
    else
        print_warning "Ping vers la passerelle : ÉCHEC"
    fi
fi

# Test DNS
echo -e "${YELLOW}Test résolution DNS...${NC}"
if nslookup google.com > /dev/null 2>&1; then
    print_success "Résolution DNS : OK"
else
    print_warning "Résolution DNS : ÉCHEC"
fi

# Créer un script de scan réseau rapide
print_header "Création des scripts utilitaires"

cat > ~/network-scan.sh << 'EOF'
#!/bin/bash

# Script de scan réseau rapide

echo "════════════════════════════════════════"
echo " SCAN DU RÉSEAU LOCAL"
echo "════════════════════════════════════════"
echo ""

# Détecter le réseau
NETWORK=$(ip route | grep -v default | grep src | awk '{print $1}' | head -1)

if [ -z "$NETWORK" ]; then
    echo "❌ Impossible de détecter le réseau"
    exit 1
fi

echo "📡 Réseau détecté : $NETWORK"
echo ""

# ARP Scan
echo "🔍 Scan ARP en cours..."
sudo arp-scan -l -I eth0 2>/dev/null | grep -v "packets received"

echo ""
echo "✅ Scan terminé"
EOF

chmod +x ~/network-scan.sh
print_success "Script créé : ~/network-scan.sh"

# Créer un alias dans bashrc
if ! grep -q "alias netscan" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Alias scan réseau" >> ~/.bashrc
    echo "alias netscan='sudo arp-scan -l'" >> ~/.bashrc
    echo "alias netmap='sudo nmap -sn'" >> ~/.bashrc
    echo "alias netdiscover='sudo netdiscover -i eth0'" >> ~/.bashrc
    print_success "Alias ajoutés à ~/.bashrc"
fi

# Message final
print_header "CONFIGURATION TERMINÉE"
echo ""
print_success "Configuration réseau WSL2 terminée !"
echo ""
echo -e "${BLUE}Commandes disponibles :${NC}"
echo ""
echo -e "  ${GREEN}sudo arp-scan -l${NC}                    # Scanner le réseau local (ARP)"
echo -e "  ${GREEN}sudo nmap -sn 192.168.1.0/24${NC}       # Scanner un sous-réseau (ICMP)"
echo -e "  ${GREEN}sudo netdiscover -i eth0${NC}           # Découverte active (ARP)"
echo -e "  ${GREEN}~/network-scan.sh${NC}                  # Script de scan rapide"
echo ""
echo -e "${YELLOW}Exemples d'utilisation :${NC}"
echo -e "  sudo arp-scan -l                        # Scan complet"
echo -e "  sudo arp-scan --interface=eth0 -l       # Spécifier l'interface"
echo -e "  sudo nmap -sP 192.168.1.0/24            # Ping scan"
echo -e "  sudo nmap -A 192.168.1.1                # Scan détaillé d'un hôte"
echo ""
echo -e "${BLUE}Rechargez votre shell avec :${NC}"
echo -e "  ${GREEN}source ~/.bashrc${NC}"
echo ""
