# User Documentation

## 1. Introduction

This project provides a WordPress website running inside a Docker-based infrastructure.

The stack consists of three services:

- **NGINX:** provides secure HTTPS access to the website.
- **WordPress:** runs the website and provides its administration interface.
- **MariaDB:** stores the website's database, including posts, pages, users, and other WordPress data.

The services communicate over a dedicated Docker network. Only NGINX is exposed to the host machine.

## 2. Accessing the Website

The website is available at:

**https://alpascua.42.fr**

For local access, the domain must resolve to the machine running the project. If you are accessing the website from the same virtual machine, the following entry can be added to `/etc/hosts`:

```text
127.0.0.1 alpascua.42.fr
```

If you are accessing it from another machine, the domain must resolve to the virtual machine's reachable IP address instead.

### HTTPS certificate warning

The project generates a self-signed TLS certificate for local development.

Your browser may therefore display a warning that the connection is not trusted. This is expected in the development environment.

Do not assume that a self-signed certificate provides the same identity verification as a certificate issued by a trusted certificate authority.

## 3. Accessing WordPress Administration

The WordPress administration panel is available at:

**https://alpascua.42.fr/wp-admin**

Log in using the WordPress administrator username and password configured during the initial installation.

From the administration panel, an administrator can manage:

- Website pages and posts.
- WordPress users and their roles.
- Themes and website appearance.
- Plugins and website functionality.
- General WordPress settings.

A regular WordPress user can access the features allowed by their assigned role. They do not automatically have administrator privileges.

If the login page does not load, first verify that all three services are running and that the domain resolves correctly.

## 4. Managing Credentials

Credentials are stored locally in the project's `secrets/` directory.

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

### WordPress credentials

The `credentials.txt` file contains the configuration used to create the initial WordPress accounts:

- Administrator username, password, and email address.
- Second WordPress username, password, and email address.

These credentials are used during the initial installation. Changing the file later does not automatically change the passwords of accounts that already exist in WordPress.

To change an existing WordPress account's password, log in to WordPress and use the account profile settings, or use an appropriate administrative procedure.

### Database credentials

The other files contain database passwords:

- `db_password.txt` contains the password for the WordPress database user.
- `db_root_password.txt` contains the MariaDB root password.

These credentials are intended for service configuration and database administration, not for logging in to WordPress.

### Credential safety

- Never publish passwords in documentation, screenshots, or public repositories.
- Do not commit the contents of `secrets/` to Git.
- Restrict access to these files on the host.
- Use strong, unique passwords.
- Do not share the MariaDB root password with ordinary website users.

The secret files are read by the containers when required. Editing a secret file does not necessarily update credentials already configured in MariaDB or WordPress.

## 5. Starting and Stopping the Project

Run these commands from the root of the repository.

### Start the project

```bash
make
```

This builds the service images and starts the containers in detached mode.

You can also use:

```bash
make up
```

### Stop the project

```bash
make stop
```

This stops the running containers without removing them.

### Stop and remove the containers

```bash
make down
```

This removes the containers and the Compose network. Persistent website and database data should remain in the configured host directories.

To start the project again, run:

```bash
make up
```

### View service status

```bash
make ps
```

This displays the status of the project's containers.

## 6. Checking That the Services Work

### Check container status

Run:

```bash
make ps
```

The NGINX, WordPress, and MariaDB containers should be running.

### Check service logs

To view logs from all services:

```bash
make logs
```

To inspect a particular service, use:

```bash
sudo docker logs nginx
sudo docker logs wordpress
sudo docker logs mariadb
```

Logs can help identify startup failures, database connection problems, or configuration errors.

### Test the website

From the virtual machine, run:

```bash
curl -k -I https://alpascua.42.fr
```

A response such as `HTTP/1.1 200 OK` indicates that the HTTPS endpoint returned a successful response.

The `-k` option allows `curl` to accept the project's self-signed certificate for this local test.

### Check the WordPress administration page

Open the following URL in a browser:

```text
https://alpascua.42.fr/wp-admin
```

The login page should appear if NGINX and WordPress are functioning correctly.

## 7. Data and Persistence

The project stores persistent data outside the container filesystems.

| Data | Storage location |
|---|---|
| MariaDB database | `/home/alpascua