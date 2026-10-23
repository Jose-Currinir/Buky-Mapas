#!/usr/bin/env bash
#
# Programa la actualización automática de datos con systemd (Linux):
# todos los domingos a las 04:00 (hora del servidor) ejecuta ./manage.sh update.
# Los registros quedan en: journalctl -u buky-mapas-update
#
# Uso:  ./scripts/install-timer.sh            instala o actualiza el temporizador
#       ./scripts/install-timer.sh --quitar   lo elimina
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT=buky-mapas-update
command -v systemctl >/dev/null || { echo "Este servidor no usa systemd." >&2; exit 1; }

if [[ "${1:-}" == "--quitar" ]]; then
  sudo systemctl disable --now "$UNIT.timer" 2>/dev/null || true
  sudo rm -f "/etc/systemd/system/$UNIT.service" "/etc/systemd/system/$UNIT.timer"
  sudo systemctl daemon-reload
  echo "Temporizador eliminado."
  exit 0
fi

sudo tee "/etc/systemd/system/$UNIT.service" >/dev/null <<UNITFILE
[Unit]
Description=Buky-Mapas: actualiza mapa y rutas desde OSM sin cortar el servicio
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$(id -un)
WorkingDirectory=$ROOT_DIR
ExecStart=$ROOT_DIR/manage.sh update
UNITFILE

sudo tee "/etc/systemd/system/$UNIT.timer" >/dev/null <<UNITFILE
[Unit]
Description=Buky-Mapas: actualización semanal de datos

[Timer]
OnCalendar=Sun *-*-* 04:00:00
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
UNITFILE

sudo systemctl daemon-reload
sudo systemctl enable --now "$UNIT.timer"
systemctl list-timers "$UNIT.timer" --no-pager
