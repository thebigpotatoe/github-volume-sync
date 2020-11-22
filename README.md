# github-volume-sync

This is a simple conteiner comprising of a few bash scripts to help sync GitHub repo's to a local docker or swarm instance. It current suits my needs and is open to anyone willing to use it.

Sync is acheived through SSH with GutHub and therefore requires adding a public key to your github account.

The private key can then either be added to your containers through ENV variables on container start or through secrets when using swarm. The required name is id_rsa for either the ENV or secret file name

## TODO

A better readme

## Build Commands

Local build container

`docker build -t local/github-volume-sync . `

## Test Run Commands

```
docker run -it --rm \
--name test \
-v test:/data  \
--env EMAIL="myemail@domain.com" \
--env NAME="myusername" \
--env ID_RSA="-----BEGIN OPENSSH PRIVATE KEY-----\n **** Add Key Here With \n Characters no spaces *** \n-----END OPENSSH PRIVATE KEY-----\n" \
--env REPO_STRING="myusername/repo" \
--env DATA_LOCATION="/data" \
github-volume-sync
```

```
docker service create \
--name test-service \
--env EMAIL="myemail@domain.com" \
--env NAME="myusername" \
--env REPO_STRING="myusername/repo" \
--env DATA_LOCATION="/data" \
--secret id_rsa \
--mount source=test,target=/data \
github-volume-sync
```