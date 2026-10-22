*This project has been created as part of the 42 curriculum by alpascua.*

# 🎡 Inception ![Static Badge](https://img.shields.io/badge/Barcelona-black?style=for-the-badge&logo=42&logoColor=%23FFFFFF)
![Static Badge](https://img.shields.io/badge/Docker-white?style=flat&logo=docker)
![Static Badge](https://img.shields.io/badge/Shell-grey?style=flat&logo=GNUbash)
![Static Badge](https://img.shields.io/badge/Makefile-green?style=flat&logo=AnkerMake)
![Static Badge](https://img.shields.io/badge/status-completed-green?style=flat)

## Table of Contents

- [Description](#description)
- [Project Architecture](#project-architecture)
- [Main Design Choices](#main-design-choices)
- [Instructions](#instructions)
- [Services](#services)
- [Data Persistence](#data-persistence)
- [Security Considerations](#security-considerations)
- [Documentation](#documentation)
- [Resources](#resources)
- [Use of Artificial Intelligence](#use-of-artificial-intelligence)

## Description

**Inception** is a system administration project from the 42 curriculum. Its goal is to introduce Docker, containerization, service orchestration, networking, persistent storage, and basic infrastructure security.

The project runs inside a virtual machine and uses Docker Compose to orchestrate a small infrastructure composed of three services:

- **NGINX:** acts as the entry point and reverse proxy, serving the website over HTTPS.
- **WordPress:** runs the content management system using PHP-FPM.
- **MariaDB:** stores the WordPress database.

Each service is built from its own Dockerfile, based on Debian 12. The containers communicate through a dedicated Docker network, and persistent storage is provided for the database and website files.

The infrastructure is configured to be reproducible: the images can be rebuilt, the services can be restarted, and persistent data is stored outside the containers.

The website is available locally at:

**https://alpascua.42.fr**

The TLS certificate is self-signed, so a browser may display a security warning. This is expected in this local development environment.

## Project Architecture

### Overview

The infrastructure follows a three-tier architecture:

```text
                         Host machine
                              |
                     Virtual Machine
                              |
                         Docker Engine
                              |
                      Docker Compose
                              |
                  Dedicated Docker network
                              |
                +-------------+-------------+
                |             |             |
              NGINX        WordPress      MariaDB
             :443           :9000          :3306
                |             |             |
                |         PHP-FPM            |
                |             |             |
                +---------- Database --------+
                              |
                       Persistent storage
```

The diagram illustrates the logical architecture. In practice, NGINX receives external HTTPS requests and forwards PHP requests to WordPress. WordPress communicates with MariaDB over the internal Docker network.

Only port **443** is published on the host. The WordPress and MariaDB ports are not exposed directly to the host.

### Project structure

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

The local `.env` file and the files in `secrets/` contain configuration and credentials. They must not be committed to version control.

### Sources included in the project

- **`srcs/docker-compose.yml`** defines the services, builds, networks, volumes, port mappings, restart policies, and secrets.
- **`srcs/requirements/mariadb/`** contains the MariaDB image definition and database initialization script.
- **`srcs/requirements/nginx/`** contains the NGINX image definition, HTTPS configuration, and startup script.
- **`srcs/requirements/wordpress/`** contains the WordPress image definition, PHP-FPM configuration, and WordPress installation script.
- **`secrets/`** contains the credentials supplied to the containers at runtime.
- **`Makefile`** provides convenient commands for building, starting, stopping, and managing the infrastructure.
- **`USER_DOC.md`** explains how to use and access the deployed website.
- **`DEV_DOC.md`** documents the development environment and technical operations.
- **`Inception.pdf`** contains the project subject.

## Main Design Choices

### 1. Virtual Machines vs Docker

A virtual machine and a Docker container provide different levels of isolation and serve different purposes.

| Aspect | Virtual Machine | Docker container |
|---|---|---|
| Virtualization | Virtualizes hardware and runs a guest operating system. | Isolates processes while sharing the host kernel. |
| Operating system | Normally has its own kernel and operating system. | Uses the host kernel. |
| Resource usage | Generally requires more memory and storage. | Usually lighter and faster to start. |
| Startup | Starts an entire guest operating system. | Starts the processes required by a service. |
| Isolation | Provides isolation at the virtual hardware level. | Provides process and resource isolation through operating-system features. |
| Typical use in this project | Provides the environment in which the infrastructure runs. | Runs NGINX, WordPress, and MariaDB independently. |

**Why both are used here**

The project runs inside a virtual machine as required by the subject. Docker is then used inside that VM to package and run each application service independently.

This approach combines the isolation of a virtual machine with the lightweight deployment and reproducibility of containers.

### 2. Secrets vs Environment Variables

Environment variables and secrets are both used to configure applications, but they are not equally appropriate for every type of information.

| Aspect | Environment variables | Docker secrets |
|---|---|---|
| Purpose | Configure application behavior and non-sensitive settings. | Supply sensitive information such as passwords. |
| Examples in this project | Domain name, database name, database username. | Database passwords and WordPress account credentials. |
| Access | Available to the process environment and potentially visible through container inspection or diagnostic tools. | Mounted as files, which applications read when needed. |
| Storage | Often supplied through an environment file or Compose configuration. | Supplied to services through Docker's secrets mechanism. |
| Security considerations | Values should not be used as a secure storage mechanism for credentials. | Reduce the need to place credentials directly in environment variables, but still require appropriate host-file permissions and access controls. |

This project uses `srcs/.env` for non-sensitive configuration and files under `secrets/` for passwords and WordPress account credentials.

The `.env.example` file provides a template for the required environment variables without containing actual credentials.

**Important:** In this project, secrets are provided through Docker Compose using local files. This is suitable for the development environment, but local Compose file-backed secrets are not equivalent to an encrypted, centrally managed secrets service. The original files still require appropriate permissions and protection.

### 3. Docker Network vs Host Network

Docker networking determines how containers communicate with one another and with the outside world.

| Aspect | Docker bridge network | Host network |
|---|---|---|
| Network namespace | Containers have their own network namespace. | The container shares the host's network namespace. |
| Container communication | Containers on the same network can communicate using service names. | Services use the host's network stack directly. |
| Port publishing | Ports can be explicitly published to the host. | Port publishing is generally unnecessary and does not work in the same way. |
| Isolation | Provides network separation from the host and unrelated networks. | Provides less network isolation from the host. |
| Use in this project | Used by all three services. | Not used. |

The project defines a dedicated network named `inception`.

The services communicate using their Compose service names:

- NGINX forwards PHP requests to `wordpress:9000`.
- WordPress connects to MariaDB using the hostname `mariadb`.

Only NGINX publishes a port to the host:

```yaml
ports:
  - "443:443"
```

This keeps WordPress and MariaDB accessible to the other containers without exposing their service ports directly to the host.

The project does not use host networking or legacy Docker links.

### 4. Docker Volumes vs Bind Mounts

Containers have writable filesystems, but data stored only in a container can be lost when that container is removed or replaced. Persistent storage separates important data from the container lifecycle.

| Aspect | Docker volume | Bind mount |
|---|---|---|
| Storage location | Managed through Docker's volume system. | A specific path on the host filesystem. |
| Configuration | Declared and referenced as a Docker volume. | Maps a host path directly into a container. |
| Portability | Docker manages the storage location, although data and configuration still affect portability. | Depends on the host path existing and having appropriate permissions. |
| Common use | Persistent application and database data. | Sharing host files or directories with containers. |
| Lifecycle | The volume can outlive a container. | The host directory exists independently of the container. |

This project declares two named Docker volumes:

- **`mariadb-data`** stores the MariaDB database files.
- **`wordpress-data`** stores the WordPress website files.

For the current development environment, these named volumes use the local volume driver with bind options. Their data is stored in the following host directories:

```text
/home/alexp/data/mariadb
/home/alexp/data/wordpress
```

These paths must be adapted if the project is installed under a different user account or on another machine.

This design combines Docker volume declarations with explicitly chosen host storage locations. The named volumes are managed by Docker, while the underlying files remain in the configured host directories.

The WordPress volume is shared by the WordPress and NGINX containers: WordPress manages the website files, while NGINX reads them to serve the site.

**Data safety:** Removing containers does not remove the data in these host directories. Removing a Docker volume object also does not automatically erase the files in a bind-backed host directory. To reset the installation completely, the host data must be handled separately and deliberately.

## Instructions

### Prerequisites

Before running the project, ensure that the virtual machine has:

- Docker Engine installed and running.
- Docker Compose v2 available through `docker compose`.
- GNU Make.
- Git.
- Internet access for downloading the base images and required packages during the initial build.

The project is intended to run inside a virtual machine. Follow the 42 subject's requirements for the VM environment.

### 1. Clone the repository

Clone the repository and enter its root directory:

```bash
git clone <repository-url>
cd Inception
```

The root directory should contain the `Makefile` and the `srcs/` directory.

### 2. Configure environment variables

Create the local environment file from the example:

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` and configure the required values. For example:

```dotenv
DOMAIN_NAME=alpascua.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=alpascua
```

Use the actual values expected by the Compose configuration. Keep this file out of version control if it contains local or private configuration.

### 3. Configure secrets

Create the required secret files in the root `secrets/` directory:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

The files must contain the credentials expected by the initialization scripts.

The `credentials.txt` file uses one `KEY=VALUE` entry per line:

```text
WP_ADMIN_USER=<wordpress_admin_username>
WP_ADMIN_PASSWORD=<strong_admin_password>
WP_ADMIN_EMAIL=<admin_email>
WP_USER=<second_username>
WP_USER_PASSWORD=<strong_user_password>
WP_USER_EMAIL=<user_email>
```

Replace every placeholder with a real value. The administrator username must not contain `admin` or `administrator`, as required by the project subject.

The `db_password.txt` file contains the password for the WordPress database user. The `db_root_password.txt` file contains the MariaDB root password.

Protect the secret files so that only the appropriate local user and privileged processes can read them. For example, if the files belong to the current user:

```bash
chmod 600 secrets/credentials.txt
chmod 600 secrets/db_password.txt
chmod 600 secrets/db_root_password.txt
```

Do not paste actual passwords into the README or commit the secret files to Git.

### 4. Create the persistent storage directories

The Compose configuration uses these host directories:

```text
/home/alexp/data/mariadb
/home/alexp/data/wordpress
```

Create them before starting the infrastructure:

```bash
sudo mkdir -p /home/alexp/data/mariadb
sudo mkdir -p /home/alexp/data/wordpress
```

If the project is being installed under a different account, update the volume device paths in `srcs/docker-compose.yml` first.

The directories must have permissions that allow the container processes to write their data. Avoid changing permissions indiscriminately; use the permissions required by the services.

### 5. Configure local domain resolution

The website uses the domain:

```text
alpascua.42.fr
```

For local testing, configure the VM's `/etc/hosts` file so that the domain resolves to the VM's local address.

If the browser or `curl` command runs inside the same VM, add:

```text
127.0.0.1 alpascua.42.fr
```

If the browser runs on the host machine instead, the domain must resolve to the VM's reachable IP address, and the VM's network configuration must allow access to port 443.

### 6. Build and start the infrastructure

From the repository root, run:

```bash
make
```

The default Makefile target builds the service images and starts the containers in detached mode.

Alternatively, run:

```bash
make up
```

To validate the resolved Compose configuration without starting the services (if it does not print anything, it means taht is valid):

```bash
make validate
```

To inspect the service status:

```bash
make ps
```

### 7. Access the website

Open the following address:

```text
https://alpascua.42.fr
```

The NGINX service terminates the HTTPS connection and forwards PHP requests to WordPress.

Because the project generates a self-signed TLS certificate for local development, the browser may warn that the certificate is not trusted. This is expected unless the certificate is explicitly trusted by the client.

To test the HTTP response from inside the VM:

```bash
curl -k -I https://alpascua.42.fr
```

The `-k` option tells `curl` to accept the self-signed certificate for this test. It should not be treated as a general security recommendation for production connections.

### 8. Manage the infrastructure

The Makefile provides the following commands:

| Command | Description |
|---|---|
| `make` | Build and start all services. |
| `make up` | Build and start all services. |
| `make build` | Build the images without starting the services. |
| `make start` | Start existing containers. |
| `make stop` | Stop running containers. |
| `make down` | Remove containers and the Compose network. |
| `make down-v` | Remove containers, networks, and named volume objects. |
| `make restart` | Restart the services. |
| `make re` | Recreate the infrastructure after stopping the current containers. |
| `make ps` | Display container status. |
| `make logs` | Follow service logs. |
| `make config` | Display the resolved Compose configuration. |
| `make validate` | Validate the Compose configuration. |
| `make clean` | Stop and remove the containers and network. |
| `make fclean` | Remove containers, networks, named volumes, and service images. |
| `make help` | Display available targets. |

**Warning:** `make down-v` and `make fclean` remove Docker volume objects, but the underlying data in the configured bind-backed host directories may remain. Do not delete or overwrite those directories unless you intentionally want to reset the persistent data.

## Services

### NGINX

NGINX is the only service exposed to the host. It serves the website over HTTPS and forwards PHP requests to the WordPress PHP-FPM service.

Its configuration is located at:

```text
srcs/requirements/nginx/conf/nginx.conf
```

The configuration:

- Listens on port 443 using TLS.
- Allows TLS 1.2 and TLS 1.3.
- Serves static files from the shared WordPress directory.
- Forwards PHP requests to `wordpress:9000`.
- Denies access to hidden files.
- Routes WordPress requests through `index.php` when necessary.

The startup script generates a self-signed certificate if one does not already exist, checks the NGINX configuration, and starts NGINX in the foreground.

### WordPress

WordPress runs on Debian 12 with PHP-FPM. It does not run its own NGINX server.

The image installs PHP and the required extensions, downloads WordPress and WP-CLI, and includes a PHP-FPM pool configuration.

At container startup, the WordPress script:

1. Reads the required environment variables and secrets.
2. Copies the WordPress distribution into the persistent website directory when it has not already been initialized.
3. Waits for MariaDB to become available.
4. Creates the WordPress configuration and installs WordPress if it is not already installed.
5. Creates the administrator account and a second, non-administrator user during the initial installation.
6. Starts PHP-FPM in the foreground.

The WordPress files are stored in the `wordpress-data` volume so that they persist across container replacement.

### MariaDB

MariaDB stores the WordPress database.

Its image installs the database server and includes an initialization script that:

1. Initializes the database directory when necessary.
2. Starts a temporary MariaDB process for initial configuration.
3. Creates the WordPress database and application user.
4. Configures the database root password.
5. Stops the temporary process and starts MariaDB normally.

Initialization is performed only when the persistent database has not already been initialized. Subsequent container starts reuse the existing database rather than recreating it.

The database files are stored in the `mariadb-data` volume.

### Restart policies and service communication

The services use Docker Compose restart policies so that Docker can restart containers after failures or daemon restarts, subject to the selected policy.

The services share the dedicated `inception` network. They use service names for internal communication instead of hard-coded container IP addresses.

The Compose configuration also specifies service dependencies. These dependencies determine startup ordering, while the application startup scripts handle readiness checks where required.

## Data Persistence

Persistent storage is essential because a container can be replaced during a rebuild or redeployment.

This project separates service images from important application data:

- MariaDB stores database files in `mariadb-data`.
- WordPress stores website files in `wordpress-data`.
- NGINX reads the shared WordPress files but does not own the database or perform WordPress installation.

This allows the containers to be removed and recreated without intentionally removing the data stored in the host directories.

For example, the following commands stop and remove the containers, then recreate the services:

```bash
make down
make up
```

As long as the persistent directories remain intact and the volume paths are unchanged, the services can reuse the existing data.

A container restart or successful HTTP response alone does not replace a proper backup strategy. Important data should be backed up and restoration should be tested.

## Security Considerations

Several choices in this project reduce unnecessary exposure:

- Only NGINX publishes a host port.
- NGINX accepts TLS 1.2 and TLS 1.3.
- WordPress and MariaDB communicate over an internal Docker network.
- Database passwords and WordPress credentials are supplied through Compose secrets.
- Sensitive local configuration and credentials should be excluded from version control.
- Service images are built from Dockerfiles based on Debian 12 rather than relying on prebuilt application images.
- Versioned service image tags are used instead of the `latest` tag.

There are also limitations to keep in mind:

- The TLS certificate is self-signed and is intended for local testing.
- File-backed Compose secrets depend on the security of the host files and the Docker environment.
- The configured host storage directories must be protected against unauthorized access.
- A production deployment would require additional hardening, certificate management, backups, monitoring, and a more comprehensive secrets-management strategy.

## Documentation

Two additional documents accompany this project:

- **`USER_DOC.md`** — explains how to access and use the website, including the relevant user-facing details.
- **`DEV_DOC.md`** — provides technical information for developers, including the environment, service configuration, and maintenance procedures.

These documents complement this README: the README introduces the architecture and explains how to start the project, while the other documents focus on usage and development.

## Resources

The following resources were used as references for understanding and implementing the infrastructure.

### Docker and Docker Compose

- [Docker documentation](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)

### NGINX and TLS

- [NGINX documentation](https://nginx.org/en/docs/)
- [NGINX beginner's guide](https://nginx.org/en/docs/beginners_guide.html)
- [OpenSSL documentation](https://docs.openssl.org/)

### WordPress and PHP

- [WordPress documentation](https://wordpress.org/documentation/)
- [WordPress installation guide](https://developer.wordpress.org/advanced-administration/before-install/howto-install/)
- [WP-CLI documentation](https://make.wordpress.org/cli/handbook/)
- [PHP documentation](https://www.php.net/docs.php)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

### MariaDB and Debian

- [MariaDB documentation](https://mariadb.com/docs/)
- [Debian documentation](https://www.debian.org/doc/)

### Use of Artificial Intelligence

Artificial intelligence tools, including ChatGPT, were used as supplementary learning and development aids during this project.

AI assistance was used for the following tasks:

- **Conceptual explanations:** understanding Docker images and containers, Docker Compose, networking, volumes, bind mounts, environment variables, and secrets.
- **Configuration support:** discussing Dockerfile structure, Compose service definitions, NGINX and PHP-FPM configuration, and service communication.
- **Initialization scripts:** reviewing approaches to database initialization, WordPress installation, readiness checks, and persistent data handling.
- **Troubleshooting:** interpreting build output, container logs, TLS test results, and service connectivity issues.
- **Documentation:** organizing the README and preparing explanations of architectural decisions and operational commands.

AI-generated suggestions were reviewed and adapted to the project. Commands and configurations were tested in the development environment where applicable. AI was used as a support tool for learning, debugging, and documentation, rather than as a substitute for understanding the infrastructure.

The final implementation and its behavior should be verified by the project author against the 42 subject and the actual execution environment.
