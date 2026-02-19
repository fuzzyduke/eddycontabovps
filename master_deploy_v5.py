import paramiko
import time

def master_deploy_v5():
    # Credentials from C:\Users\eggy doge\.gemini\antigravity\scratch\contabo-vps\credentials.md
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        # 1. Force Sync to latest fix (a7a4fcc)
        print("--- FORCING GIT SYNC TO a7a4fcc ---")
        ssh.exec_command("cd /srv && git fetch origin master && git reset --hard origin/master && git clean -ffdx")
        time.sleep(5)
        
        # 2. Re-trigger Infra (Traefik v2.11 + apiVersion 1.44)
        print("--- RESTARTING TRAEFIK v2.11 WITH FIX ---")
        ssh.exec_command("cd /srv/infra/traefik && docker compose down && docker compose up -d")
        time.sleep(10)
        
        # 3. Deploy App
        print("--- RUNNING DEPLOY.SH ---")
        stdin, stdout, stderr = ssh.exec_command("cd /srv && chmod +x deploy.sh && ./deploy.sh")
        print(stdout.read().decode('utf-8'))
        print(stderr.read().decode('utf-8'))
        
        # 4. CAPTURE FINAL AUDIT
        print("--- CAPTURING AUDIT DATA ---")
        cmds = [
            'docker ps | grep -E "traefik|hello11|hello1-service"',
            'cd /srv/apps/hello1 && docker compose ps',
            'docker inspect hello1-service --format "{{json .Config.Labels}}" || echo "NOT FOUND"',
            'docker network inspect proxy --format "{{json .Containers}}"',
            'docker logs traefik | tail -n 300 | grep -Ei "hello1|docker|router|rule|error" | tail -n 120',
            'curl -sI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | sed -n "1,20p"'
        ]
        
        for cmd in cmds:
            print(f"\nAUDIT: [{cmd}]")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            err = se.read().decode('utf-8')
            if err: print(f"STDERR: {err}")
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    master_deploy_v5()
