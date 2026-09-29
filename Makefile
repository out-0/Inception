LOGIN       := aarid
DATA_DIR    := /home/$(LOGIN)/data
COMPOSE     := docker compose -f srcs/docker-compose.yml

all: up

bonus: all

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
	@sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all bonus build up down stop start status logs clean fclean re
