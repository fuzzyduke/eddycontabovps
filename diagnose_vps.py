import paramiko
import sys

def run_ssh_commands(ip, username, password, commands):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=username, password=password)
        
        for cmd in commands:
            print(f"--- EXECUTING: {cmd} ---")
            stdin, stdout, stderr = ssh.exec_command(cmd)
            out = stdout.read().decode('utf-8')
            err = stderr.read().decode('utf-8')
            if out: print(out)
            if err: print(f"STDERR: {err}")
            print("\n")
            
        ssh.close()
    except Exception as e:
        print(f"FAILED: {e}")

if __name__ == "__main__":
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    commands = [
        "git -C /srv rev-parse HEAD",
        "docker ps | grep -E 'traefik|hello1'",
        "cd /srv/apps/hello1 && docker compose ps",
        "docker inspect hello1-service --format '{{json .Config.Labels}}'",
        "docker network inspect proxy --format '{{json .Containers}}'",
        "docker logs traefik | tail -n 300 | grep -Ei 'hello1|docker|router|rule|error' | tail -n 120",
        "curl -sI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | sed -n '1,20p'"
    ]
    
    run_ssh_commands(ip, user, pw, commands)
