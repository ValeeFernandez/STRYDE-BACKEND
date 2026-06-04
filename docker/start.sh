#!/bin/sh
set -e

echo ">>> Generando .env..."
cat > /var/www/html/.env <<EOF
APP_NAME="${APP_NAME:-STRYDE}"
APP_ENV=production
APP_KEY="${APP_KEY:-}"
APP_DEBUG=false
APP_URL="${APP_URL:-http://localhost}"

LOG_CHANNEL=stderr
LOG_LEVEL=error

DB_CONNECTION=sqlite
DB_DATABASE="${DB_DATABASE:-/var/data/database.sqlite}"

SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
EOF

echo ">>> Preparando base de datos SQLite..."
DB_PATH="${DB_DATABASE:-/var/data/database.sqlite}"
mkdir -p "$(dirname $DB_PATH)"
touch "$DB_PATH"
chown www-data:www-data "$DB_PATH"
chmod 664 "$DB_PATH"

echo ">>> Generando APP_KEY..."
php artisan key:generate --force

echo ">>> Corriendo migraciones..."
php artisan migrate --force

echo ">>> Corriendo seeders si la BD está vacía..."
COUNT=$(php artisan tinker --execute="echo App\Models\Zapato::count();" 2>/dev/null | tail -1 || echo "0")
if [ "$COUNT" = "0" ]; then
  echo ">>> Corriendo seeders..."
  php artisan db:seed --force
fi

echo ">>> Optimizando Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link

echo ">>> Iniciando servicios..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf