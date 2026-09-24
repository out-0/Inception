*This project has been created as part of the 42 curriculum by aarid.*

# Inception

## Description

The **Inception** project is a system administration exercise designed to introduce containerization concepts and modern DevOps practices using Docker and Docker Compose. The primary goal is to build a secure, isolated, and multi-container web infrastructure hosted on a dedicated Linux Virtual Machine.

The stack is composed of dedicated microservices running in isolated containers built from custom Dockerfiles utilizing `debian:bookworm` (penultimate stable Debian release):

### Mandatory Services
1. **NGINX**: Acts as the sole public gateway to the web infrastructure, exposing exclusively port 443 with TLSv1.2 or TLSv1.3 encryption.
2. **WordPress + PHP-FPM**: Serves dynamic web content, executing PHP FastCGI requests independently on port 9000 without embedding an NGINX web server.
3. **MariaDB**: Relational database engine storing all WordPress content, user accounts, and configuration data on internal port 3306.

### Bonus Services
4. **Redis Cache**: In-memory data store providing object caching for WordPress, drastically reducing database read latency.
5. **FTP Server (`vsftpd`)**: File Transfer Protocol daemon pointing to the WordPress files volume for secure remote file management.
6. **Static Website (Portfolio)**: Showcase website for `aarid` built with non-PHP web technologies (HTML5, CSS3, modern JS) and served via a lightweight Node.js engine, reverse-proxied by NGINX at `/portfolio/`.
7. **Adminer**: Lightweight, single-file database management interface for MariaDB, accessible through NGINX at `/adminer`.
8. **cAdvisor (Service of Choice)**: Google's container telemetry daemon providing real-time resource usage, CPU, memory, and filesystem metrics across all containers in the stack.

---

## Project Description & Architectural Comparisons

### Docker Usage and Design Choices
Each service is decoupled according to the single-responsibility principle:
- No monolithic containers or pre-built service images from Docker Hub are permitted (except official Debian base OS images).
- Processes run directly under PID 1 using `exec` in shell entrypoints to ensure correct Unix signal forwarding (`SIGTERM`, `SIGINT`) and avoid hacky infinite loop wrappers (`tail -f`, `sleep infinity`).
- Sensitive data is decoupled from both code and image layers using Docker Secrets and environment configuration files (`.env`).

### Architectural Comparisons

#### 1. Virtual Machines vs Docker
| Feature | Virtual Machines (VMs) | Docker Containers |
| :--- | :--- | :--- |
| **Architecture** | Emulates complete hardware via a Hypervisor (Type 1 or Type 2). Runs a full guest operating system with its own kernel. | Shares the host Linux kernel and isolates processes via Linux namespaces (`pid`, `net`, `mnt`, `ipc`, `uts`) and control groups (`cgroups`). |
| **Resource Overhead** | Heavy: high RAM, CPU, and disk storage overhead per instance. | Lightweight: minimal overhead, processes run directly on host kernel. |
| **Startup Speed** | Minutes (full OS boot sequence). | Milliseconds to seconds (process execution). |
| **Isolation Level** | Strong hardware-level isolation. | Process-level isolation enforced by kernel namespaces and seccomp profiles. |
| **Portability** | Heavy image export (multi-gigabyte virtual disks). | Highly portable layered images with immutable specifications (Dockerfiles). |

#### 2. Secrets vs Environment Variables
| Feature | Environment Variables | Docker Secrets |
| :--- | :--- | :--- |
| **Storage & Visibility** | Stored in process memory and inspectable via `docker inspect`, `docker compose config`, or `/proc/$PID/environ`. | Stored in temporary in-memory filesystems (`/run/secrets/`) within the container. |
| **Image Leak Risk** | High risk if hardcoded in `Dockerfile` or exported in image history layers. | Zero risk: secrets are mounted only at runtime and never baked into images. |
| **Security Scope** | Best suited for non-confidential configuration (domain names, ports, public flags). | Required for sensitive credentials (database root passwords, user passwords, API keys). |
| **Lifecycle** | Persists across container restarts and inspect logs. | In-memory only; ceases to exist when container stops. |

#### 3. Docker Network vs Host Network
| Feature | Docker Network (Bridge) | Host Network (`network_mode: host`) |
| :--- | :--- | :--- |
| **Network Isolation** | Containers receive private IP addresses within an internal software bridge. Host ports must be explicitly mapped (`ports:`). | Container shares the network namespace and IP stack directly with the host machine. |
| **Port Collision** | Multiple containers can listen on the same internal port (e.g. MariaDB on 3306, PHP-FPM on 9000) without host collisions. | Containers cannot bind to the same port on the host machine. |
| **Security** | Isolated: unmapped ports remain inaccessible to outside networks and only visible to containers on the same bridge. | Insecure for multi-tenant services: any open port is exposed on all host network interfaces. |
| **Subject Compliance** | Mandatory (`inception-net` bridge). | Strictly prohibited (`network: host` is forbidden). |

#### 4. Docker Volumes vs Bind Mounts
| Feature | Docker Named Volumes | Host Bind Mounts |
| :--- | :--- | :--- |
| **Management** | Fully managed by the Docker daemon (`docker volume create`, `docker volume ls`). | Directly references an arbitrary path on the host filesystem without Docker management. |
| **Portability** | Abstracted from the host directory structure; easily shared across containers and backup drivers. | Bound to specific host directory paths and dependent on host filesystem structure. |
| **Subject Implementation** | Configured via Docker named volumes with local driver options (`driver_opts: type=none, o=bind, device=/home/aarid/data/...`). This fulfills both Docker named volume management and data persistence under `/home/aarid/data`. | Disallowed as raw bind mounts (`volumes: - /path/on/host:/path/in/container`). |

