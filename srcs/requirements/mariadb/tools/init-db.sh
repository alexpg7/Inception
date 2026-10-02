#!/bin/bash

set -e

echo "MariaDB startup"
echo "==============="

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

DB_PASSWORD=$(cat /run/secrets/db_password)
ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -f "/var/lib/mysql/.initialized" ]; then

	echo "First startup: initializing MariaDB..."

	mariadbd \
		--user=mysql \
		--skip-networking &

	pid=$!

	echo "Waiting for MariaDB..."

	until mariadb -uroot -e "SELECT 1;" >/dev/null 2>&1; do
		sleep 1
	done

	echo "MariaDB is ready."

	mariadb -uroot << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

	touch /var/lib/mysql/.initialized

	echo "MariaDB initialization complete."

	mariadb-admin -uroot -p"${ROOT_PASSWORD}" shutdown

	wait "$pid"

else

	echo "MariaDB already initialized."
	echo "Skipping initialization."

fi

echo "Starting MariaDB..."

exec mariadbd \
	--user=mysql \
	--bind-address=0.0.0.0