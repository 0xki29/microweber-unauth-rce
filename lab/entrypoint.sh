#!/bin/bash
set -e

cd /var/www/html

# Auto-install on first boot (SQLite, no external DB needed)
if [ ! -f "config/.env" ] && [ ! -f ".env" ]; then
    echo "[*] First boot — running Microweber installer..."

    DB_ENGINE=sqlite \
    DB_NAME=storage/database.sqlite \
    DB_PREFIX=mw_ \
    php artisan microweber:install \
        --db-driver=sqlite \
        --db-name=storage/database.sqlite \
        --db-prefix=mw_ \
        --email=admin@lab.local \
        --username=admin \
        --password=Admin1234! \
        --default-content=1 \
        --template=liteness \
        2>&1

    echo "[+] Install complete."
    echo "[+] Admin: admin@lab.local / Admin1234!"
fi

chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/userfiles

echo "[*] Starting Apache..."
exec apache2-foreground
