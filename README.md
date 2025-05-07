GitOps: Easy Deploy and Even Easer Rollback
===========================================

This is the code samples to the GitOps talk at https://robrich.org/slides/gitops/.


About
-----

This repo demonstrates two different GitOps scenarios:

1. An on-prem GitOps setup
2. A Docker & Kubernetes GitOps setup using [ArgoCD](https://argoproj.github.io/cd/)


The Apps
--------

### Frontend

- A Node.js / Express.js app shows a Handlebars UI
- In `/routes/index.js` is the configuration to call the backend.

### Backend

- An ASP.NET Minimal APIs app exposes APIs for creating and updating items and votes for each item.
- The data store is a static list, so restarting the app empties the "database".


On-Prem GitOps Setup
--------------------

The purpose of the On-Prem GitOps Setup is to show that GitOps is a methodology for deployment, and not a Kubernetes-specific toolchain or product.

### About

The on-prem setup uses scripts in the `build` folder.

- build.ps1: builds the two apps and commits assets to a local repository.
- deploy.ps1: copies deployed assets to the websites running in [PM2](https://pm2.keymetrics.io/)

### Setup

Outside this repo and in a folder next to it, create a git repo named `deploy`:

1. git clone this repo: `git clone https://github.com/robrich/gitops`
2. `mkdir deploy`
3. `cd deploy`
4. `git init --bare`
5. `cd ..`

This repo is the GitOps deployment repo.

Install dependencies on your machine:

6. Install [Node.js](https://nodejs.org/)
7. Install [ASP.NET SDK](https://dotnet.microsoft.com/en-us/download)
8. Install PM2: `npm install -g pm2`

Setup the sites:

9. `mkdir server`
10. `cd server`
11. `mkdir wwwroot`
12. `cd wwwroot`
13. `mkdir frontend`
14. `pm2 start --name frontend index.js`
    This will correctly fail because nothing exists in this directory yet
15. `cd ..`
16. `cd backend`
17. `pm2 start dotnet --name backend -- "backend.dll"`
    This will correctly fail because nothing exists in this directory yet
18. `cd ../../..`
19. `pm2 ls`
    This will show you the 2 apps are now failing but exist

### Build & Deploy

1. Run `build.ps1`. This is typically done by a build server.
   It will:
   - build the frontend and backend
   - copy the built assets to the `dist` directory
   - clone the `deploy` repository
   - copy the `dist` directory into `deploy/apps` and commit it

2. Run `deploy.ps1`. This is typically done on the production server by the Task Scheduler or cron.
   It will:
   - get the latest from the `deploy` repository
   - if nothing changed, it exits early
   - stop the backend site so files aren't in use
   - copy new content into place
   - restart all sites in pm2

3. Browse the sites:
   - Visit https://localhost:3000/ to view the frontend
   - Visit https://localhost:5000/ to view the backend

### Change and re-deploy

Now let's change the content and watch the GitOps process run.

1. Modify anything in either the frontend app or the backend app.  Perhaps change the word `Framework` to `Restaurant`.

2. Re-run build.ps1 & deploy.ps1, simulating the build server and the production scheduled task.

3. Refresh the sites to view the changes.


Kubernetes GitOps with ArgoCD
-----------------------------

This solution shows how you can use container tools with a GitOps process.

### About

- In the `apps` folder, in each folder is a `Dockerfile` that outlines the build steps.
- In the `k8s` folder are Kubernetes YAML files.
- In the `.github/workflows` folder is the GitHub Actions build script.
- We'll use ArgoCD in your k8s cluster of choice to deploy the apps.

Argo supports k8s yaml, helm charts, and others.  See https://github.com/argoproj/argocd-example-apps

### Setup

1. Fork this repository into your own account.

Setup the ArgoCD repo.  This repo will store built assets.  It is not a fork of this repo.

2. Create a new repository on your GitHub account to store ArgoCD assets.  I chose the name [`gitops-argocd`](https://github.com/robrich/gitops-argocd)

Setup the GitHub Actions build:

3. In your forked repository's settings, create Repository Secrets for:

   - `DOCKER_USERNAME`: your username on https://hub.docker.com/  With slight modification, you could also use a private container registry like Azure Container Registry or Elastic Container Registry.

   - `DOCKER_PASSWORD`: setup a [Docker Hub Access Token](https://docs.docker.com/security/for-developers/access-tokens/) and setup this secret with the value.

   - `GH_TOKEN`: setup a [GitHub Fine-grained Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
      - Give it permission to the Argo CD repository built above
      - Set `Contents` to `Read & Write` and leave all other permissions to `none`
      Set the value of this token into this secret.

      Note: We're specifically not using `GITHUB_TOKEN` because that one only has access to the current repository.

4. In your forked repository's settings, create Repository Variables for:

   - `ARGO_REPO`: the ArgoCD repository created above.  Mine is set to `robrich/gitops-argocd`.  Make sure to **NOT** include the `https://github/` part.

Now the two repositories are setup.

Install mkcert, a great tool for creating self-signed certificates with a trust chain.

5. Download [mkcert](https://github.com/FiloSottile/mkcert) and put it in your path.

6. `mkcert -install`

Next let's setup ArgoCD in the Kubernetes cluster.

7. In your k8s cluster of choice, follow the [ArgoCD Setup instructions](https://argo-cd.readthedocs.io/en/stable/getting_started/):

   - Download the ArgoCD CLI and put it in your path.

   - Run these commands in your terminal:

     ```sh
     mkcert localhost
     kubectl create namespace argocd
     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
     kubectl create -n argocd secret tls argocd-server-tls --cert=localhost.pem --key=localhost-key.pem
     kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
     kubectl -n argocd get secrets/argocd-initial-admin-secret --template="{{.data.password}}" | base64 -d
     kubectl -n argocd get svc
     # Note the https port for `argocd-server`
     argocd admin initial-password -n argocd
     argocd login localhost:NODE_PORT # <-- fill in the node port retrieved above
     # username is `admin`, password is the one you retrieved above
     https://localhost:NODE_PORT # <-- fill in the node port retrieved above
     # use the same login
     kubectl config get-contexts
     argocd cluster add docker-desktop # the name of your current kubectl context
     kubectl config set-context --current --namespace=argocd
     # change these URLs to your fork of the GitOps repo:
     argocd app create frontend --repo https://github.com/robrich/gitops-argocd --path apps/frontend --dest-server https://kubernetes.default.svc --dest-namespace default --sync-policy auto
     argocd app create backend --repo https://github.com/robrich/gitops-argocd --path apps/backend --dest-server https://kubernetes.default.svc --dest-namespace default --sync-policy auto
     ```

   - Now that you have Argo setup, refresh the ArgoCD website and see the 2 apps you have configured.

The apps are running because ArgoCD just deployed them, but they're likely failing because the containers don't yet exist.

### Build & Deploy

1. Visit your fork of the GitOps repo.  Mine is https://github.com/robrich/gitops

2. Click on Actions then choose `App Build` on the left.

3. On the far right, click `Run Workflow` and choose the `main` branch.

4. This will kick off the build, push containers to Docker Hub, then commit the k8s yaml files to the ArgoCD repo.

5. Refresh the ArgoCD dashboard.

   ArgoCD checks for changes every 10 seconds.  It'll notice the ArgoCD repo changed, and deploy the apps.

6. Browse the apps:
   - Visit https://localhost:3000/ to view the frontend
   - Visit https://localhost:5000/ to view the backend

Now we'll change something and watch it re-deploy.

7. Change something in the frontend or backend app.  Perhaps change the title `Frameworks` to `Restaurants` in `frontend/views/index.hbs`.

8. Commit and push this change.

9. Watch the GitHub Actions build complete.

10. Verify the new containers are pushed to Docker Hub.

11. Watch ArgoCD deploy these new versions to your cluster.

12. Refresh the frontend app, and notice the change.


License
-------

License: MIT, Copyright Richardson & Sons, LLC
