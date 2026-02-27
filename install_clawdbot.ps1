<#
.SYNOPSIS
    Automatisierte Installation von Clawdbot (OpenClaw) für Windows.

.DESCRIPTION
    Dieses Skript prüft, ob es mit Administratorrechten ausgeführt wird,
    installiert bei Bedarf Node.js (via winget), aktualisiert die PATH-Umgebung,
    installiert "openclaw" global und startet anschließend den Onboarding-Wizard.
#>

$ErrorActionPreference = 'Stop'

# --- Hilfsfunktionen für farbige Konsolenausgaben ---
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[ERFOLG] $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[FEHLER] $Message" -ForegroundColor Red
}

Write-Host "`n=== Clawdbot Installation ===`n" -ForegroundColor Cyan

# --- 1. Rechte-Prüfung (Administrator) ---
Write-Info "Prüfe Administratorrechte..."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ErrorMsg "Dieses Skript benötigt Administratorrechte."
    Write-ErrorMsg "Bitte starte PowerShell als Administrator (Rechtsklick -> Als Administrator ausführen) und versuche es erneut."
    exit
}
Write-Success "Administratorrechte bestätigt."

try {
    # --- 2. Abhängigkeiten (Node.js & npm) prüfen & installieren ---
    Write-Info "Prüfe auf Node.js und npm..."
    
    $nodeInstalled = $false
    try {
        # Wir setzen ErrorAction auf SilentlyContinue, falls node nicht gefunden wird
        $nodeVersion = Invoke-Expression "node -v" -ErrorAction SilentlyContinue
        $npmVersion = Invoke-Expression "npm -v" -ErrorAction SilentlyContinue
        if ($nodeVersion -and $npmVersion) {
            $nodeInstalled = $true
            Write-Success "Node.js ($nodeVersion) und npm ($npmVersion) sind bereits installiert."
        }
    } catch {
        # Ignorieren, wird unten behandelt
    }

    if (-not $nodeInstalled) {
        Write-Info "Node.js und/oder npm fehlen. Starte automatische Installation via winget..."
        
        # winget Installation
        # Argumente: -e (exact), --accept-source-agreements, --accept-package-agreements
        # Wir fangen Fehler von winget ab
        winget install OpenJS.NodeJS -e --accept-source-agreements --accept-package-agreements
        
        Write-Success "Node.js wurde erfolgreich über winget installiert."

        # --- 3. Umgebungsvariablen (PATH) aktualisieren ---
        Write-Info "Aktualisiere die PATH-Umgebungsvariable im laufenden Skript..."
        
        # System- und User-PATH aus der Registry neu laden
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machinePath;$userPath"
        
        # Kurze Pause, falls das System Zeit zum Registrieren der Dateien benötigt
        Start-Sleep -Seconds 2
        
        try {
            $newNodeVersion = Invoke-Expression "node -v" -ErrorAction Stop
            Write-Success "Neue Umgebungsvariablen geladen. Node.js Version: $newNodeVersion"
        } catch {
            Write-ErrorMsg "Node.js konnte nach der Installation nicht im PATH gefunden werden."
            Write-ErrorMsg "Möglicherweise ist ein manueller Neustart der PowerShell erforderlich."
            exit
        }
    }

    # --- 4. OpenClaw installieren ---
    Write-Info "Installiere OpenClaw global über npm..."
    
    # npm global installieren
    # Wir rufen npm über cmd.exe auf, was manchmal in PowerShell stabiler läuft, wenn es um globale Installationen geht
    cmd.exe /c "npm install -g openclaw"
    
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Die Installation von OpenClaw ist fehlgeschlagen."
        exit
    }
    
    Write-Success "OpenClaw erfolgreich installiert."

    # --- 5. Onboarding starten ---
    Write-Info "Starte Clawdbot Onboarding-Prozess..."
    
    try {
        # Wir rufen openclaw oder npx über cmd.exe auf, um interaktive Prompts besser zu unterstützen
        # Fallback auf npx
        cmd.exe /c "openclaw onboard || npx openclaw onboard"
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Der Onboarding-Prozess ist fehlgeschlagen oder wurde abgebrochen."
            exit
        }
    } catch {
        Write-ErrorMsg "Fehler beim Aufruf des Onboarding-Prozesses."
        exit
    }

    # --- 6. Nutzer-Information ---
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Green
    Write-Host "  Die Einrichtung von Clawdbot ist erfolgreich abgeschlossen!          " -ForegroundColor Green
    Write-Host "  Der Bot ist nun voll integriert und läuft ab sofort (bzw. ist bereit).  " -ForegroundColor Green
    Write-Host "=========================================================================" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-ErrorMsg "Es ist ein unerwarteter Fehler aufgetreten:"
    Write-ErrorMsg $_.Exception.Message
    exit
}
