*This project has been created as part of the 42 curriculum by aarid.*

# Inception

## Description

The **Inception** project is a system administration exercise focused on Docker and service administration. Its goal is to run a small web infrastructure as separate containers, connected through a private Docker network and configured with persistent storage.

The required services are built from custom Dockerfiles based on Debian Bookworm. Each container runs one main service.

### Mandatory Services

1. **NGINX**: Accepts web traffic over HTTPS on port 443 and routes requests to the web services. TLS 1.2 and TLS 1.3 are enabled.
2. **WordPress + PHP-FPM**: Runs the WordPress application. PHP-FPM listens on port 9000 inside the Docker network.
3. **MariaDB**: Stores WordPress content and configuration in a database on the internal Docker network.

### Bonus Services

4. **Redis**: Provides object caching for WordPress.
5. **FTP (`vsftpd`)**: Provides file transfer access to the WordPress files. FTP ports are published separately from HTTPS.
6. **Static site**: A portfolio built with HTML, CSS, and JavaScript, served by Node.js and available at `/portfolio/`.
7. **Adminer**: Web interface for managing MariaDB, available at `/adminer`.
8. **cAdvisor**: Displays container resource metrics and is available at `/cadvisor/`.

### Project Files

- `srcs/docker-compose.yml`: Defines the services, network, secrets, and persistent volumes.
- `srcs/requirements/mariadb/`, `wordpress/`, and `nginx/`: Dockerfiles, service configuration, and startup scripts for the required services.
- `srcs/requirements/bonus/`: Dockerfiles and files for Redis, FTP, the static site, Adminer, and cAdvisor.
- `srcs/.env.example`: Template for non-secret settings. Local `srcs/.env` and the root `secrets/` files provide deployment configuration and passwords.
- `Makefile`: Short commands to build, start, stop, and inspect the stack.

## Project Description and Docker Design Choices

The services run in separate containers built from this project’s Dockerfiles. The images use Debian Bookworm as their base. Startup scripts use `exec` for the main service process so it receives container signals directly. Non-secret settings are supplied through `srcs/.env`; passwords are supplied as Compose secrets.

### Architectural Comparisons

#### 1. Virtual Machines vs Docker

| Topic | Virtual Machines | Docker containers |
| :--- | :--- | :--- |
| Operating system | Each VM runs a guest operating system on virtual hardware. | Containers share the host kernel while isolating processes and resources. |
| Resources | A guest OS adds resource overhead. | Usually lighter because containers do not run a separate kernel. |
| Isolation | Isolation is provided by the hypervisor and guest OS boundary. | Isolation is provided by the container runtime and operating system; it is not the same boundary as a VM. |
| This project | Would require managing one or more guest systems. | Runs each service in its own container on the Docker network. |

#### 2. Secrets vs Environment Variables

| Topic | Environment variables | Compose secrets |
| :--- | :--- | :--- |
| Intended use | Convenient for non-secret settings such as domain names and database names. | Mounts sensitive values as files under `/run/secrets/` for services that need them. |
| Exposure | Values can be visible to processes and may appear in configuration or inspection output. | Keeps values out of the service environment and image, but does not by itself guarantee secure storage on the host. |
| This project | `srcs/.env` configures the domain and service settings. | Root-level files in `secrets/` provide passwords. Compose's file-backed secrets use those host files. |

#### 3. Docker Network vs Host Network

| Topic | Docker bridge network | Host network |
| :--- | :--- | :--- |
| Connectivity | Containers on the bridge can reach one another by service name. | A container shares the host network namespace. |
| Ports | Services can use the same internal port; `ports` publishes selected ports on the host. | Services bind directly to host ports, so port conflicts are possible. |
| This project | All services join the `inception-net` bridge. NGINX publishes port 443; FTP publishes port 21 and its passive range. | The stack does not use host networking. |

#### 4. Docker Volumes vs Bind Mounts

| Topic | Docker-managed named volume | Bind mount |
| :--- | :--- | :--- |
| Host path | Docker chooses and manages the storage location. | The configuration names a specific host path. |
| Portability | Usually less tied to a particular host directory layout. | Depends on the configured host path existing and having suitable permissions. |
| This project | Compose declares named volumes, but configures the local driver to use `/home/aarid/data/mariadb` and `/home/aarid/data/wordpress`. These are host-backed paths, so the data remains tied to those locations. | A direct bind mount uses a host path directly in the service's `volumes` entry. |

---

## Bonus Services Overview & Justification

