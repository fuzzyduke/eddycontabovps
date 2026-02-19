import paramiko
import time

def master_deploy_and_audit():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        # 1. Force Sync to latest fix
        print("--- FORCING GIT SYNC TO 732b5b9 ---")
        ssh.exec_command("cd /srv && git fetch origin master && git reset --hard origin/master && git clean -ffdx")
        time.sleep(2)
        
        # 2. Re-trigger Infra
        print("--- RESTARTING TRAEFIK WITH FIX ---")
        ssh.exec_command("cd /srv/infra/traefik && docker compose down && docker compose up -d")
        time.sleep(5)
        
        # 3. Deploy App
        print("--- RUNNING DEPLOY.SH ---")
        stdin, stdout, stderr = ssh.exec_command("cd /srv && chmod +x deploy.sh && ./deploy.sh")
        print(stdout.read().decode('utf-8'))
        print(stderr.read().decode('utf-8'))
        
        # 4. CAPTURE FINAL AUDIT (Evidence requested by user)
        print("--- CAPTURING AUDIT DATA ---")
        cmds = {
            "docker_ps": 'docker ps | grep -E "traefik|hello1"',
            "compose_ps": 'cd /srv/apps/hello1 && docker compose ps',
            "labels": 'docker inspect hello1-service --format "{{json .Config.Labels}}"',
            "network_inspect": 'docker network inspect proxy --format "{{json .Containers}}"',
            "traefik_logs": 'docker logs traefik | tail -n 300 | grep -Ei "hello1|docker|router|rule|error" | tail -n 120',
            "curl_resolve": 'curl -sI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | sed -n "1,20p"'
        }
        
        for name, cmd in cmds.items():
            print(f"\nAUDIT: [{name}]")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            err = se.read().decode('utf-8')
            if err: print(f"STDERR: {err}")
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    master_deploy_and_audit()
