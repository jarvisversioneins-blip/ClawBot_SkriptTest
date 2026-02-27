#!/usr/bin/env bash

# Beende das Skript sofort, falls ein Befehl mit Fehler fehlschlägt
set -e

# --- Farben für Terminalausgaben ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color (Zurücksetzen)

# --- Hilfsfunktionen für Konsolenausgaben ---
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ERFOLG]${NC} $1"; }
error() { echo -e "${RED}[FEHLER]${NC} $1"; }

# Funktion zur Prüfung, ob ein Befehl (z.B. node, npm) existiert
command_exists() { command -v "$1" >/dev/null 2>&1; }

echo -e "\n${YELLOW}=== Clawdbot Installation ===${NC}\n"

# --- 1. OS-Erkennung ---
OS="$(uname -s)"
info "Betriebssystem wird überprüft: $OS"

if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
    error "Dieses Skript unterstützt nur macOS (Darwin) und Linux."
    exit 1
fi

# --- 2. Abhängigkeiten (Node.js & npm) prüfen und installieren ---
if command_exists node && command_exists npm; then
    success "Node.js ($(node -v | sed 's/v//')) und npm ($(npm -v)) sind bereits installiert."
else
    info "Node.js und/oder npm fehlen. Starte automatische Installation..."
    
    if [ "$OS" = "Darwin" ]; then
        # macOS Installation
        info "macOS erkannt. Prüfe Homebrew..."
        
        # Prüfen, ob Homebrew installiert ist
        if ! command_exists brew; then
            info "Homebrew ist nicht installiert. Installiere Homebrew..."
            # Ohne User-Input wird der Installer hier evtl. stoppen.
            # NONINTERACTIVE=1 führt ihn ohne Enter-Eingabeaufforderung aus.
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { error "Homebrew-Installation fehlgeschlagen."; exit 1; }
            success "Homebrew erfolgreich installiert."
            
            # Homebrew in den aktuellen PATH laden (nötig für Apple Silicon oder bestimmte Intel Setups)
            if [ -x "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -x "/usr/local/bin/brew" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            success "Homebrew ist bereits installiert."
        fi
        
        info "Installiere Node.js über Homebrew..."
        brew install node || { error "Node.js-Installation fehlgeschlagen."; exit 1; }
        
    elif [ "$OS" = "Linux" ]; then
        # Linux Installation (Fokus auf Debian/Ubuntu)
        info "Linux erkannt. Versuche Installation über apt (Debian/Ubuntu)..."
        
        if command_exists apt-get; then
            info "Aktualisiere Paketquellen..."
            sudo apt-get update -y || { error "Paketquellen-Update fehlgeschlagen."; exit 1; }
            
            info "Installiere Node.js & npm..."
            sudo apt-get install -y nodejs npm || { error "Node.js/npm-Installation fehlgeschlagen."; exit 1; }
        else
            error "Es konnte kein apt-Paketmanager gefunden werden. Bitte installiere Node.js manuell."
            exit 1
        fi
    fi
    
    # Letzter Check, ob die Installation erfolgreich war
    if command_exists node && command_exists npm; then
        success "Node.js und npm wurden erfolgreich installiert."
    else
        error "Die Installation von Node.js/npm scheint fehlgeschlagen zu sein. Bitte überprüfe das manuell."
        exit 1
    fi
fi

# --- 3. OpenClaw installieren ---
info "Installiere OpenClaw global über npm..."

if [ "$OS" = "Linux" ]; then
    # Auf Linux wird oftmals sudo für globale npm-Pakete benötigt
    sudo npm install -g openclaw || { error "OpenClaw-Installation fehlgeschlagen."; exit 1; }
else
    # Auf macOS mit Homebrew geht das normalerweise ohne sudo
    npm install -g openclaw || sudo npm install -g openclaw || { error "OpenClaw-Installation fehlgeschlagen."; exit 1; }
fi
success "OpenClaw erfolgreich installiert."

# --- 4. Onboarding starten ---
info "Starte Clawdbot Onboarding-Prozess..."
# Wichtig: openclaw onboard muss die interaktive Eingabe unterstuetzen, weshalb es normal aufgerufen wird
if command_exists openclaw; then
    openclaw onboard || { error "Der Onboarding-Prozess ist fehlgeschlagen oder wurde abgebrochen."; exit 1; }
else
    # Fallback, falls openclaw nicht global im Pfad gefunden wird
    info "Skript versucht Fallback via npx..."
    npx openclaw onboard || { error "Der Onboarding-Prozess via npx ist fehlgeschlagen."; exit 1; }
fi

# --- 5. Nutzer-Information ---
echo ""
success "========================================================================="
success "  Die Einrichtung von Clawdbot ist erfolgreich abgeschlossen!          "
success "  Der Bot ist nun voll integriert und läuft ab sofort im Hintergrund.  "
success "========================================================================="
echo ""