1. **Redis (`srcs/requirements/bonus/redis`)**: WordPress uses Redis through the Redis Object Cache plugin to cache object data.
2. **FTP (`srcs/requirements/bonus/ftp`)**: `vsftpd` provides access to the shared WordPress files directory. It uses port 21 and passive ports `21100-21105`.
3. **Static site (`srcs/requirements/bonus/static_site`)**: A Node.js server serves the portfolio files on the Docker network; NGINX routes `/portfolio/` requests to it.
4. **Adminer (`srcs/requirements/bonus/adminer`)**: A web interface for connecting to and managing MariaDB through the Docker network.
5. **cAdvisor (`srcs/requirements/bonus/cadvisor`)**: Collects and displays resource metrics for the containers. It is available through NGINX at `/cadvisor/`.

---

## Instructions

### Requirements

- Docker Engine with the Docker Compose plugin
- GNU Make
- A Linux host or virtual machine

### Configure the Project

1. Create the local environment file from the example:

   ```sh
   cp srcs/.env.example srcs/.env
   ```

   Edit `srcs/.env`. Set `DOMAIN_NAME` to your chosen domain, and update the WordPress title and email addresses as needed. The example uses `login.42.fr`; replace `login` with your own login.

2. Create the repository-root `secrets/` directory and add the required password files. The filenames must match these entries:

   ```sh
   mkdir -p secrets
   ```

   ```text
   db_root_password.txt
   db_password.txt
   wp_admin_password.txt
   wp_user_password.txt
   ftp_password.txt
   ```

   Put one password in each file and restrict access:

   ```sh
   chmod 600 secrets/*.txt
   ```

3. Add your chosen domain to the host's `/etc/hosts` file. For the example domain:

   ```text
   127.0.0.1 login.42.fr
   ```

   Replace `login.42.fr` with the value of `DOMAIN_NAME` in `srcs/.env`. This project uses a self-signed TLS certificate, so browsers will show a certificate warning.

4. The Makefile stores persistent files in `/home/aarid/data`. If your Linux username differs, update `LOGIN` in the Makefile before starting the stack.

### Build and Run

Run commands from the repository root:

```sh
make          # Build images and start the stack
make status   # Show container status
make logs     # Follow logs from all services
make stop     # Stop containers without removing them
make start    # Start stopped containers
make down     # Remove containers and the project network; keep host data
```

`make clean` runs `make down`. **Destructive:** `make fclean` prunes unused Docker resources and deletes `/home/aarid/data`, including the persistent MariaDB and WordPress files. `make re` runs `fclean` before rebuilding, so it also deletes that data. Back up anything important before using either target.

### Access the Services

Use the domain configured in `srcs/.env`:

- WordPress: `https://login.42.fr/`
- WordPress administration: `https://login.42.fr/wp-admin/`
- Static portfolio: `https://login.42.fr/portfolio/`
- Adminer: `https://login.42.fr/adminer/` (server: `mariadb`; database: `wordpress`; credentials are in the database secret files)
- cAdvisor: `https://login.42.fr/cadvisor/`
- FTP: connect to `login.42.fr` on port `21` with the username in `FTP_USER` and password in `secrets/ftp_password.txt`; passive ports `21100-21105` must also be reachable.

The example WordPress administrator username is `site_boss`; its password is in `secrets/wp_admin_password.txt`. The regular WordPress user defaults to `evaluator`; its password is in `secrets/wp_user_password.txt`. Change these usernames and emails in `srcs/.env` before the first installation if desired.

---

## Resources

### References

- [Docker Documentation: Compose file specification](https://docs.docker.com/compose/compose-file/)
- [Docker Documentation: Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker Documentation: Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker Documentation: Bridge networks](https://docs.docker.com/engine/network/drivers/bridge/)
- [NGINX Documentation: Configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [MariaDB Documentation](https://mariadb.com/docs/server/)
- [WP-CLI Handbook: Command line interface for WordPress](https://make.wordpress.org/cli/handbook/)
- [PHP-FPM Documentation: FastCGI Process Manager](https://www.php.net/manual/en/install.fpm.php)
- [Redis Documentation](https://redis.io/documentation)
- [vsftpd Reference Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Adminer Official Site](https://www.adminer.org/)
- [Google cAdvisor GitHub](https://github.com/google/cadvisor)

### AI Usage Disclosure

AI assistance was used during development to:

- Debug service startup and routing problems, including MariaDB initialization and the resulting WordPress/Nginx behavior.
- Explain some weird configuration and choices
- Draft, clarify, and review Markdown documentation in `README.md`, `DEV_DOC.md`, and `USER_DOC.md`.

The project author is still the one responsible for reviewing and testing the resulting configuration.
