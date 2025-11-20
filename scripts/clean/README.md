# Docker clean-up script

`clean-docker.sh` reclaims disk space from Docker hosts. It is intended to run as root (or via `sudo`) because it touches `/var/lib/docker` and prunes system-wide resources.

## What it does

1. `docker container prune -f`: remove every stopped container.
2. `docker image prune -a -f`: drop all unreferenced images.
3. `docker network prune -f`: delete unused networks.
4. `docker builder prune -a -f`: clear build cache layers.
5. `find ... truncate`: zero out each container’s `*-json.log` file under `/var/lib/docker/containers/` to keep logs small.
6. `du -sh /var/lib/docker/overlay2`: print current overlay2 disk usage to the log for future comparison.

The script logs progress to `/var/log/docker-clean.log` and finishes quickly on most hosts.

## Dependencies

- Docker CLI (`docker`)
- Permission to run Docker commands and access `/var/lib/docker`
- `find`, `truncate`, and `du` (available on standard GNU/Linux installations)

## Configuration knobs

The script does not accept arguments; edit the file if you need custom behavior:

- Change `LOG_FILE` if `/var/log/docker-clean.log` is not desirable.
- Adjust or remove prune commands if you want to preserve dangling images/networks. For example, replace `docker image prune -a -f` with `docker image prune --filter "until=720h"` to keep assets newer than 30 days.
- Comment out the `find ... truncate` block if you rely on historical container logs.

## Cron example

```cron
# Clean Docker artifacts daily at 04:00
0 4 * * * /usr/local/bin/bash /path/to/repo/scripts/clean/clean-docker.sh >> /var/log/docker-clean.log 2>&1
```

Use absolute paths for both Bash and the script because cron’s `PATH` is minimal.

## Safety tips

- Run the script manually once (`sudo bash clean-docker.sh`) to see how much data is removed.
- Verify that no critical stopped containers or untagged images are needed before enabling the cron job.
- Consider running `docker system df` after the script to quantify space savings.

