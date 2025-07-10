REGISTRY = baobaomedia
TAG = dev

.PHONY: build push deploy all tilt down rebuild clean

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

# Clean up containers and deployments
down: 
	kubectl delete -k k8s/base --ignore-not-found=true
	docker container prune -f
	docker image prune -f
	tilt down

# Clean Docker images
clean:
	docker rmi $(REGISTRY)/baobao-frontend:$(TAG) $(REGISTRY)/baobao-backend:$(TAG) --force 2>/dev/null || true

# Full rebuild cycle
rebuild: down clean build push deploy tilt 

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
	@echo "✅ Development environment ready!"
	@echo "🌐 Frontend: http://localhost:4000"
	@echo "🔧 Backend: http://localhost:3000"
	@echo "📊 Monitor: kubectl get pods"

# Complete workflow
all: build push deploy tilt

