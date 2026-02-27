# Remote Docker Server Info

> Connection details and usage for the remote Docker environment

← [Back to Guides](README.md)

---

## System Details

| Property | Value |
|----------|-------|
| IP | `10.0.1.9` |
| SSH Port | `22` |
| SSH User | `root` |
| SSH Key | already configured |
| Hostname | CT108 |
| OS | Linux 6.8.12-17-pve (Proxmox VE) |
| Architecture | x86_64 |
| Disk Total | 40GB |
| Disk Used | 1.4GB (4%) |
| Docker Version | 29.2.1 |
| Docker Compose Version | v5.1.0 |

## Docker Status

- **Containers**: None running
- **Images**: None cached

## Usage

### Run a command on the remote server

```bash
ssh root@10.0.1.9 "your command"
```

### Run Docker commands

```bash
ssh root@10.0.1.9 "docker ps -a"
ssh root@10.0.1.9 "docker run -d nginx"
ssh root@10.0.1.9 "docker-compose -f /path/to/docker-compose.yml up -d"
```

### Deploy with Docker Compose

1. Copy your docker-compose.yml to the server:

   ```bash
   scp docker-compose.yml root@10.0.1.9:/path/
   ```

2. Start the services:

   ```bash
   ssh root@10.0.1.9 "cd /path && docker compose up -d"
   ```

### View logs

```bash
ssh root@10.0.1.9 "docker logs <container_name>"
ssh root@10.0.1.9 "docker logs -f <container_name>"
```
