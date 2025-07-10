# Build images locally without pushing to Docker Hub
docker_build("baobaomedia/baobao-frontend:dev", "apps/frontend", live_update=[
  sync("apps/frontend", "/app")
])
docker_build("baobaomedia/baobao-backend:dev", "apps/backend", live_update=[
  sync("apps/backend", "/app/backend")
])

k8s_yaml([
  "k8s/base/frontend.yaml",
  "k8s/base/backend.yaml",
])

k8s_resource("baobao-backend", port_forwards="3000:4000")
k8s_resource("baobao-frontend", port_forwards="4000:3000")

# Disable pushing to Docker Hub for local development
# Note: Tilt will build images locally but won't push them
