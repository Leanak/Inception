NAME = inception
LOGIN = lenakach
DATA = /home/$(LOGIN)/data

all : build up

build :
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	docker compose -f srs/docker-compose.yml up --build -d

up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	sudo rm -rf $(DATA)/mariadb/* $(DATA)/wordpress/*

re: fclean all

.PHONY: all build up down clean fclean re
