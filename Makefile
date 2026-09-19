# TODO: ALLOW COMMENTS without approve AND USER REGISTERS IN WORDPRESS WEBSITE LATER

LOGIN       := aarid
DATA_DIR    := /home/$(LOGIN)/data
COMPOSE     := docker compose -f srcs/docker-compose.yml

all: up

build:
	@echo "Building Docker images..."
	@$(COMPOSE) build

up:
	@echo "Creating data persistence directories if they do not exist..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Starting up services..."
	@$(COMPOSE) up -d --build

down:
	@echo "Stopping and removing containers..."
	@$(COMPOSE) down

stop:
	@echo "Stopping containers..."
	@$(COMPOSE) stop

start:
	@echo "Starting stopped containers..."
	@$(COMPOSE) start

status:
	@echo "Checking containers status..."
	@$(COMPOSE) ps

logs:
	@echo "Displaying logs..."
	@$(COMPOSE) logs -f

clean: down
	@echo "Cleaning up containers and networks..."

fclean: down
	@echo "Performing deep cleanup (volumes, images, and data directories)..."
	@docker system prune -af --volumes || true
	@if [ -d "$(DATA_DIR)" ]; then \
		echo "Removing $(DATA_DIR)..."; \
		rm -rf $(DATA_DIR) || sudo rm -rf $(DATA_DIR) || true; \
	fi

re: fclean all

.PHONY: build up down stop start status logs
