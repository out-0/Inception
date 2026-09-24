# Developer Documentation (DEV_DOC.md)

This documentation provides engineers and developers with technical details required to install, inspect, maintain, and modify the Inception infrastructure (Mandatory and Bonus stacks).

---

## 1. Setting Up the Environment from Scratch

### System Prerequisites
- Operating System: Debian (recommended by 42 curriculum) or equivalent Linux distribution running in a Virtual Machine.
- Required Packages:
  - `docker.io` or Docker Engine (v24.0+)
  - `docker-compose-plugin` (Docker Compose v2.0+)
  - `make`
  - `git`
  - `openssl` (for host-level debugging if needed)

### Repository Layout
```text
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                  <- Untracked secrets directory
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env                  <- Untracked environment variables file
    ├── .env.example          <- Template file for configuration
    ├── docker-compose.yml    <- Main orchestration file
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   └── tools/mariadb-setup.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/www.conf
        │   └── tools/wp-setup.sh
        └── bonus/
            ├── adminer/
            │   ├── Dockerfile
            │   └── .dockerignore
            ├── cadvisor/
            │   ├── Dockerfile
            │   └── .dockerignore
            ├── ftp/
            │   ├── Dockerfile
            │   ├── .dockerignore
            │   ├── conf/vsftpd.conf
            │   └── tools/ftp-setup.sh
            ├── redis/
            │   ├── Dockerfile
            │   ├── .dockerignore
            │   └── conf/redis.conf
            └── static_site/
                ├── Dockerfile
                ├── .dockerignore
                ├── server.js
                └── app/
                    ├── index.html
                    └── style.css
```

### Configuration & Secret Initialization
1. **Initialize `.env`**:
   ```bash
   cp srcs/.env.example srcs/.env
   ```
2. **Initialize Secrets**:
   Create the directory `secrets/` at repository root:
   ```bash
   mkdir -p secrets
   echo "db_root_pass_123"    > secrets/db_root_password.txt
   echo "db_user_pass_123"    > secrets/db_password.txt
   echo "wp_admin_pass_123"   > secrets/wp_admin_password.txt
   echo "wp_user_pass_123"    > secrets/wp_user_password.txt
   echo "ftp_pass_123"        > secrets/ftp_password.txt
   chmod 600 secrets/*.txt
   ```
3. **Map Domain in `/etc/hosts`**:
   Ensure `aarid.42.fr` resolves locally:
   ```bash
   sudo sed -i '1s/^/127.0.0.1 aarid.42.fr\n/' /etc/hosts
   ```

---

## 2. Building and Launching the Project

The orchestration is automated using `make` which interacts directly with `docker compose`:

```bash
# Build images and start all containers in detached mode
make

# Explicit rebuild without cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Run in foreground to monitor startup trace
docker compose -f srcs/docker-compose.yml up
```

### Startup Sequence & Architecture
1. **Host Directories**: `make` creates `/home/aarid/data/mariadb` and `/home/aarid/data/wordpress` if they do not exist.
2. **MariaDB**: Boots, reads root and user secrets, performs database bootstrapping with `mariadb-install-db` and `mariadbd --bootstrap`, then runs `exec mariadbd --user=mysql --console` on PID 1.
3. **Redis**: Boots in-memory data store on port 6379 under PID 1 (`redis-server /etc/redis/redis.conf`).
4. **WordPress**: Starts, polls `mariadb:3306` until responsive, runs `wp core download`, configures `wp-config.php` (including Redis cache parameters), installs WordPress, enables Redis Object Cache plugin, creates the second user (`evaluator`), and calls `exec php-fpm8.2 -F`.
5. **FTP Server**: Configures `ftpuser` with password from secrets, sets home to `/var/www/html`, and executes `exec /usr/sbin/vsftpd` on PID 1.
6. **Static Website**: Starts Node.js static server on port 3000 (`exec node server.js`).
7. **Adminer**: Starts built-in PHP web server on port 8080 (`exec php -S 0.0.0.0:8080 -t /var/www/html`).
8. **cAdvisor**: Collects container telemetry on port 8080.
9. **NGINX**: Generates self-signed TLS certificates for `aarid.42.fr` if not already present, binds to port 443, reverse-proxies `/`, `/portfolio/`, `/adminer`, and `/cadvisor/`, and executes `exec nginx -g "daemon off;"`.

---

## 3. Container, Volume, and Network Management

### Useful Developer Commands
| Operation | Command |
| :--- | :--- |
| **View Active Containers** | `docker compose -f srcs/docker-compose.yml ps` |
| **Inspect Running Process Tree** | `docker compose -f srcs/docker-compose.yml top` |
| **Follow Live Aggregate Logs** | `docker compose -f srcs/docker-compose.yml logs -f` |
| **Shell Access (WordPress)** | `docker compose -f srcs/docker-compose.yml exec wordpress sh` |
| **Shell Access (MariaDB)** | `docker compose -f srcs/docker-compose.yml exec mariadb sh` |
| **Shell Access (NGINX)** | `docker compose -f srcs/docker-compose.yml exec nginx sh` |
| **Inspect Network Bridge** | `docker network inspect inception-net` |
| **Inspect Docker Volumes** | `docker volume inspect srcs_mariadb_data srcs_wordpress_data` |

### Cleanup Routines
- Standard shutdown:
  ```bash
  make down
  ```
- Complete teardown and storage wipe:
  ```bash
  make fclean
  ```

---

## 4. Data Storage and Persistence

Data persistence is managed through Docker named volumes utilizing the `local` volume driver with direct host device bindings:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/aarid/data/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/aarid/data/wordpress
```

### Host Persistence Paths
- **MariaDB Relational Data**: `/home/aarid/data/mariadb`
  - Stores all MySQL table data, innodb logs, and system schemas.
- **WordPress Web Files**: `/home/aarid/data/wordpress`
  - Contains core WordPress files, `wp-config.php`, plugin installations, themes, and uploaded media (`wp-content/uploads/`). Shared with FTP container for remote asset manipulation.
