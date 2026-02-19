import paramiko
import time

def run_command(ssh, cmd):
    print(f"--- RUNNING: {cmd} ---")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8')
    err = stderr.read().decode('utf-8')
    if out: print(out)
    if err: print(f"STDERR: {err}")
    return out, err

def repair_vps():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        # 1. Force clear Docker state
        run_command(ssh, "docker stop dokploy-traefik traefik || true")
        run_command(ssh, "docker rm dokploy-traefik traefik || true")
        
        # 2. Re-init repo properly
        run_command(ssh, "rm -rf /srv/.git")
        run_command(ssh, "mkdir -p /srv")
        run_command(ssh, "cd /srv && git init && git remote add origin https://github.com/fuzzyduke/eddycontabovps.git")
        run_command(ssh, "cd /srv && git fetch origin master && git reset --hard origin/master")
        
        # 3. Launch Infra
        run_command(ssh, "cd /srv/infra/traefik && docker compose up -d")
        
        # 4. Deploy app
        run_command(ssh, "cd /srv && chmod +x deploy.sh && ./deploy.sh")
        
        # 5. Final Diagnostic
        run_command(ssh, "docker ps | grep -E 'traefik|hello1'")
        run_command(ssh, "docker inspect hello1-service --format '{{json .Config.Labels}}' || true")
        
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    repair_vps()
