import random
import logging
import subprocess
import sys
import os
import re
import time
import concurrent.futures
import discord
from discord.ext import commands, tasks
import docker
import asyncio
from discord import app_commands

TOKEN = '' # TOKEN HERE
SERVER_LIMIT = 12000000
database_file = 'database.txt'

intents = discord.Intents.default()
intents.messages = False
intents.message_content = False

bot = commands.Bot(command_prefix='/', intents=intents)
client = docker.from_env()

# port gen forward module < i forgot this shit in the start
def generate_random_port(): 
    return random.randint(1025, 65535)

def add_to_database(user, container_name, ssh_command):
    with open(database_file, 'a') as f:
        f.write(f"{user}|{container_name}|{ssh_command}\n")

def remove_from_database(ssh_command):
    if not os.path.exists(database_file):
        return
    with open(database_file, 'r') as f:
        lines = f.readlines()
    with open(database_file, 'w') as f:
        for line in lines:
            if ssh_command not in line:
                f.write(line)

async def capture_ssh_session_line(process):
    while True:
        output = await process.stdout.readline()
        if not output:
            break
        output = output.decode('utf-8').strip()
        if "ssh session:" in output:
            return output.split("ssh session:")[1].strip()
    return None

def get_ssh_command_from_database(container_id):
    if not os.path.exists(database_file):
        return None
    with open(database_file, 'r') as f:
        for line in f:
            if container_id in line:
                return line.split('|')[2]
    return None

def get_user_servers(user):
    if not os.path.exists(database_file):
        return []
    servers = []
    with open(database_file, 'r') as f:
        for line in f:
            if line.startswith(user):
                servers.append(line.strip())
    return servers

def count_user_servers(user):
    return len(get_user_servers(user))

def get_container_id_from_database(user):
    servers = get_user_servers(user)
    if servers:
        return servers[0].split('|')[1]
    return None

@bot.event
async def on_ready():
    change_status.start()
    print(f'Bot is ready. Logged in as {bot.user}')
    await bot.tree.sync()

@tasks.loop(seconds=5)
async def change_status():
    try:
        if os.path.exists(database_file):
            with open(database_file, 'r') as f:
                lines = f.readlines()
                instance_count = len(lines)
        else:
            instance_count = 0

          status = f"with {instance_count} VDSes"
        await bot.change_presence(activity=discord.Game(name=status))
    except Exception as e:
        print(f"Failed to update status: {e}")

