# User Documentation (USER_DOC.md)

This guide provides end users and administrators with simple, clear instructions on managing and interacting with the Inception web infrastructure.

---

## 1. Services Provided by the Stack

The infrastructure provides eight dedicated services:

### Mandatory Services
- **NGINX Web Gateway**: An encrypted reverse proxy operating over HTTPS (port 443 with TLSv1.2/TLSv1.3). It routes incoming requests to WordPress and serves static media assets.
- **WordPress Application (PHP-FPM)**: Powers the website and content management system, processing dynamic PHP requests on port 9000.
- **MariaDB Database**: Stores website data, users, blog posts, configurations, and taxonomy tables on internal port 3306.

### Bonus Services
- **Redis Cache**: In-memory caching layer accelerating WordPress database query performance.
- **FTP Server (`vsftpd`)**: Remote file management service pointing directly to the WordPress installation directory (`/var/www/html`).
- **Static Website (Portfolio)**: Showcase resume web application for `aarid` built without PHP using HTML5/CSS3/Node.js.
- **Adminer**: Web-based administration tool for managing MariaDB databases.
- **cAdvisor**: Telemetry dashboard providing real-time resource utilization (CPU, RAM, network) across all stack containers.

---

## 2. Starting and Stopping the Project

All stack operations are controlled through the `Makefile` at the repository root.

### Starting the Stack
To build and launch all containers in detached mode:
```bash
make
```
*(or `make bonus` / `make up`)*

### Stopping the Stack
To temporarily halt container execution without removing them:
```bash
make stop
```

To resume stopped containers:
```bash
make start
```

To stop and remove containers and networks while preserving database data:
```bash
make down
```

---

## 3. Accessing the Website and Administration Panel

### Domain Configuration
Before accessing the site, verify that the domain name points to your local machine. In `/etc/hosts`:
```text
127.0.0.1 aarid.42.fr
```

### Access URLs
| Service | URL / Port | Description |
| :--- | :--- | :--- |
| **WordPress Website** | `https://aarid.42.fr` | Main dynamic website |
| **WordPress Admin Panel** | `https://aarid.42.fr/wp-admin` | Administrative dashboard |
| **Static Portfolio** | `https://aarid.42.fr/portfolio/` | Static developer showcase |
| **Adminer** | `https://aarid.42.fr/adminer` | MariaDB web management |
| **cAdvisor** | `https://aarid.42.fr/cadvisor/` | Real-time container metrics |
| **FTP Server** | `aarid.42.fr:21` (passive `21100-21105`) | Remote file transfer |

### Default Accounts
- **WordPress Administrator**:
  - **Username**: `site_boss` (configured via `srcs/.env`)
  - **Password**: Found in `secrets/wp_admin_password.txt`
- **WordPress Standard User**:
  - **Username**: `evaluator` (configured via `srcs/.env`)
  - **Password**: Found in `secrets/wp_user_password.txt`
- **FTP User**:
  - **Username**: `ftpuser`
  - **Password**: Found in `secrets/ftp_password.txt`
- **MariaDB Root User**:
  - **Username**: `root`
  - **Password**: Found in `secrets/db_root_password.txt`
- **MariaDB Application User**:
  - **Username**: `wp_user`
  - **Password**: Found in `secrets/db_password.txt`

---

## 4. Locating and Managing Credentials

All sensitive credentials and passwords are decoupled from configuration files and stored securely inside the `secrets/` directory at the project root:

| Credential | File Location | Used By |
| :--- | :--- | :--- |
| **Database Root Password** | `secrets/db_root_password.txt` | MariaDB |
| **Database User Password** | `secrets/db_password.txt` | MariaDB, WordPress |
| **WordPress Admin Password** | `secrets/wp_admin_password.txt` | WordPress initial setup |
| **WordPress User Password** | `secrets/wp_user_password.txt` | WordPress initial setup |
| **FTP User Password** | `secrets/ftp_password.txt` | vsftpd FTP server |

### Changing Passwords
To change initial passwords prior to first deployment, edit the corresponding `.txt` file inside `secrets/` and update permissions:
```bash
chmod 600 secrets/*.txt
```

---

## 5. Checking that Services Are Running Correctly

### Checking Container Health and Status
Run the status command:
```bash
make status
```
Output will list all running containers:
```text
NAME          IMAGE             COMMAND                  SERVICE       STATUS
mariadb       mariadb:42        "/usr/local/bin/mari…"   mariadb       Up
redis         redis:42          "redis-server /etc/r…"   redis         Up
wordpress     wordpress:42      "/usr/local/bin/wp-s…"   wordpress     Up
ftp           ftp:42            "/usr/local/bin/ftp-…"   ftp           Up
static_site   static_site:42    "node server.js"         static_site   Up
adminer       adminer:42        "php -S 0.0.0.0:8080…"   adminer       Up
cadvisor      cadvisor:42       "/usr/local/bin/cadv…"   cadvisor      Up
nginx         nginx:42          "/usr/local/bin/entr…"   nginx         Up
```
Verify that all 8 services report status `Up`.

### Inspecting Live Logs
To monitor real-time activity:
```bash
make logs
```
To view logs for a single service:
```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f redis
docker compose -f srcs/docker-compose.yml logs -f ftp
docker compose -f srcs/docker-compose.yml logs -f adminer
docker compose -f srcs/docker-compose.yml logs -f cadvisor
```

### Checking Network Connectivity and SSL
Verify that NGINX answers over HTTPS with TLSv1.2 or TLSv1.3:
```bash
curl -kI https://aarid.42.fr
```

### Checking Redis Cache
In the container:
```bash
docker compose -f srcs/docker-compose.yml exec redis redis-cli ping
# Output: PONG
```
Or check the WordPress admin dashboard under **Settings > Redis** to confirm Redis Object Cache is enabled.

### Testing FTP
Connect with any FTP client:
```bash
ftp -p aarid.42.fr 21
# Enter username 'ftpuser' and password from secrets/ftp_password.txt
```
