import paramiko

def run_diagnostics():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    commands = {
        "docker_ps": 'docker ps | grep -E "traefik|hello1"',
        "compose_ps": 'cd /srv/apps/hello1 && docker compose ps',
        "labels": 'docker inspect hello1-service --format "{{json .Config.Labels}}"',
        "network": 'docker network inspect proxy --format "{{json .Containers}}"',
        "traefik_logs": 'docker logs traefik | tail -n 300 | grep -Ei "hello1|docker|router|rule|error" | tail -n 120',
        "curl_test": 'curl -sI --resolve hello1.valhallala.com:443:167.86.84.248 https://hello1.valhallala.com | sed -n "1,20p"'
    }
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        for name, cmd in commands.items():
            print(f"=== {name} ===")
            stdin, stdout, stderr = ssh.exec_command(cmd)
            print(stdout.read().decode('utf-8'))
            err = stderr.read().decode('utf-8')
            if err: print(f"STDERR: {err}")
            print("\n")
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    run_diagnostics()
