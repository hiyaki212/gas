#!/data/data/com.termux/files/usr/bin/bash
# ngapain ke sini cuma untuk install doang ngak aneh aneh
# pelajari jangan kopas sekarang AI ada banyak minta aja bantu sama AI
# Warna untuk output
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
N='\033[0m'

encrypsi() {
    # Gunakan path absolut
    GAS_PATH="$PWD/gas"
    GASKAN_PATH="$PWD/gaskan"

    # Cek jika file 'gas' tidak ada
    if [ ! -f "$GAS_PATH" ]; then
        echo -e "${R}[!] Error: File 'gas' tidak ditemukan di $GAS_PATH!${N}"
        echo -e "${Y}[*] File yang ada di direktori ini:${N}"
        ls -l
        return 1
    fi

    # Enkripsi dengan SHC
    echo -e "${Y}[*] Memulai enkripsi '$GAS_PATH' -> '$GASKAN_PATH'...${N}"
    shc -f "$GAS_PATH" -o "$GASKAN_PATH"

    # Verifikasi hasil enkripsi
    if [ $? -eq 0 ] && [ -f "$GASKAN_PATH" ]; then
        chmod 700 "$GASKAN_PATH"
        echo -e "${G}[✓] Enkripsi berhasil!${N}"

        # Hapus file asli SECARA PERMANEN dengan metode overwrite
        echo -e "${Y}[!] Menghapus file asli '$GAS_PATH'...${N}"

        # Metode penghapusan aman (pilih salah satu):
        # 1. Overwrite lalu hapus
        echo -e "${Y}[*] Menggunakan shred...${N}"
        if command -v shred &>/dev/null; then
            shred -u -z -n 5 "$GAS_PATH" && {
                echo -e "${G}[✓] File asli di-overwrite dan dihapus aman${N}"
                return 0
            }
        fi

        # 2. Fallback: overwrite manual
        echo -e "${Y}[*] Menggunakan dd (fallback)...${N}"
        dd if=/dev/zero of="$GAS_PATH" bs=1M count=3 status=none
        rm -f "$GAS_PATH" && {
            echo -e "${G}[✓] File asli dihapus${N}"
            return 0
        }

        # 3. Fallback terakhir: hapus biasa
        echo -e "${Y}[*] Menggunakan rm biasa...${N}"
        rm -f "$GAS_PATH" && {
            echo -e "${G}[✓] File asli dihapus${N}"
            return 0
        }

        echo -e "${R}[X] Gagal menghapus file asli! Hapus manual dengan: rm -f '$GAS_PATH'${N}"
        return 1
    else
        echo -e "${R}[X] Enkripsi gagal! File 'gas' tetap ada di $GAS_PATH${N}"
        return 1
    fi
}

# Fungsi untuk mengecek dan menginstal ngrok
install_ngrok() {
    echo -e "${Y}[*] Mengecek Ngrok...${N}"

    if command -v ngrok >/dev/null 2>&1; then
        echo -e "${G}[+] Ngrok sudah terinstall${N}"
sleep 1
        return 0
    fi

    echo -e "${Y}[*] Menginstal Ngrok...${N}"

    # Download dan instal ngrok
    if ! pkg install -y wget unzip; then
        echo -e "${R}[-] Gagal menginstal dependencies (wget/unzip)${N}"
        return 1
    fi

    arch=$(uname -m)
    case $arch in
        aarch64) ngrok_arch="arm64" ;;
        arm*) ngrok_arch="arm" ;;
        i*86) ngrok_arch="386" ;;
        x86_64) ngrok_arch="amd64" ;;
        *) ngrok_arch="arm" ;;
    esac

    ngrok_url="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-${ngrok_arch}.zip"

    if wget "$ngrok_url" -O ngrok.zip; then
        unzip ngrok.zip
        chmod +x ngrok
        mv ngrok /data/data/com.termux/files/usr/bin/
        rm ngrok.zip
        echo -e "${G}[+] Ngrok berhasil diinstall${N}"
        return 0
    else
        echo -e "${R}[-] Gagal mengunduh Ngrok${N}"
        return 1
    fi
}

