---
up:
  - "[[Self-Hosting]]"
projectName:
  - "[[!PG IT Infrastructure Build]]"
dateCreated: 2025-09-16
tags:
  - k/note
cssclasses:
  - wide-table
---
# Technology Stack for my infrastructure

3 levels:

- hardware/devices
- software
- domain (family, personal, development environment, business, customer)

## Hardware

| Device                  | Purpose                                                                                   | Connection                            | Backups                                                                                                                                                                                             | Power Protection |
| ----------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| iPhone                  | Personal mobile device                                                                    | WiFi                                  | iCloud                                                                                                                                                                                              | Battery          |
| iPad                    | Reading and some streaming                                                                | WiFi                                  | iCloud                                                                                                                                                                                              | Battery          |
| Mac Studio              | Development and main productivity device; RAG and AI suite                                | Gigabit                               | 1: TimeMachine on Seagate USB + git for dev projects (ondemand) + cron/rsync on iCloud<br>2: NAS Synology 8TB raid1 (disks to buy)<br>3: Cloud Sync from NAS<br>3: Monthly Physical Backup 2 cycles | UPS 1            |
| MacBook                 | Portable productivity device and secondary development                                    | WiFi + Gigabit when connected Desktop | 1: TimeMachine on Seagate USB + git for dev projects (ondemand) + cron/rsync on iCloud                                                                                                              | Battery          |
| MiniPC server           | Infrastructure services hosting (NextCloud), DNS/Tailscale exit node, Backup orchestrator | Gigabit                               | 1: Rsync on External HDD or on NAS (temporary)<br>2: NAS Synology 3TB raid1 (disks to buy)<br>3: Cloud Sync from NAS<br>4: Monthly Physical Backup 2 cycles                                         | UPS 2            |
| JBOD external enclosure | Media storage                                                                             | USB4 to MiniPC                        | 1: NAS Synology 4TB raid1 (disks to buy)<br>2: Cloud Sync from NAS<br>3: Monthly Physical Backup 2 cycles                                                                                           | UPS 2            |
| Gaming PC               | Gaming                                                                                    | Gigabit Ethernet                      | 1: Cloud Sync for saves and configs<br>2: NAS Synology 1TB raid1 (disks to buy)<br>3: 2: Cloud Sync from NAS                                                                                        | UPS 1            |

### Connection

