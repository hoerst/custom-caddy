# Custom Caddy Docker Image (Bunny DNS + DDNS + CrowdSec)

This repository provides an automated build for a custom Caddy Docker image, optimized for usage in standard Docker environments and as a drop-in replacement on Unraid. The build process runs weekly via GitHub Actions and publishes the image to the GitHub Container Registry (GHCR).

## Integrated Modules
The image is compiled from the official `caddy:2-builder` using `xcaddy` and includes the following plugins:
* [caddy-dns/bunny](https://github.com/caddy-dns/bunny): DNS-01 challenge support for Bunny.net to automatically provision TLS certificates.
* [mholt/caddy-dynamicdns](https://github.com/mholt/caddy-dynamicdns): Dynamic DNS update capability directly within Caddy.
* [hslatman/caddy-crowdsec-bouncer/http](https://github.com/hslatman/caddy-crowdsec-bouncer): Integration of the CrowdSec Bouncer as a Caddy HTTP handler.
* [alectrocute/caddy-bunnynet-ip](https://github.com/alectrocute/caddy-bunnynet-ip): Fetches Bunny.net Edge IPs to ensure real client IPs are passed to CrowdSec when using the CDN.

## Usage

### 1. Host Preparation
The `Caddyfile` must be created manually on the host system before starting the container to prevent the Docker daemon from creating a directory instead of a file.
```bash
mkdir -p /path/to/caddy/config
mkdir -p /path/to/caddy/data
touch /path/to/caddy/Caddyfile
```

### 2. Deployment

**Option A: Unraid**
1. Add a new container using the repository path: `ghcr.io/<YOUR_GITHUB_USERNAME>/caddy-bunny-ddns-crowdsec:latest` *(username must be lowercase)*.
2. Set the Network to a Custom Network (e.g., `br0`) with a dedicated IP, or change Unraid's default management ports (80/443) to avoid conflicts if using the `bridge` network.
3. Add Path mappings for `/data`, `/config`, and `/etc/caddy/Caddyfile`.
4. Add Variable mappings for `BUNNY_API_TOKEN` and `CROWDSEC_API_KEY`.
5. Install the Unraid plugin **CA Auto Update Applications** and enable it for this container to automatically receive the weekly GitHub builds.

**Option B: Docker Compose**
```yaml
services:
  caddy:
    image: ghcr.io/<YOUR_GITHUB_USERNAME>/caddy-bunny-ddns-crowdsec:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - BUNNY_API_TOKEN=your_token_here
      - CROWDSEC_API_KEY=your_key_here
    volumes:
      - /path/to/caddy/Caddyfile:/etc/caddy/Caddyfile
      - /path/to/caddy/data:/data
      - /path/to/caddy/config:/config
```

### 3. Secure Caddyfile Configuration
Use environment variables `{$VARIABLE}` instead of hardcoding sensitive keys directly into the file.

```caddyfile
{
    servers {
        trusted_proxies bunnynet {
            interval 12h
            timeout 15s
        }
    }
    
    dynamic_dns {
        provider bunny {$BUNNY_API_TOKEN}
        domains {
            yourdomain.com @ sub
        }
    }
    
    crowdsec {
        api_url http://<CROWDSEC_HOST_IP>:<CROWDSEC_PORT>
        api_key {$CROWDSEC_API_KEY}
    }
}

yourdomain.com {
    tls {
        dns bunny {$BUNNY_API_TOKEN}
    }
    crowdsec
    reverse_proxy <TARGET_IP>:<TARGET_PORT>
}
```
*Note: If Caddy fails to start with `trusted_proxies bunnynet` in the global `servers` block, the module syntax may require it to be placed directly inside the `reverse_proxy` block of your site.*

## Automated Updates
GitHub Actions rebuilds the image entirely from scratch (`no-cache: true`) every Sunday at 03:00 UTC to pull the latest module versions. 

## AI Disclosure
The code, configuration files, and documentation in this repository were generated with the assistance of an AI language model. All generated components have been logically verified based on official documentation for Caddy, Unraid, and the respective plugins.

## License
This project is licensed under the [Apache License 2.0](LICENSE).
