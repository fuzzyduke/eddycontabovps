import paramiko

def final_repair_and_deploy():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        # 1. Force Git Sync and Clean
        print("--- FORCING GIT SYNC ---")
        ssh.exec_command("cd /srv && git fetch origin master && git reset --hard origin/master && git clean -fd")
        
        # 2. Wait a moment and then run deploy.sh
        print("--- RUNNING DEPLOY.SH ---")
        stdin, stdout, stderr = ssh.exec_command("cd /srv && chmod +x deploy.sh && ./deploy.sh")
        print(stdout.read().decode('utf-8'))
        print(stderr.read().decode('utf-8'))
        
        # 3. Capture EVIDENCE
        print("--- CAPTURING AUDIT DATA ---")
        cmds = {
            "docker_ps": 'docker ps | grep -E "traefik|hello1"',
            "compose_ps": 'cd /srv/apps/hello1 && docker compose ps',
            "labels": 'docker inspect hello1-service --format "{{json .Config.Labels}}"',
            "network": 'docker network inspect proxy --format "{{json .Containers}}"',
            "traefik_logs": 'docker logs traefik | tail -n 200 | grep -Ei "hello1|docker|router|rule|error"',
            "curl_test": 'curl -sI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | sed -n "1,20p"'
        }
        
        for name, cmd in cmds.items():
            print(f"[{name}]")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            print("\n")
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    final_repair_and_deploy()