The current router is limited to 1Gbps, it is worth to buy a new one 10Gbps. 
Test made on [[2025-09-16]]: (Writing from MacOS~880 Mbps (SSH) / ~666 Mbps (SMB)

Use tailnet for access encrypted for network devices, while use clouflare tunnels to give access to shared users.
[Reddit post about using Cloudflare Tunnels together with Tailnett](https://www.reddit.com/r/homelab/comments/1jaiczk/can_i_use_tailscale_and_cloudflare_tunnels/?show=original)
[Stop Using VPNs, DDNS & Port Forwarding: Cloudflare Tunnels Are Better! - YouTube](https://www.youtube.com/watch?v=3FiGPmls-fk&list=WL&index=11)

Reserved IPs:

- `*.1` router
- `*.5*`* Servers
	- `*.50` MiniPC
- `*.6*` Desktop Devices
	- `*.61` Mac Studio
	- `*.62` Gaming PC
- `*.7*` Backup devices 
	-  `*.70` Synology NAS 1
	- `*.70` Synology NAS 1
- `*.8*` Media storage devices
	- `*.80` JBOD Media Storage
- `*.9*` Devices (TV, SKY, etc.)
	- `*.90` TV4Salone
	- `*.91` TV4Salottino
	- `*.92` WebOS Tv Salone
	- `*.93` Tv Salottino
	- `*.95` SKY Q
	- `*.96` SKY Q mini cucina
	- `*.97` SKY Q mini sala
	- `*.98` WebOS Tv babbo
- `*.100`-`*.149` IoT Automations
	- Velux
	- Weather Station
	- Cellar
	- NEFF aspiration
- `*.150`-`*.199` DHCP
- 

### To Buy

HW: 

- Archer BE700 **€350**
- Geekom with Ryzen 3550H **€700** (with 1 SSD and RAM)
- RAID 1 SSD 4TB NVME 2x **€ 500**
- 32Gb RAM DDR4 2x **€ 110**
- 2 SSD 4TB RAID 1 Media server **€ 400**
- 2 IronWolf 4TB disks for MacStudio NAS € 100 x 2 **€ 200**
- 2nd NAS 4 bays DS925+ **€ 520**
- 4 IronWolf 4TB disks for MacStudio NAS € 100 x 2 **€ 400**
- 6 IronWolf 4TB disks for offsite Backup **€ 600**

Services:

- Hetzner Storage Box 11€ / month for 5 TB 
  
Additional considerations:

- Consider buying a rack

## Software


## Domains

1. Personal productivity
2. Family Storage
3. Development environment
4. Business Suite Cloud (via tailnet/tunnel)
5. Customer services (via tunnel)



| Service/SW              | Purpose                                                                     | Port         | Development | Business Suite | Services | Personal   | Family |
| ----------------------- | --------------------------------------------------------------------------- | ------------ | ----------- | -------------- | -------- | ---------- | ------ |
| Device                  | -                                                                           |              | Mac Studio  | MiniPC         | VPS      | Mac Studio | MiniPC |
| PostgreSQL              | General Database for every environment. One schema DB for every environment | 5432         | x           | x              | x        |            |        |
| Redis                   | Caching for database speed                                                  | 6379         | x           | x              | x        |            |        |
| PGVector                | On PostgreSQL                                                               |              | x           |                | x        |            |        |
| Nginx                   | Reverse Proxy and balance load                                              | 8080-8443    | x           | x              | x        |            |        |
| Socat Postres Proxy     | Proxy for Postgres for opening the remote connections                       | 1234         |             |                |          |            |        |
| Grafana                 | Dashboards for business intelligence and observability                      | 3000 -> 3300 | x           | x              | x        |            |        |
| Prometheus              |                                                                             | 9090         | x           | x              | x        |            |        |
| Loki                    |                                                                             | 3100         | x           | x              | x        |            |        |
| Grafana Alloy           |                                                                             | 12345        | x           | x              | x        |            |        |
| Prometheus Alertmanager |                                                                             | 9093         | x           | x              | x        |            |        |
| Ollama                  |                                                                             | 11434-11438  | x           | x              | x        |            |        |
| Tailscale               |                                                                             | 80-443       | x           | x              |          |            |        |
| MinIO                   |                                                                             | 9000         | x           | x              | x        |            |        |
| RAG Service             |                                                                             |              | x           |                | x        |            |        |
| Pi-Hole DNS             |                                                                             | 53           |             | x              |          |            |        |
| NextCloud               |                                                                             | 80-443       |             | x              |          |            |        |
| SES Server              |                                                                             | 465-587      |             | x              |          |            |        |
| MailHog                 |                                                                             |              |             |                |          |            |        |
| Umami                   |                                                                             | 3000 -> 3400 |             | x              |          |            |        |
| LangChain               |                                                                             | 4137         | x           |                |          |            |        |
| LangGraph               |                                                                             | 2024         |             |                |          |            |        |
| LangFuse                |                                                                             | 3000 -> 3500 | x           |                |          |            |        |
| Supabase                |                                                                             | 8000         |             |                | x        |            |        |
| Obsidian                |                                                                             |              | x           |                |          |            |        |
| FASTAPI                 |                                                                             | 8000 -> 8100 | x           |                | x        |            |        |
| Hugo                    |                                                                             | 1313         | x           |                | x        |            |        |
| Next.js                 |                                                                             | 3000         | x           |                | x        |            |        |
| Streamlit               |                                                                             | 8000 -> 8200 | x           |                | x        |            |        |
| ntfy                    |                                                                             |              |             |                |          |            |        |
| Portainer               |                                                                             |              |             |                |          |            |        |
| Nginx proxy Manager     |                                                                             |              |             |                |          |            |        |
| Pydantic AI             |                                                                             |              |             |                |          |            |        |
| n8n                     |                                                                             |              |             |                |          |            |        |
| Crawl4ai                |                                                                             |              |             |                |          |            |        |
| BeautifulSoup           |                                                                             |              |             |                |          |            |        |
| Playwright              |                                                                             |              |             |                |          |            |        |

