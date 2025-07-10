REGISTRY = baobaomedia
TAG = dev

.PHONY: build push deploy all tilt down rebuild clean \
rebuild-local dev init update-frontend update-backend \
commit-all commit-frontend commit-backend

#initialization
init: 
	git submodule update --init --recursive

update-frontend:
	cd apps/frontend && git pull origin main && cd ../..

update-backend:
	cd apps/backend && git pull origin main && cd ../..

# Commit changes with a message
commit-all:
	@echo "Please provide a branch name and commit message."
	@read -p "Branch: " branch && \
	read -p "Message: " msg && \
	make commit-frontend branch=$$branch msg=$$msg && \
	make commit-backend branch=$$branch msg=$$msg

commit-frontend:
	cd apps/frontend && \
	git checkout $(branch) && \
	git pull origin $(branch) && \
	git add . && \
	git commit -m "$(msg)" && \
	git push origin $(branch) && \
	cd ../..

commit-backend:
	cd apps/backend && \
	git checkout $(branch) && \
	git pull origin $(branch) && \
	git add . && \
	git commit -m "$(msg)" && \
	git push origin $(branch) && \
	cd ../..

# Build Docker images with correct context
build:
	docker build -t $(REGISTRY)/baobao-frontend:$(TAG) -f apps/frontend/Dockerfile apps/frontend
	docker build -t $(REGISTRY)/baobao-backend:$(TAG) -f apps/backend/Dockerfile apps/backend

# Push images to registry
push: build
	docker push $(REGISTRY)/baobao-frontend:$(TAG)
	docker push $(REGISTRY)/baobao-backend:$(TAG)

# Deploy to Kubernetes
deploy: push
	kubectl apply -k k8s/base

# Start Tilt
tilt:
	tilt up

studio:
	cd apps/backend && npx prisma studio

# Clean up containers and deployments
down: 
	kubectl delete -k k8s/base --ignore-not-found=true
	docker container prune -f
	docker image prune -f
	tilt down

# Clean Docker images
clean:
	docker rmi $(REGISTRY)/baobao-frontend:$(TAG) $(REGISTRY)/baobao-backend:$(TAG) --force 2>/dev/null || true

# Local rebuild without pushing to Docker Hub
rebuild-local: down clean build
	k3d image import baobaomedia/baobao-frontend:dev -c baobao-cluster
	k3d image import baobaomedia/baobao-backend:dev -c baobao-cluster
	kubectl apply -k k8s/base
	tilt up

# Development workflow without Tilt (no Docker Hub)
dev: down clean build
	k3d image import baobaomedia/baobao-frontend:dev -c baobao-cluster
	k3d image import baobaomedia/baobao-backend:dev -c baobao-cluster
	kubectl apply -k k8s/base
	@echo "Development environment ready!"
	@echo "Frontend: http://localhost:4000"
	@echo "Backend: http://localhost:3000"
	@echo "Monitor: kubectl get pods"


# Full rebuild cycle
all: down clean build push deploy tilt studio


