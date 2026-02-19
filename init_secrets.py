import paramiko

def init_secrets_infra():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        commands = [
            'mkdir -p /srv/secrets',
            'chmod 700 /srv/secrets',
            'mkdir -p /opt/bible'
        ]
        
        for cmd in commands:
            print(f"Executing: {cmd}")
            ssh.exec_command(cmd)
            
        ssh.close()
        print("Infrastructure initialized successfully.")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    init_secrets_infra()
