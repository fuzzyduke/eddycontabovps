import paramiko

def inspect_git_drift():
    ip = "167.86.84.248"
    user = "root"
    pw = "2kPJXKNB7U3S"
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, username=user, password=pw)
        
        commands = [
            'cd /srv && git status',
            'cd /srv && git diff',
            'cd /srv && git log -1',
            'cd /srv && git config --list | grep autocrlf'
        ]
        
        for cmd in commands:
            print(f"--- {cmd} ---")
            si, so, se = ssh.exec_command(cmd)
            print(so.read().decode('utf-8'))
            print(se.read().decode('utf-8'))
            
        ssh.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    inspect_git_drift()