---

## Bonus Services Overview & Justification

1. **Redis Cache (`srcs/requirements/bonus/redis`)**:
   - High-performance in-memory key-value cache. Connected to WordPress via `WP_REDIS_HOST=redis` and the `redis-cache` plugin with `php8.2-redis`. Significantly accelerates database query resolution by caching object queries in RAM.
2. **FTP Server (`srcs/requirements/bonus/ftp`)**:
   - `vsftpd` configured with local user chroot pointing to `/var/www/html`. Operates on port 21 (control) and passive range `21100-21105`. Enables remote file uploads directly to the WordPress installation.
3. **Static Website (`srcs/requirements/bonus/static_site`)**:
   - Built completely without PHP using HTML5, CSS3, and JavaScript. Served via a custom native Node.js HTTP server on port 3000 and reverse-proxied by NGINX at `https://aarid.42.fr/portfolio/`.
4. **Adminer (`srcs/requirements/bonus/adminer`)**:
   - Full-featured database management web interface contained in a single PHP file. Provides an intuitive web UI to inspect tables, execute SQL queries, and manage MariaDB databases at `https://aarid.42.fr/adminer`.
5. **cAdvisor — Service of Choice (`srcs/requirements/bonus/cadvisor`)**:
   - **Justification**: In a production microservice environment, maintaining real-time observability of container resource consumption (CPU throttling, memory leaks, disk I/O, network traffic) is critical for system health and capacity planning. cAdvisor provides continuous real-time telemetry natively without external agents. Reverse-proxied by NGINX at `https://aarid.42.fr/cadvisor/`.

---

## Instructions

### 1. Prerequisites
- Linux Virtual Machine with Docker and Docker Compose installed.
- Administrative privileges (`sudo`) to create directory paths and update `/etc/hosts`.

### 2. Domain Name Setup
Map `aarid.42.fr` to your local host IP address in `/etc/hosts`:
```bash
sudo sed -i '1s/^/127.0.0.1 aarid.42.fr\n/' /etc/hosts
```
Or manually edit `/etc/hosts` to include:
```text
127.0.0.1 aarid.42.fr
```

### 3. Configuration & Secrets Setup
1. Duplicate the example environment file:
   ```bash
   cp srcs/.env.example srcs/.env
   ```
2. Create the `secrets/` directory at the repository root and populate the secret files:
   ```bash
   mkdir -p secrets
   echo "super_mariadb_root_pass" > secrets/db_root_password.txt
   echo "mariadb_user_pass"       > secrets/db_password.txt
   echo "wp_super_admin_pass"     > secrets/wp_admin_password.txt
   echo "wp_regular_user_pass"    > secrets/wp_user_password.txt
   echo "ftp_user_pass"           > secrets/ftp_password.txt
   chmod 600 secrets/*.txt
   ```

### 4. Build and Execution Commands
Run the stack using the root `Makefile`:
```bash
make          # Builds images and launches all services in the background
make status   # Displays the status of running containers
make logs     # Follows aggregate container logs
make down     # Stops and removes all containers
make clean    # Removes stopped containers and networks
make fclean   # Deep cleanup: removes containers, networks, images, volumes, and host data
make re       # Performs fclean and rebuilds the stack
```

### 5. Accessing the Services
- **WordPress Website**: `https://aarid.42.fr`
- **WordPress Admin Panel**: `https://aarid.42.fr/wp-admin`
  - Username: `site_boss` (or value set in `WP_ADMIN_USER`)
  - Password: as specified in `secrets/wp_admin_password.txt`
- **Static Portfolio**: `https://aarid.42.fr/portfolio/`
- **Adminer Database Manager**: `https://aarid.42.fr/adminer`
  - System: `MySQL` / `MariaDB`
  - Server: `mariadb`
  - Username: `wp_user`
  - Password: as specified in `secrets/db_password.txt`
  - Database: `wordpress`
- **cAdvisor Metrics Dashboard**: `https://aarid.42.fr/cadvisor/`
- **FTP Server**: Connect via FTP client (e.g. `ftp -p aarid.42.fr 21` or FileZilla):
  - Host: `aarid.42.fr`
  - Port: `21`
  - Username: `ftpuser`
  - Password: as specified in `secrets/ftp_password.txt`

---

## Resources

### References
- [Docker Documentation: Compose file specification](https://docs.docker.com/compose/compose-file/)
- [Docker Documentation: Manage sensitive data with Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation: Configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [MariaDB Knowledge Base: Starting and stopping MariaDB](https://mariadb.com/kb/en/starting-and-stopping-mariadb-automatically/)
- [WP-CLI Handbook: Command line interface for WordPress](https://make.wordpress.org/cli/handbook/)
- [PHP-FPM Documentation: FastCGI Process Manager](https://www.php.net/manual/en/install.fpm.php)
- [Redis Documentation](https://redis.io/documentation)
- [vsftpd Reference Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Adminer Official Site](https://www.adminer.org/)
- [Google cAdvisor GitHub](https://github.com/google/cadvisor)

### AI Usage Disclosure
In accordance with the 42 AI Instructions:
- **Tasks and Parts**: AI assistance was utilized to audit configuration compliance against the Inception v5.4 subject specifications, structure documentation (`README.md`, `USER_DOC.md`, `DEV_DOC.md`), and draft automated WP-CLI installation scripts, Redis cache integration, and vsftpd FTP setup.
- **Verification**: All generated Dockerfiles, configurations, and bash entrypoint scripts were systematically reviewed to ensure Debian Bookworm compatibility, valid shell shebangs, correct FastCGI proxy headers, and strict adherence to PID 1 signal handling without using banned loop workarounds (`tail -f`, `sleep infinity`).
