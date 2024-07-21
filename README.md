# Discord Docker VPS Bot v2

> [!IMPORTANT]
>
> You need a Discord bot token from [Discord Developer Portal](https://discord.dev). Create a application there.
>
> If you need any support, join our support Discord and create a ticket: https://discord.gg/6CDmXw5Q

**Features**
- Quick and easy deployment using Docker
- Autodeploy SSH (You can choose either tmate or serveo. If you're using servo.net, edit the script to use this command instead:  `ssh -R $HOSTNAME:22:localhost:22 serveo.net`. We suggest tmate for better uptime.)
- Deploys Docker Containers (you can run this anywhere you want, even on a bad computer / vps!)
- Has creation / deletion / listing of servers
- Supports Debian 12 and Ubuntu 22.04 (at the moment)
- A customizeable install script and docker image that you can change easily
- Uses slash commands to enhance the user expierence
- Start/stop/restart of VPS(s)
- Spec Limiter (RAM)
- Start and stop
- Systemd
- Fast Deployment

**Features in Progress**
- Alpine Linux Support
- Node support/shards
- A Plan system
- A renew system (Disableable and enableable)
- A expire system

**How to create a VPS using the bot?**
- Go in any channel that has slash command permissions (if you're not owner. If you're owner / administrator you can run this in any channel)
- Make sure the bot is in your server and is online
- Run /deploy-ubuntu or /deploy-debian (based on what os you want to use) and wait as it deploys. The bot will send you a message in DMS with the SSH command.
- Open your terminal and paste the SSH command to SSH into the server.

**Requirements to use the bot**:
- Your bot host is Linux (any distro). We recommand **Ubuntu, Debian, or Alpine** as the OS to get the best preformance.
- Docker is installed on your Linux machine.
- Python 3.10 is insatlled on your Linux machine. (You can run `sudo apt install python3 python3-pip` to download Python)

**How to use**:
- Download the latest `.py` and `Dockerfile1` and `Dockerfile2` file from our [Latest Releases](https://github.com/Is-a-space/discord-vps-creator/releases/)
- Compile the images using `docker build -t ubuntu-22.04-with-tmate -f Dockerfile1 . && docker build -t debian-with-tmate -f Dockerfile2 .` and wait for it to be done 
- Edit .py file and paste the token where it says `TOKEN=`. You can get your bots token from [here](https://discord.dev). Edit the specified resources (if you want) to adjust how much resources are allocated per VPS.
- Run the file by using `python3 main.py` or `python main.py` or `py main.py`

If you want to see the bot in action or you are too lazy to deploy it yourself, you can invite our VPS bot [here](https://discord.com/oauth2/authorize?client_id=1249856618468737104&permissions=8&integration_type=0&scope=bot)
