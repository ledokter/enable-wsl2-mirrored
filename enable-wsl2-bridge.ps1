###############################################################################
# Script d'activation du mode Bridge pour WSL2 (Windows 10)
# Crée un pont réseau entre l'adaptateur physique et WSL2
###############################################################################

# Vérifier les privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Ce script nécessite des privilèges administrateur" -ForegroundColor Red
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " ACTIVATION DU MODE BRIDGE POUR WSL2 (WINDOWS 10)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Lister les adaptateurs réseau
Write-Host "`n[1/5] Détection des adaptateurs réseau..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*WSL*"}

Write-Host "`nAdaptateurs réseau disponibles :" -ForegroundColor Cyan
$i = 1
foreach ($adapter in $adapters) {
    Write-Host "  [$i] $($adapter.Name) - $($adapter.InterfaceDescription)" -ForegroundColor Gray
    $i++
}

# Sélectionner l'adaptateur
$selection = Read-Host "`nSélectionnez l'adaptateur à bridge (numéro)"
$selectedAdapter = $adapters[$selection - 1]

if (-not $selectedAdapter) {
    Write-Host "❌ Sélection invalide" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Adaptateur sélectionné : $($selectedAdapter.Name)" -ForegroundColor Green

# Arrêter WSL2
Write-Host "`n[2/5] Arrêt de WSL2..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 3
Write-Host "✅ WSL2 arrêté" -ForegroundColor Green

# Configurer le bridge Hyper-V
Write-Host "`n[3/5] Configuration du bridge Hyper-V..." -ForegroundColor Yellow

try {
    Set-VMSwitch -Name "WSL" -NetAdapterName $selectedAdapter.Name -AllowManagementOS $true
    Write-Host "✅ Bridge configuré avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la configuration du bridge" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Créer le script de configuration réseau WSL
Write-Host "`n[4/5] Création du script de configuration WSL..." -ForegroundColor Yellow

$wslNetworkScript = @'
#!/bin/bash

# Configuration réseau pour WSL2 en mode bridge

echo "Configuration du réseau WSL2..."

# Attendre que l'interface soit disponible
sleep 2

# Configurer DHCP sur eth0
sudo ip addr flush dev eth0
sudo dhclient eth0

# Afficher la configuration
echo ""
echo "Configuration réseau :"
ip addr show eth0
echo ""
ip route
echo ""
echo "✅ Configuration terminée"
'@

$scriptPath = "$env:TEMP\wsl-network-setup.sh"
$wslNetworkScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force

# Copier le script dans WSL
wsl -e mkdir -p /tmp
wsl -e bash -c "cat > /tmp/wsl-network-setup.sh << 'EOF'
$wslNetworkScript
EOF"
wsl -e chmod +x /tmp/wsl-network-setup.sh

Write-Host "✅ Script créé dans WSL : /tmp/wsl-network-setup.sh" -ForegroundColor Green

# Démarrer WSL2
Write-Host "`n[5/5] Démarrage de WSL2..." -ForegroundColor Yellow
wsl -e echo "WSL2 started"
Start-Sleep -Seconds 2
Write-Host "✅ WSL2 démarré" -ForegroundColor Green

# Instructions finales
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " CONFIGURATION TERMINÉE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT : Exécutez ces commandes dans WSL2 :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  wsl" -ForegroundColor Cyan
Write-Host "  sudo /tmp/wsl-network-setup.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testez ensuite :" -ForegroundColor Yellow
Write-Host "  sudo apt install arp-scan -y" -ForegroundColor Cyan
Write-Host "  sudo arp-scan -l" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Note : Vous devrez re-configurer le bridge à chaque redémarrage de Windows" -ForegroundColor Yellow
Write-Host ""
