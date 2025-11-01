# Two-Tier Kubernetes Application (Frontend + Backend)

This project sets up a simple two-tier web application on a local Kubernetes cluster using Minikube. The frontend runs an NGINX web server, and the backend is a small HTTP echo service that returns a “Hello World” message.

## Steps to Run
1. Start the local cluster:
   ./setup-minikube-cluster.sh
2. Deploy the application:
   ./deploy-application.sh
3. After deployment, run
   minikube service frontend-service --url.

   Open that URL in your browser to view the app.

## Cleanup
To stop or remove the setup:
minikube stop
minikube delete
