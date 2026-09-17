# User Documentation (USER_DOC.md)

This guide provides end users and administrators with simple, clear instructions on managing and interacting with the Inception web infrastructure.

---

## 1. Services Provided by the Stack

The infrastructure runs three dedicated services:
- **NGINX Web Gateway**: An encrypted reverse proxy operating over HTTPS (port 443 with TLSv1.2/TLSv1.3). It routes incoming requests to WordPress and serves static media assets.
- **WordPress Application (PHP-FPM)**: Powers the website and content management system, processing dynamic PHP requests on port 9000.
- **MariaDB Database**: Stores website data, users, blog posts, configurations, and taxonomy tables on internal port 3306.

---

## 2. Starting and Stopping the Project

All stack operations are controlled through the `Makefile` at the repository root.

### Starting the Stack
To build and launch all containers in detached mode:
```bash
make
```
*(or `make up`)*

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
- **Public Website**: Open a web browser and navigate to:
  ```text
  https://aarid.42.fr
  ```
  *(Accept the self-signed SSL certificate prompt).*
- **Administration Panel**: Open the WordPress administrative dashboard:
  ```text
  https://aarid.42.fr/wp-admin
  ```

### Default Accounts
- **Administrator**:
  - **Username**: `site_boss` (configured via `srcs/.env`)
  - **Password**: Found in `secrets/wp_admin_password.txt`
- **Standard User**:
  - **Username**: `evaluator` (configured via `srcs/.env`)
  - **Password**: Found in `secrets/wp_user_password.txt`

---

## 4. Locating and Managing Credentials

All sensitive credentials and passwords are decoupled from configuration files and stored securely inside the `secrets/` directory at the project root:

| Credential | File Location | Used By |
| :--- | :--- | :--- |
| **Database Root Password** | `secrets/db_root_password.txt` | MariaDB |
| **Database User Password** | `secrets/db_password.txt` | MariaDB, WordPress |
| **WordPress Admin Password** | `secrets/wp_admin_password.txt` | WordPress initial setup |
| **WordPress User Password** | `secrets/wp_user_password.txt` | WordPress initial setup |

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
Output will list the running containers:
```text
NAME        IMAGE       COMMAND                  SERVICE     CREATED         STATUS         PORTS
mariadb     mariadb     "/usr/local/bin/mari…"   mariadb     2 minutes ago   Up 2 minutes   3306/tcp
nginx       nginx       "/usr/local/bin/entr…"   nginx       2 minutes ago   Up 2 minutes   0.0.0.0:443->443/tcp
wordpress   wordpress   "/usr/local/bin/wp-s…"   wordpress   2 minutes ago   Up 2 minutes   9000/tcp
```
Verify that all 3 services report status `Up`.

### Inspecting Live Logs
To monitor real-time activity and troubleshoot potential issues:
```bash
make logs
```
To view logs for a single service:
```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### Checking Network Connectivity and SSL
Verify that NGINX answers over HTTPS with TLSv1.2 or TLSv1.3:
```bash
curl -kI https://aarid.42.fr
```
Expected output:
```text
HTTP/2 200
server: nginx
...
```
