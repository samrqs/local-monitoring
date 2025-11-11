#!/bin/sh
set -e

echo "Entrypoint: aguardando banco e aplicando migrations..."

until python manage.py migrate --noinput; do
  echo "Banco não pronto ou migrate falhou — tentarei novamente em 5s..."
  sleep 5
done

echo "Migrations aplicadas. Iniciando comando principal..."

exec "$@"
