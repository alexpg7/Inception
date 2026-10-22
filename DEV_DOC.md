# Developer Documentation

## 1. Overview

This project deploys a WordPress website using Docker Compose.

The infrastructure contains three services:

| Service | Responsibility | Internal port | Published host port |
|---|---|---:|---:|
| NGINX | HTTPS entry point and reverse proxy | 443 | 443 |
| WordPress | WordPress application running with PHP-FPM | 9000 | None |
| MariaDB | Database server | 3306 | None |

Each service has its own Dockerfile based on Debian 12. Docker Compose builds and manages the service containers, the network, the persistent volumes, and the secrets.

NGINX is the only service exposed directly to the host.

## 2. Prerequisites

Prepare a virtual machine that satisfies the 42 Inception subject requirements.

The development environment requires:

- A compatible Linux environment.
- Docker Engine.
- Docker Compose v2, available through `docker compose`.
- GNU Make.
- Git.
- Internet access during the initial image build to download base images and required packages.

The user running the project must have permission to execute Docker commands. The current Makefile invokes Docker Compose through `sudo`.

## 3. Project Structure

The repository is organized as follows:

```text
.
├── DEV_DOC.md
├── Inception.pdf
├── Makefile
├── README.md
├── USER_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── setup.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup.sh
```

### Important files

- `Makefile`: defines project management commands.
- `srcs/docker-compose.yml`: describes the infrastructure and how the services interact.
- `srcs/.env`: contains environment-specific configuration.
- `srcs/.env.example`: template for creating the local environment file.
- `requirements/*/Dockerfile`: defines how each service image is built.
- `requirements/*/tools/`: contains initialization and startup scripts.
- `requirements/*/conf/`: contains service-specific configuration files.
- `secrets/`: contains local credential files consumed by the services.

The actual `.env` file and secret files must remain out of version control.

## 4. Environment Configuration

### Create the environment file

From the repository root:

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` and provide the values required by the Compose configuration.

The current installation uses values such as:

```dotenv
DOMAIN_NAME=alpascua.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=alpascua
```

These values must agree with the service configuration and initialization scripts.

The `.env` file is read by Docker Compose for variable substitution when applicable. In this project, the Compose configuration also uses `env_file` to pass the listed variables into the relevant containers.

Do not put actual passwords in the example file. Use the dedicated secret files for credentials.

## 5. Configure Secrets

Create the following files in the repository's root `secrets/` directory:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

### `credentials.txt`

The WordPress initialization script expects one key-value pair per line:

```text
WP_ADMIN_USER=<wordpress_admin_username>
WP_ADMIN_PASSWORD=<strong_admin_password>
WP_ADMIN_EMAIL=<admin_email>
WP_USER=<second_username>
WP_USER_PASSWORD=<strong_user_password>
WP_USER_EMAIL=<user_email>
```

Replace the placeholders with valid values.

The administrator username must not contain `admin` or `administrator`, in accordance with the subject requirements.

The second account is created with the `subscriber` role by the current initialization script.

### Database password files

- `db_password.txt`: password for the WordPress database user.
- `db_root_password.txt`: MariaDB root password.

The MariaDB and WordPress containers receive the relevant secrets through the `secrets` sections in `srcs/docker-compose.yml`.

### Protect the files

For files owned by the current user, restrict access:

```bash
chmod 600 secrets/credentials.txt
chmod 600 secrets/db_password.txt
chmod 600 secrets/db_root_password.txt
```

The files must remain readable by the user or privileged process that runs Docker Compose.

File-backed Compose secrets are mounted into the relevant containers as files, typically under `/run/secrets/`. They do not automatically provide an encrypted secrets-management system for the host files.

### Important behavior when changing credentials

The initialization scripts use the supplied values when setting up a new database or installing WordPress.

Changing a secret file after initialization does not automatically update an existing MariaDB password or an existing WordPress account password. Update the actual account or database credential using the appropriate administrative procedure, and ensure the application configuration remains consistent.

## 6. Configure Persistent Storage

The Compose file defines two named volumes using the local driver with bind options.

The current host paths are:

```text
/home/alexp/data/mariadb
/home/alexp/data/wordpress
```

Create the directories before launching the services:

```bash
sudo mkdir -p /home/alexp/data/mariadb
sudo mkdir -p /home/alexp/data/wordpress
```

If the project is moved to a different machine or user account, update the `device` values in the volume definitions in `srcs/docker-compose.yml`.

For example, the volume definitions follow this pattern:

```yaml
volumes:
  mariadb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/alexp/data/mariadb

  wordpress-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/alexp/data/wordpress
