###############################################################################
# Script d'activation du mode réseau Mirrored pour WSL2 (Windows 11 22H2+)
# Permet l'accès direct au réseau local pour arp-scan, nmap, etc.
###############################################################################

# Vérifier les privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Ce script nécessite des privilèges administrateur" -ForegroundColor Red
    Write-Host "Relancez PowerShell en tant qu'administrateur" -ForegroundColor Yellow
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " ACTIVATION DU MODE RÉSEAU MIRRORED POUR WSL2" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Vérifier la version de Windows
$windowsVersion = [System.Environment]::OSVersion.Version
if ($windowsVersion.Build -lt 22621) {
    Write-Host "⚠️  Windows 11 22H2 (build 22621) ou supérieur requis" -ForegroundColor Yellow
    Write-Host "Votre build : $($windowsVersion.Build)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Utilisez le script 'enable-wsl2-bridge.ps1' pour Windows 10" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ Windows 11 22H2+ détecté (build $($windowsVersion.Build))" -ForegroundColor Green

# Chemin du fichier .wslconfig
$wslConfigPath = "$env:USERPROFILE\.wslconfig"

Write-Host "`n[1/4] Configuration de .wslconfig..." -ForegroundColor Yellow

# Créer ou modifier .wslconfig
$wslConfig = @"
[wsl2]
# Mode réseau mirrored - Accès direct au réseau local
networkingMode=mirrored

# Activer DNS tunneling
dnsTunneling=true

# Support IPv6
ipv6=true

# Auto-proxy
autoProxy=true

# Firewall Hyper-V
firewall=true

# Performances
memory=4GB
processors=2
swap=2GB
"@

$wslConfig | Out-File -FilePath $wslConfigPath -Encoding UTF8 -Force
Write-Host "✅ Fichier .wslconfig créé : $wslConfigPath" -ForegroundColor Green

# Afficher le contenu
Write-Host "`nContenu de .wslconfig :" -ForegroundColor Cyan
Get-Content $wslConfigPath | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

# Arrêter WSL2
Write-Host "`n[2/4] Arrêt de WSL2..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 3
Write-Host "✅ WSL2 arrêté" -ForegroundColor Green

# Configuration du pare-feu Windows
Write-Host "`n[3/4] Configuration du pare-feu Windows..." -ForegroundColor Yellow

$firewallRules = @(
    @{Name="WSL2 - Inbound"; Direction="Inbound"; Action="Allow"},
    @{Name="WSL2 - Outbound"; Direction="Outbound"; Action="Allow"}
)

foreach ($rule in $firewallRules) {
    $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
    if ($existingRule) {
        Write-Host "  ℹ️  Règle '$($rule.Name)' existe déjà" -ForegroundColor Gray
    } else {
        New-NetFirewallRule -DisplayName $rule.Name `
                            -Direction $rule.Direction `
                            -Action $rule.Action `
                            -Enabled True `
                            -Profile Any | Out-Null
        Write-Host "  ✅ Règle '$($rule.Name)' créée" -ForegroundColor Green
    }
}

# Démarrer WSL2
Write-Host "`n[4/4] Démarrage de WSL2..." -ForegroundColor Yellow
wsl -e echo "WSL2 started"
Start-Sleep -Seconds 2
Write-Host "✅ WSL2 démarré" -ForegroundColor Green

# Vérifier la configuration
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " VÉRIFICATION DE LA CONFIGURATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`nAdresse IP Windows :" -ForegroundColor Yellow
$windowsIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" | Select-Object -First 1).IPAddress
Write-Host "  $windowsIP" -ForegroundColor Green

Write-Host "`nAdresse IP WSL2 :" -ForegroundColor Yellow
$wslIP = wsl hostname -I
Write-Host "  $wslIP" -ForegroundColor Green

if ($windowsIP -eq $wslIP.Trim()) {
    Write-Host "`n✅ MODE MIRRORED ACTIVÉ - Les IPs correspondent !" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Les IPs diffèrent - Le mode mirrored peut ne pas être actif" -ForegroundColor Yellow
    Write-Host "Redémarrez Windows si nécessaire" -ForegroundColor Gray
}

# Instructions finales
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " CONFIGURATION TERMINÉE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Mode réseau mirrored activé !" -ForegroundColor Green
Write-Host ""
Write-Host "Testez depuis WSL2 :" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor Cyan
Write-Host "  sudo apt install arp-scan -y" -ForegroundColor Cyan
Write-Host "  sudo arp-scan -l" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commandes utiles :" -ForegroundColor Yellow
Write-Host "  ip addr show          # Voir les interfaces" -ForegroundColor Gray
Write-Host "  ip route              # Voir les routes" -ForegroundColor Gray
Write-Host "  sudo nmap -sn 192.168.1.0/24  # Scanner le réseau" -ForegroundColor Gray
Write-Host ""
