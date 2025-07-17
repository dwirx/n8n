#!/bin/bash

APP_NAME="n8n"
SCRIPT_PATH="$HOME/.n8n-start.sh"
ENV_FILE=".env"

#  Warna terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

# Ambil IP lokal dengan cara universal
get_host() {
  ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1
}

# Ambil PORT dari file .env atau fallback ke 5678
get_port() {
  if [ -f "$ENV_FILE" ]; then
    grep -E "^N8N_PORT=" "$ENV_FILE" | cut -d '=' -f2
  else
    echo "5678"
  fi
}

# Tampilkan URL akses
show_url() {
  PORT=$(get_port)
  HOST=$(get_host)
  echo -e "${CYAN} Akses n8n via:"
  echo -e "   • LAN     : http://$HOST:$PORT/"
  echo -e "   • Local   : http://127.0.0.1:$PORT/${RESET}"
}

# Buat skrip eksekusi jika belum ada
if [ ! -f "$SCRIPT_PATH" ]; then
  cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi
npx n8n
EOF
  chmod +x "$SCRIPT_PATH"
fi

# Cek apakah proses aktif
is_running() {
  pm2 list | grep -q "$APP_NAME" && pm2 info "$APP_NAME" | grep -q "online"
}

# Start dengan IP otomatis
start_n8n() {
  HOST=$(get_host)
  echo -e "${YELLOW} Menentukan N8N_HOST=${HOST}${RESET}"
  pm2 start "$SCRIPT_PATH" --name "$APP_NAME" --env N8N_HOST=$HOST
  pm2 save
}

# Tampilkan status
status_info() {
  echo ""
  if is_running; then
    echo -e "${GREEN} STATUS: n8n sedang berjalan.${RESET}"
    show_url
  else
    echo -e "${RED} STATUS: n8n tidak berjalan.${RESET}"
  fi
  echo ""
}

# Menu interaktif
while true; do
  clear
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗"
  echo "║         N8N PM2 MANAGER (CLI)          ║"
  echo "╠════════════════════════════════════════╣${RESET}"
  status_info
  echo -e "${BOLD}1)  Jalankan n8n"
  echo "2)  Hentikan n8n"
  echo "3)  Restart n8n"
  echo "4)  Lihat status"
  echo "5)  Lihat log"
  echo "6) ❌ Hapus dari PM2"
  echo -e "7)  Keluar${RESET}"
  echo -ne "${YELLOW} Pilih [1-7]: ${RESET}"
  read choice

  case $choice in
    1)
      if is_running; then
        echo -e "${GREEN}✅ n8n sudah berjalan.${RESET}"
      else
        echo -e "${CYAN} Menjalankan n8n...${RESET}"
        start_n8n
        sleep 2
        show_url
      fi
      ;;
    2)
      if is_running; then
        echo -e "${RED} Menghentikan n8n...${RESET}"
        pm2 stop "$APP_NAME"
      else
        echo -e "${YELLOW}ℹ️ n8n tidak sedang berjalan.${RESET}"
      fi
      ;;
    3)
      if is_running; then
        echo -e "${YELLOW} Restarting n8n...${RESET}"
        pm2 restart "$APP_NAME" --env N8N_HOST=$(get_host)
      else
        echo -e "${YELLOW}⚠️ n8n belum berjalan. Menjalankan sekarang...${RESET}"
        start_n8n
      fi
      sleep 2
      show_url
      ;;
    4)
      status_info
      read -p "Tekan Enter untuk kembali..."
      ;;
    5)
      echo -e "${CYAN} Menampilkan log real-time...${RESET}"
      pm2 logs "$APP_NAME"
      ;;
    6)
      if pm2 list | grep -q "$APP_NAME"; then
        echo -e "${RED}❌ Menghapus proses dari PM2...${RESET}"
        pm2 delete "$APP_NAME"
      else
        echo -e "${YELLOW}ℹ️ n8n tidak terdaftar di PM2.${RESET}"
      fi
      ;;
    7)
      echo -e "${CYAN} Keluar dari N8N Manager.${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}❗ Pilihan tidak valid.${RESET}"
      ;;
  esac

  echo ""
  read -p "Tekan Enter untuk kembali ke menu..."
done

