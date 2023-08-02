## github-action-ssh-docker-compose
Simple github action to run docker-compose on remote host.

This action packs contents of the action workspace into archive.
Logs into remote host via ssh. Unpacks the workspace there and runs
`docker-compose up -d` command.

Comparing to other actions with similar behavior this one does not use any
unknown docker-images. It is entirely built from Dockerfile on top of
`alpine:3.8`.

## Inputs

 * `ssh_private_key` - Private SSH key used for logging into remote system.
   Please, keep your key securely in github secrets.
 * `ssh_host` - Remote host name.
 * `ssh_port` - Remote port for SSH connection. Default is 22.
 * `ssh_user` - Remote user which should have access to docker.
 * `docker_compose_prefix` - Project name passed to compose. Each docker
   container will have this prefix in name.
 * `docker_compose_filename` - Path to the docker-compose file in the repository.
 * `use_stack` - Use docker stack instead of docker-compose.
 * `tar_package_operation_modifiers` - Modifiers for tar package operation. Default is '--exclude .git --exclude .github'

# Usage example

Let's say we have a repo with single docker-compose file in it and remote
ubuntu based server with docker and docker-compose installed.

1. Generate key pair, do not use a password here.

```
ssh-keygen -t ed25519 deploy_key
```

2. Create a user which will deploy containers for you on the remote server, do
not set password for this user:

```
ssh example.com
$ sudo useradd -m -b /var/lib -G docker docker-deploy
```

3. Allow to log into that user with the key you generated on the step one.

```
scp deploy_key.pub example.com:~
ssh example.com
$ sudo mkdir /var/lib/docker-deploy/.ssh
$ sudo chown docker-deploy:docker-deploy /var/lib/docker-deploy/.ssh
$ sudo install -o docker-deploy -g docker-deploy -m 0600 deploy_key.pub /var/lib/docker-deploy/.ssh/authorized_keys
$ sudo chmod 0500 /var/lib/docker-deploy/.ssh
$ rm deploy_key.pub
```

4. Test that key works.

```
ssh -i deploy_key docker-deploy@example.com
```

5. Add private key and user name into secrets for the repository. Let's say that
names of the secrets are `EXAMPLE_COM_SSH_PRIVATE_KEY` and
`EXAMPLE_COM_SSH_USER`.

6. Remove your local copy of the ssh key:

```
rm deploy_key
```

7. Setup a github-actions workflow (e.g. `.github/workflows/main.yml`):

```
name: Deploy

on:
  push:
    branches: [ master ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - uses: alex-ac/github-action-ssh-docker-compose@master
      name: Docker-Compose Remote Deployment
      with:
        ssh_host: example.com
        ssh_private_key: ${{ secrets.EXAMPLE_COM_SSH_PRIVATE_KEY }}
        ssh_user: ${{ secrets.EXAMPLE_COM_SSH_USER }}
        docker_compose_prefix: example_com
```

8. You're all set!

# Swarm & Stack

In case you want to use some advanced features like secrets. You'll need to
setup a docker swarm cluster and use docker stack command instead of the plain
docker-compose. To do that just set `use_stack` input to `"true"`:

```
name: Deploy
on:
  push:
    branches: [ master ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - actions/checkout@v2

    - uses: alex-ac/github-action-ssh-docker-compose@master
      name: Docker-Stack Remote Deployment
      with:
        ssh_host: example.com
        ssh_private_key: ${{ secrets.EXAMPLE_COM_SSH_PRIVATE_KEY }}
        ssh_user: ${{ secrets.EXAMPLE_COM_SSH_USER }}
        docker_compose_prefix: example.com
        use_stack: 'true'
```