async def regen_ssh_command(interaction: discord.Interaction, container_name: str):
    user = str(interaction.user)
    container_id = get_container_id_from_database(user, container_name)

    if not container_id:
        await interaction.response.send_message(embed=discord.Embed(description="No active instance found for your user.", color=0xff0000))
        return

    try:
        exec_cmd = await asyncio.create_subprocess_exec("docker", "exec", container_id, "tmate", "-F",
                                                        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        await interaction.response.send_message(embed=discord.Embed(description=f"Error executing tmate in Docker container: {e}", color=0xff0000))
        return

    ssh_session_line = await capture_ssh_session_line(exec_cmd)
    if ssh_session_line:
        await interaction.user.send(embed=discord.Embed(description=f"### New SSH Session Command: ```{ssh_session_line}```", color=0x00ff00))
        await interaction.response.send_message(embed=discord.Embed(description="New SSH session generated. Check your DMs for details.", color=0x00ff00))
    else:
        await interaction.response.send_message(embed=discord.Embed(description="Failed to generate new SSH session.", color=0xff0000))

async def start_server(interaction: discord.Interaction, container_name: str):
    user = str(interaction.user)
    container_id = get_container_id_from_database(user, container_name)

    if not container_id:
        await interaction.response.send_message(embed=discord.Embed(description="No instance found for your user.", color=0xff0000))
        return

    try:
        subprocess.run(["docker", "start", container_id], check=True)
        exec_cmd = await asyncio.create_subprocess_exec("docker", "exec", container_id, "tmate", "-F",
                                                        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        ssh_session_line = await capture_ssh_session_line(exec_cmd)
        if ssh_session_line:
            await interaction.user.send(embed=discord.Embed(description=f"### Instance Started\nSSH Session Command: ```{ssh_session_line}```", color=0x00ff00))
            await interaction.response.send_message(embed=discord.Embed(description="Instance started successfully. Check your DMs for details.", color=0x00ff00))
        else:
            await interaction.response.send_message(embed=discord.Embed(description="Instance started, but failed to get SSH session line.", color=0xff0000))
    except subprocess.CalledProcessError as e:
        await interaction.response.send_message(embed=discord.Embed(description=f"Error starting instance: {e}", color=0xff0000))

async def stop_server(interaction: discord.Interaction, container_name: str):
    user = str(interaction.user)
    container_id = get_container_id_from_database(user, container_name)

    if not container_id:
        await interaction.response.send_message(embed=discord.Embed(description="No instance found for your user.", color=0xff0000))
        return

    try:
        subprocess.run(["docker", "stop", container_id], check=True)
        await interaction.response.send_message(embed=discord.Embed(description="Instance stopped successfully.", color=0x00ff00))
    except subprocess.CalledProcessError as e:
        await interaction.response.send_message(embed=discord.Embed(description=f"Error stopping instance: {e}", color=0xff0000))

async def restart_server(interaction: discord.Interaction, container_name: str):
    user = str(interaction.user)
    container_id = get_container_id_from_database(user, container_name)

    if not container_id:
        await interaction.response.send_message(embed=discord.Embed(description="No instance found for your user.", color=0xff0000))
        return

    try:
        subprocess.run(["docker", "restart", container_id], check=True)
        exec_cmd = await asyncio.create_subprocess_exec("docker", "exec", container_id, "tmate", "-F",
                                                        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        ssh_session_line = await capture_ssh_session_line(exec_cmd)
        if ssh_session_line:
            await interaction.user.send(embed=discord.Embed(description=f"### Instance Restarted\nSSH Session Command: ```{ssh_session_line}```\nOS: Ubuntu 22.04", color=0x00ff00))
            await interaction.response.send_message(embed=discord.Embed(description="Instance restarted successfully. Check your DMs for details.", color=0x00ff00))
        else:
            await interaction.response.send_message(embed=discord.Embed(description="Instance restarted, but failed to get SSH session line.", color=0xff0000))
    except subprocess.CalledProcessError as e:
        await interaction.response.send_message(embed=discord.Embed(description=f"Error restarting instance: {e}", color=0xff0000))

def get_container_id_from_database(user, container_name):
    if not os.path.exists(database_file):
        return None
    with open(database_file, 'r') as f:
        for line in f:
            if line.startswith(user) and container_name in line:
                return line.split('|')[1]
    return None

async def execute_command(command):
    process = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await process.communicate()
    return stdout.decode(), stderr.decode()

async def capture_output(process, keyword):
    while True:
        output = await process.stdout.readline()
        if not output:
            break
        output = output.decode('utf-8').strip()
        if keyword in output:
            return output
    return None

async def create_server_task(interaction):
          await interaction.response.send_message(embed=discord.Embed(description="Creating VDS.\n~# This bot is powered by .gg/qemu AMD EPYC 9754 Servers.", color=0x00ff00))
    user = str(interaction.user)
    if count_user_servers(user) >= SERVER_LIMIT:
        await interaction.followup.send(embed=discord.Embed(description="```Error: Instance Limit-reached```", color=0xff0000))
        return

    image = "ubuntu-22.04-with-tmate"
    
    try:
        container_id = subprocess.check_output([
            "docker", "run", "--cpus 1", "--memory 6G", "-itd", image
        ]).strip().decode('utf-8')
    except subprocess.CalledProcessError as e:
      await interaction.followup.send(embed=discord.Embed(description=f"Something went wrong. Please report this to the .gg/qemu staff.", color=0xff0000))
        return

    try:
        exec_cmd = await asyncio.create_subprocess_exec("docker", "exec", container_id, "tmate", "-F",
                                                        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        await interaction.followup.send(embed=discord.Embed(description=f"Error executing tmate in Docker container: {e}", color=0xff0000))
        subprocess.run(["docker", "kill", container_id])
        subprocess.run(["docker", "rm", container_id])
        return

    ssh_session_line = await capture_ssh_session_line(exec_cmd)
    if ssh_session_line:
      await interaction.user.send(embed=discord.Embed(description=f"### Successfully created Instance\nSSH Session Command: ```{ssh_session_line}```\nOS: Ubuntu 22.04\n~# interested in our paid booster servers? Join .gg/qemu", color=0x00ff00))
        add_to_database(user, container_id, ssh_session_line)
        await interaction.followup.send(embed=discord.Embed(description="Instance created successfully. Check your DMs for details.", color=0x00ff00))
    else:
        await interaction.followup.send(embed=discord.Embed(description="Something went wrong or the Instance is taking longer than expected. If this problem continues, Contact Support.", color=0xff0000))
        subprocess.run(["docker", "kill", container_id])
        subprocess.run(["docker", "rm", container_id])

async def create_server_task_debian(interaction):
      await interaction.response.send_message(embed=discord.Embed(description="Creating VDS.\n~# This bot is powered by .gg/qemu AMD EPYC 9754 Servers.", color=0x00ff00))
    user = str(interaction.user)
    if count_user_servers(user) >= SERVER_LIMIT:
        await interaction.followup.send(embed=discord.Embed(description="```Error: Instance Limit-reached```", color=0xff0000))
        return

    image = "debian-with-tmate"
    
    try:
        container_id = subprocess.check_output([
            "docker", "run", "--cpus 1", "--memory 6G", "-itd", image
        ]).strip().decode('utf-8')
    except subprocess.CalledProcessError as e:
        await interaction.followup.send(embed=discord.Embed(description=f"Error creating Docker container: {e}", color=0xff0000))
        return

    try:
        exec_cmd = await asyncio.create_subprocess_exec("docker", "exec", container_id, "tmate", "-F",
                                                        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        await interaction.followup.send(embed=discord.Embed(description=f"Error executing tmate in Docker container: {e}", color=0xff0000))
        subprocess.run(["docker", "kill", container_id])
        subprocess.run(["docker", "rm", container_id])
        return

    ssh_session_line = await capture_ssh_session_line(exec_cmd)
    if ssh_session_line:
      await interaction.user.send(embed=discord.Embed(description=f"### Successfully created Instance\nSSH Session Command: ```{ssh_session_line}```\nOS: Debian\n~# interested in our paid booster servers? Join .gg/qemu", color=0x00ff00))
        add_to_database(user, container_id, ssh_session_line)
        await interaction.followup.send(embed=discord.Embed(description="Instance created successfully. Check your DMs for details.", color=0x00ff00))
    else:
        await interaction.followup.send(embed=discord.Embed(description="Something went wrong or the Instance is taking longer than expected. If this problem continues, Contact Support.", color=0xff0000))
        subprocess.run(["docker", "kill", container_id])
        subprocess.run(["docker", "rm", container_id])

@bot.tree.command(name="deploy-ubuntu", description="Creates a new Instance with Ubuntu 22.04")
async def deploy_ubuntu(interaction: discord.Interaction):
    await create_server_task(interaction)

@bot.tree.command(name="deploy-debian", description="Creates a new Instance with Debian 12")
async def deploy_ubuntu(interaction: discord.Interaction):
    await create_server_task_debian(interaction)

@bot.tree.command(name="regen-ssh", description="Generates a new SSH session for your instance")
@app_commands.describe(container_name="The name/ssh-command of your Instance")
async def regen_ssh(interaction: discord.Interaction, container_name: str):
    await regen_ssh_command(interaction, container_name)

@bot.tree.command(name="start", description="Starts your instance")
@app_commands.describe(container_name="The name/ssh-command of your Instance")
async def start(interaction: discord.Interaction, container_name: str):
    await start_server(interaction, container_name)

@bot.tree.command(name="stop", description="Stops your instance")
@app_commands.describe(container_name="The name/ssh-command of your Instance")
async def stop(interaction: discord.Interaction, container_name: str):
    await stop_server(interaction, container_name)

@bot.tree.command(name="restart", description="Restarts your instance")
@app_commands.describe(container_name="The name/ssh-command of your Instance")
async def restart(interaction: discord.Interaction, container_name: str):
    await restart_server(interaction, container_name)

@bot.tree.command(name="ping", description="Check the bot's latency.")
async def ping(interaction: discord.Interaction):
    latency = round(bot.latency * 1000)
    embed = discord.Embed(
        title="🏓 Pong!",
        description=f"Latency: {latency}ms",
        color=discord.Color.green()
    )
    await interaction.response.send_message(embed=embed)

@bot.tree.command(name="list", description="Lists all your Instances")
async def list_servers(interaction: discord.Interaction):
    user = str(interaction.user)
    servers = get_user_servers(user)
    if servers:
        embed = discord.Embed(title="Your Instances", color=0x00ff00)
        for server in servers:
            _, container_name, _ = server.split('|')
          embed.add_field(name=container_name, value="6GB RAM - 2cores - AMD EPYC 9754 Server", inline=False)
        await interaction.response.send_message(embed=embed)
    else:
        await interaction.response.send_message(embed=discord.Embed(description="You have no servers.", color=0xff0000))

@bot.tree.command(name="remove", description="Removes an Instance")
@app_commands.describe(container_name="The name/ssh-command of your Instance")
async def remove_server(interaction: discord.Interaction, container_name: str):
    user = str(interaction.user)
    container_id = get_container_id_from_database(user, container_name)

    if not container_id:
        await interaction.response.send_message(embed=discord.Embed(description="No Instance found for your user with that name.", color=0xff0000))
        return

    try:
        subprocess.run(["docker", "stop", container_id], check=True)
        subprocess.run(["docker", "rm", container_id], check=True)
        
        remove_from_database(container_id)
        
        await interaction.response.send_message(embed=discord.Embed(description=f"Instance '{container_name}' removed successfully.", color=0x00ff00))
    except subprocess.CalledProcessError as e:
        await interaction.response.send_message(embed=discord.Embed(description=f"Error removing instance: {e}", color=0xff0000))

@bot.tree.command(name="help", description="Shows the help message")
async def help_command(interaction: discord.Interaction):
    embed = discord.Embed(title="Help", color=0x00ff00)
    embed.add_field(name="/deploy-ubuntu", value="Creates a new Instance with Ubuntu 22.04.", inline=False)
    embed.add_field(name="/deploy-debian", value="Creates a new Instance with Debian 12.", inline=False)
    embed.add_field(name="/remove <ssh_command/Name>", value="Removes a server", inline=False)
    embed.add_field(name="/start <ssh_command/Name>", value="Start a server.", inline=False)
    embed.add_field(name="/stop <ssh_command/Name>", value="Stop a server.", inline=False)
    embed.add_field(name="/regen-ssh <ssh_command/Name>", value="Regenerates SSH cred", inline=False)
    embed.add_field(name="/restart <ssh_command/Name>", value="Stop a server.", inline=False)
    embed.add_field(name="/list", value="List all your servers", inline=False)
    embed.add_field(name="/ping", value="Check the bot's latency.", inline=False)
    await interaction.response.send_message(embed=embed)

bot.run(TOKEN)
