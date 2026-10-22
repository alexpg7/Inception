NAME        = inception
COMPOSE_FILE = srcs/docker-compose.yml
DOCKER_COMPOSE = sudo docker compose -f $(COMPOSE_FILE)

# Default target
all: up

# Build images and start all services
up:
	$(DOCKER_COMPOSE) up -d --build

# Alias for starting the project
run: up

# Build images without starting containers
build:
	$(DOCKER_COMPOSE) build

# Start existing containers
start:
	$(DOCKER_COMPOSE) start

# Stop containers without removing them
stop:
	$(DOCKER_COMPOSE) stop

# Stop and remove containers and the project network
down:
	$(DOCKER_COMPOSE) down --remove-orphans

# Stop and remove containers, networks, and named volumes
down-v:
	$(DOCKER_COMPOSE) down -v --remove-orphans

# Restart running containers
restart:
	$(DOCKER_COMPOSE) restart

# Rebuild images and recreate services
re:
	$(DOCKER_COMPOSE) down --remove-orphans
	$(DOCKER_COMPOSE) up -d --build

# Show service status
ps:
	$(DOCKER_COMPOSE) ps -a

# Follow logs; use Ctrl+C to stop following
logs:
	$(DOCKER_COMPOSE) logs -f --tail=100

# Show the resolved Compose configuration
config:
	$(DOCKER_COMPOSE) config

# Validate the Compose configuration
validate:
	$(DOCKER_COMPOSE) config -q

# Remove containers and networks, preserving volumes
clean: down

# Remove containers, networks, named volumes, and service images
fclean:
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans

# Display available targets
help:
	@echo "Inception - available targets:"
	@echo "  make          Build and start the project"
	@echo "  make up       Build and start all services"
	@echo "  make run      Alias for up"
	@echo "  make build    Build images only"
	@echo "  make start    Start existing containers"
	@echo "  make stop     Stop containers"
	@echo "  make down     Remove containers and networks"
	@echo "  make down-v   Remove containers, networks, and named volumes"
	@echo "  make restart  Restart containers"
	@echo "  make re       Rebuild and recreate the project"
	@echo "  make ps       Show container status"
	@echo "  make logs     Follow container logs"
	@echo "  make config   Display resolved Compose configuration"
	@echo "  make validate Validate Compose configuration"
	@echo "  make clean    Same as down"
	@echo "  make fclean   Remove containers, volumes, and service images"
	@echo "  make help     Display this help"

.PHONY: all up run build start stop down down-v restart re ps logs config validate clean fclean help