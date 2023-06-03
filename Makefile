#DEFAULT
GREEN := "\e[92m"
STOP="\e[0m"

# EXPORT .ENV
export $(cat .env | xargs)

# DEFAULT
default:
	@printf ${GREEN}
	@echo 'Documentation for TEMPCONVERTER make commands:     '
	@printf ${STOP}
	@echo '---------------------------------------------------'
	@echo '  build        : will build app in /bin folder     '
	@echo '  package      : will package app in docker image  '
	@echo '  publish      : will publish docker image		  '
	@echo '  deploy       : will deploy images in docker swarm'
	@echo '  pipeline     : will do all steps above           '
	@echo '  local        : will run local containers         '
	@echo '  clean        : will clean /bin folder            '
	@echo '---------------------------------------------------'
	@echo ' '

# BUILD
build:
	mkdir -p bin
	podman build -f .docker/Dockerfile.build -t tempconverter-build . --no-cache
	podman run --name tempconverter tempconverter-build /bin/true
	podman cp tempconverter:/app/dist/app ./bin/app
	podman rm tempconverter

# PACKAGE
package:
	$(eval HASH=$(shell sha256sum bin/app | cut -d ' ' -f 1))
	podman build -f .docker/Dockerfile.app -t tempconverter-app . --no-cache
	podman tag tempconverter-app:latest tempconverter-app:$(HASH)

# PUBLISH
publish:
	$(eval IMAGES=$(shell podman images --format "{{.Repository}}:{{.Tag}}" | grep tempconverter-app))
	$(foreach IMAGE,$(IMAGES),\
		podman tag $(IMAGE) darwin0id/$(IMAGE) ;\
		podman push darwin0id/$(IMAGE) ;\
	)

# DEPLOY
deploy:
	docker swarm init
	cp .prod/docker-compose.yml.dist docker-compose.yml
	docker stack deploy -c docker-compose.yml tempconverter
	@echo ' '
	@printf ${GREEN}
	@echo 'Tempconverter is available at: http://localhost:5000'
	@printf ${STOP}
	@echo ' '

# PIPELINE
pipeline: build package publish deploy

# LOCAL
local:
	$(info Running tempconverter installation script, this might take a minute...)
	cp .local/docker-compose.yml.dist docker-compose.yml
	podman compose build --no-cache
	podman compose up --detach --force-recreate --remove-orphans
	@echo ' '
	@printf ${GREEN}
	@echo 'Tempconverter is available at: http://localhost:5000'
	@printf ${STOP}
	@echo ' '

# CLEAN
clean:
	-rm -rf bin
	-podman ps -q | xargs podman stop
	-podman rmi $(shell podman images -f "dangling=true" -q)
	-podman rmi $(shell podman images -f "reference=tempconverter-app" -q)
	-podman rmi $(shell podman images -f "reference=tempconverter-build" -q)
	-podman rmi tempconverter-build
	-podman rmi tempconverter-app
	-podman images --format "{{.Repository}}:{{.Tag}}" | grep tempconverter-app | xargs podman rmi -f
	-docker swarm leave --force

