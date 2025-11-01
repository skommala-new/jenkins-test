
#!/bin/bash
# Deploy two-tier application to Minikube

set -e

echo "Deploying application..."

# Check if cluster is running
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Error: Cannot connect to cluster"
    echo "Please run ./setup-minikube-cluster.sh first"
    exit 1
fi

# Apply Kubernetes manifests
kubectl apply -f - << 'EOFMANIFEST'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: hashicorp/http-echo:latest
        args:
          - "-text=Hello World from Backend!"
          - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
        - name: html
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: setup
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          cat > /config/default.conf << 'EOFNGINX'
          server {
              listen 80;
              location / { 
                  root /usr/share/nginx/html; 
                  index index.html;
              }
              location /api { 
                  proxy_pass http://backend-service; 
              }
          }
          EOFNGINX
          
          cat > /html/index.html << 'EOFHTML'
          <!DOCTYPE html>
          <html>
          <head>
              <title>Hello World App</title>
              <style>
                  body {
                      font-family: sans-serif;
                      background: linear-gradient(135deg, #667eea, #764ba2);
                      min-height: 100vh;
                      display: flex;
                      align-items: center;
                      justify-content: center;
                  }
                  .container {
                      background: white;
                      border-radius: 20px;
                      padding: 50px;
                      max-width: 700px;
                  }
                  h1 { text-align: center; }
                  button {
                      width: 100%;
                      background: linear-gradient(135deg, #667eea, #764ba2);
                      color: white;
                      padding: 18px;
                      border: none;
                      border-radius: 10px;
                      font-size: 18px;
                      cursor: pointer;
                  }
                  #response {
                      margin-top: 20px;
                      padding: 20px;
                      border-radius: 10px;
                      display: none;
                  }
                  .success { background: #d4edda; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>Hello World</h1>
                  <p>Two-Tier Kubernetes Application</p>
                  <button onclick="callBackend()">Test Backend Connection</button>
                  <div id="response"></div>
              </div>
              <script>
                  async function callBackend() {
                      const div = document.getElementById('response');
                      div.style.display = 'block';
                      div.innerHTML = 'Connecting...';
                      try {
                          const r = await fetch('/api');
                          const t = await r.text();
                          div.className = 'success';
                          div.innerHTML = 'Success! Backend says: ' + t;
                      } catch(e) {
                          div.innerHTML = 'Error: ' + e.message;
                      }
                  }
              </script>
          </body>
          </html>
          EOFHTML
        volumeMounts:
        - name: config
          mountPath: /config
        - name: html
          mountPath: /html
      volumes:
      - name: config
        emptyDir: {}
      - name: html
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOFMANIFEST

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend
kubectl wait --for=condition=available --timeout=300s deployment/frontend

echo "Deployment complete!"
kubectl get pods
kubectl get services

APP_URL=$(minikube service frontend-service --url)
echo "Application URL: $APP_URL"
#echo "Opening application in browser..."
#minikube service frontend-service