# Fungsi untuk konfigurasi token ngrok
configure_ngrok() {
    echo -e "${Y}[*] Konfigurasi Ngrok Token...${N}"

    if [ -f "$HOME/.ngrok2/ngrok.yml" ]; then
        echo -e "${G}[+] File konfigurasi Ngrok sudah ada${N}"
        return 0
    fi

    if [ -z "$NGROK_TOKEN" ]; then
        echo -e "${B}[?] Masukkan Ngrok Token Anda (dapat dari https://dashboard.ngrok.com/get-started/your-authtoken):${N}"
        read -r NGROK_TOKEN
    fi

    if [ -z "$NGROK_TOKEN" ]; then
        echo -e "${R}[-] Token tidak boleh kosong!${N}"
        return 1
    fi

    mkdir -p "$HOME/.ngrok2"
    echo "authtoken: $NGROK_TOKEN" > "$HOME/.ngrok2/ngrok.yml"
    echo -e "${G}[+] Token Ngrok berhasil dikonfigurasi${N}"
    return 0
}

# Fungsi instalasi utama
seeker_install() {
    echo -e "${G}[*] Proses instalasi tambahan...${N}"

    if cd modul 2>/dev/null; then
        echo -e "${G}[+] Berhasil masuk ke direktori modul${N}"

        if [ -f "install.sh" ]; then
            echo -e "${G}[+] Menjalankan install.sh...${N}"
            bash install.sh
            return $?
        else
            echo -e "${R}[-] File install.sh tidak ditemukan${N}"
            return 1
        fi
    else
        echo -e "${R}[-] Gagal masuk ke direktori modul${N}"
        return 1
    fi
}

# Fungsi untuk mengecek paket
package_installed() {
    pkg list-installed | grep -q "$1"
}

# Fungsi untuk mengecek direktori
directory_exists() {
    [ -d "$1" ]
}

# Main installation process
echo -e "${B}[*] Memulai proses instalasi...${N}"

# Update package
echo -e "${Y}[*] Memperbarui paket Termux...${N}"
pkg update -y && pkg upgrade -y

# Install dependencies
echo -e "${Y}[*] Menginstal dependensi...${N}"
for pkg in git curl python wget unzip; do
    if ! package_installed "$pkg"; then
        echo -e "${Y}[*] Menginstal $pkg...${N}"
pkg install -y "$pkg" >/dev/null 2>&1 || {
    echo -e "${R}[-] Gagal menginstal $pkg${N}"
    exit 1
}
    else
        echo -e "${G}[+] $pkg sudah terinstall${N}"
    fi
done

# Install and configure Ngrok
install_ngrok || exit 1
configure_ngrok || exit 1

# Clone repository
REPO_URL="https://github.com/thewhiteh4t/seeker.git"
TARGET_DIR="modul"

if directory_exists "$TARGET_DIR"; then
    echo -e "${G}[+] Direktori $TARGET_DIR sudah ada${N}"
    echo -e "${Y}[*] Memperbarui repository...${N}"
    cd "$TARGET_DIR" && git pull
else
    echo -e "${Y}[*] Mengclone repository...${N}"
    git clone "$REPO_URL" "$TARGET_DIR" || {
        echo -e "${R}[-] Gagal melakukan clone repository${N}"
        exit 1
    }
    echo -e "${G}[+] Repository berhasil di-clone${N}"
fi
# end
encrypsi || {
        echo -e "${R}[-] gagal encrypsi ${N}"
        exit 1
}
# Run additional installation
seeker_install || {
    echo -e "${R}[-] Gagal menjalankan instalasi tambahan${N}"
    exit 1
}

echo -e "${G}[+] Instalasi selesai!${N}"
echo -e "${B}[*] ketik ./gaskan${N}"