```

The directories must have suitable permissions for MariaDB and WordPress to write their data. Do not assume that the correct permissions are the same on every host.

The WordPress volume is mounted into both the WordPress and NGINX containers. WordPress manages the application files, while NGINX reads them to serve the website.

## 7. Configure Local Domain Resolution

The NGINX configuration uses the domain:

```text
alpascua.42.fr
```

For testing from inside the virtual machine, add the following entry to `/etc/hosts` if it is not already present:

```text
127.0.0.1 alpascua.42.fr
```

If access is required from the host machine, configure the domain to resolve to the VM's reachable IP address and ensure that the VM's network allows access to port 443.

The local DNS or hosts configuration must match the domain used by the NGINX configuration and WordPress installation URL.

## 8. Build and Launch

Run the following commands from the repository root.

### Validate the Compose configuration

```bash
make validate
```

The target runs `docker compose config -q`. Quiet mode suppresses normal output when the configuration is valid; errors are printed if validation fails.

### Build and start all services

```bash
make
```

This is equivalent to running the default `up` target.

You can also run:

```bash
make up
```

The target builds the images and starts the containers in detached mode.

### Build images only

```bash
make build
```

### Inspect the resolved Compose configuration

```bash
make config
```

Be careful when sharing this output: resolved configuration can include sensitive values if they have been interpolated into the Compose configuration.

### Check service status

```bash
make ps
```

### Follow logs

```bash
make logs
```

The logs target follows the most recent 100 lines from the Compose services.

## 9. Makefile Commands

The current Makefile provides the following targets:

| Command | Purpose |
|---|---|
| `make` | Build and start the project. |
| `make up` | Build and start the services. |
| `make run` | Alias for `make up`. |
| `make build` | Build the images. |
| `make start` | Start existing containers. |
| `make stop` | Stop running containers. |
| `make down` | Remove containers and networks. |
| `make down-v` | Remove containers, networks, and named Docker volume objects. |
| `make restart` | Restart the containers. |
| `make re` | Stop the current stack and rebuild/recreate it. |
| `make ps` | Display container status. |
| `make logs` | Follow service logs. |
| `make config` | Print the resolved Compose configuration. |
| `make validate` | Validate the Compose configuration quietly. |
| `make clean` | Alias for `make down`. |
| `make fclean` | Remove containers, networks, named volume objects, and service images. |
| `make help` | Display the available targets. |

### Important cleanup distinction

The named volumes use host directories as their underlying storage. Removing the Docker volume objects does not necessarily delete the contents of those host directories.

Consequently, `make down-v` and `make fclean` do not guarantee a completely fresh installation if the existing host data remains.

To reset the project, first back up any data that must be retained. Then stop the stack and deliberately remove or replace the relevant data directories if a full reset is intended.

Do not delete the persistent directories as part of routine troubleshooting.

## 10. Docker Compose Operations

The equivalent direct Docker Compose commands can be run from the repository root.

### Start the stack

```bash
sudo docker compose -f srcs/docker-compose.yml up -d --build
```

### Stop and remove the stack

```bash
sudo docker compose -f srcs/docker-compose.yml down --remove-orphans
```

### List containers

```bash
sudo docker compose -f srcs/docker-compose.yml ps -a
```

### View logs

```bash
sudo docker compose -f srcs/docker-compose.yml logs -f --tail=100
```

### Rebuild a single service

For example, to rebuild WordPress:

```bash
sudo docker compose -f srcs/docker-compose.yml build wordpress
```

Then recreate the service if required:

```bash
sudo docker compose -f srcs/docker-compose.yml up -d wordpress
```

The same approach applies to `nginx` and `mariadb`.

### Inspect a container

```bash
sudo docker inspect nginx
sudo docker inspect wordpress
sudo docker inspect mariadb
```

### Execute a command inside a running container

For example:

```bash
sudo docker exec -it wordpress bash
```

Use the appropriate service name for the container you need to inspect.

## 11. Service Configuration

### NGINX

Configuration:

```text
srcs/requirements/nginx/conf/nginx.conf
```

Startup script:

```text
srcs/requirements/nginx/tools/setup.sh
```

NGINX listens on port 443 and enables TLS 1.2 and TLS 1.3. It serves the WordPress files and forwards PHP requests to `wordpress:9000`.

The startup script generates a self-signed certificate if necessary, validates the NGINX configuration, and starts NGINX in the foreground.

### WordPress

PHP-FPM configuration:

```text
srcs/requirements/wordpress/conf/www.conf
```

Startup script:

```text
srcs/requirements/wordpress/tools/setup.sh
```

WordPress runs through PHP-FPM, listening on port 9000 within the Docker network.

The startup script reads configuration and secrets, initializes the persistent website directory when needed, waits for MariaDB, installs WordPress if it has not already been installed, and starts PHP-FPM.

### MariaDB

Initialization script:

```text
srcs/requirements/mariadb/tools/init-db.sh
```

The script initializes the database directory when necessary, creates the WordPress database and application user, configures the root password, and starts MariaDB normally.

The database is stored in the persistent MariaDB volume. On subsequent starts, the initialization marker and existing database files prevent the initial setup from being repeated.

## 12. Networking and Service Dependencies

The services use a dedicated Docker network named `inception`.

Internal communication uses Compose service names rather than fixed container IP addresses:

- NGINX reaches WordPress at `wordpress:9000`.
- WordPress reaches MariaDB using the hostname `mariadb`.

Only NGINX publishes port 443 to the host. WordPress and MariaDB do not publish their internal ports.

The Compose configuration declares dependencies to establish startup ordering. However, service startup order alone does not guarantee that an application is ready to accept connections. The WordPress startup script therefore includes a database readiness check.

The services also use restart policies to allow Docker to restart containers under the configured conditions.

## 13. Data Persistence

The project keeps persistent data outside the container filesystems.

| Data | Host directory | Container directory |
|---|---|---|
| MariaDB database | `/home/alexp/data/mariadb` | `/var/lib/mysql` |
| WordPress website files | `/home/alexp/data/wordpress` | `/var/www/html` |

These paths reflect the current development configuration. Update them when moving the project to another environment.

### Why persistence matters

Containers can be replaced when images are rebuilt or services are recreated. Persistent volumes allow the database and website files to survive those operations.

For example:

```bash
make down
make up
```

This removes and recreates the containers while leaving the host data directories intact.

The services can then reuse the existing database and WordPress installation.

### Backup recommendations

Before making changes to the volume configuration or resetting the installation:

1. Stop or quiesce the relevant services as appropriate for the backup method.
2. Back up the database using a database-aware backup procedure.
3. Back up the WordPress files.
4. Store backups separately from the active data directories.
5. Test that the backups can be restored.

A copy of the raw database directory should not be assumed to be a valid, consistent backup if MariaDB was writing to it during the copy.

## 14. Troubleshooting

### Compose configuration fails validation

Run:

```bash
make validate
```

Then inspect the complete configuration:

```bash
make config
```

Check YAML indentation, variable names, file paths, and secret declarations.

### A container exits during startup

Inspect the status and logs:

```bash
make ps
make logs
```

For service-specific logs:

```bash
sudo docker logs nginx
sudo docker logs wordpress
sudo docker logs mariadb
```

### NGINX cannot connect to WordPress

Check that both containers are running and connected to the same Docker network. Verify the PHP-FPM listener and the `fastcgi_pass wordpress:9000` configuration.

### WordPress cannot connect to MariaDB

Check that MariaDB started successfully, that the database and user exist, and that the WordPress database configuration matches the credentials stored in the secret files.

Changing a secret file alone does not update an existing database account password.

### The website cannot be reached

Verify that:

- NGINX is running.
- Port 443 is published.
- The domain resolves to the correct machine.
- The NGINX configuration passes its syntax check.
- The virtual machine's network allows access to the published port.

A self-signed certificate warning is expected in the current local development setup.

### The website or database appears to have reset

Check the volume mappings and the contents of the host directories before performing any destructive action.

If the Compose file points to a different host directory, Docker may be mounting a new, empty data location. Restore the original paths if appropriate, and never delete data directories until you have confirmed which installation they contain.

## 15. Security Notes

- Never commit `.env` or actual secret files.
- Protect the host directories containing credentials and persistent data.
- Do not expose the MariaDB or PHP-FPM ports unnecessarily.
- Avoid including passwords in shell history, logs, or shared diagnostic output.
- Remember that the project's self-signed certificate is intended for local development.
- Review the security implications of any configuration changes before using the infrastructure outside the required development environment.

## 16. Related Documentation

- `README.md`: project description, architecture, design choices, and references.
- `USER_DOC.md`: instructions for using the website and administration panel.
- `Inception.pdf`: the original project subject.