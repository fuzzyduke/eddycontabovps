import paramiko
import time

def master_deploy_ultra():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        # 1. Force Sync and Clean
        print("--- FORCING GIT SYNC ---")
        ssh.exec_command("cd /srv && git fetch origin master && git reset --hard origin/master && git clean -ffdx")
        # Explicitly remove acme.json to start fresh
        ssh.exec_command("rm -f /srv/infra/traefik/acme.json")
        time.sleep(3)
        
        # 2. Fix Permissions
        print("--- FIXING PERMISSIONS ---")
        ssh.exec_command("touch /srv/infra/traefik/acme.json && chmod 600 /srv/infra/traefik/acme.json")
        
        # 3. Restart Traefik
        print("--- RESTARTING TRAEFIK ---")
        ssh.exec_command("cd /srv/infra/traefik && docker compose down && docker compose up -d")
        time.sleep(10)
        
        # 4. Deploy App
        print("--- RUNNING DEPLOY.SH ---")
        stdin, stdout, stderr = ssh.exec_command("cd /srv && chmod +x deploy.sh && ./deploy.sh")
        print(stdout.read().decode('utf-8'))
        print(stderr.read().decode('utf-8'))
        
        # 5. CAPTURE FINAL AUDIT
        print("--- CAPTURING AUDIT DATA ---")
        cmds = [
            'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"',
            'docker exec traefik wget -qO- http://localhost:8080/api/rawdata | grep -Ei "hello1|router|rule"',
            'docker logs traefik 2>&1 | tail -n 200 | grep -Ei "hello1|docker|router|rule|error"',
            'curl -skI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | head -n 10'
        ]
        
        for cmd in cmds:
            print(f"\nAUDIT: [{cmd}]")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            print(se.read().decode('utf-8'))
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    master_deploy_ultra()
