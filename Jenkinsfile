pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t rise-app ."
                }
            }
        }

        stage('Transfer Docker Image and Project to Remote Server') {
            steps {
                sshagent(['ssh']) {
                    sh '''
                    # Save Docker image
                    docker save rise-app -o rise-app.tar

                    # Copy Docker image to remote
                    scp -o StrictHostKeyChecking=no rise-app.tar vagrant@192.168.56.122:/tmp/

                    # Ensure remote folder exists
                    ssh -o StrictHostKeyChecking=no vagrant@192.168.56.122 "mkdir -p /tmp/dotnet-2526-vc2"

                    # Copy full project folder to remote
                    scp -r -o StrictHostKeyChecking=no dotnet-2526-vc2 vagrant@192.168.56.122:/tmp/
                    '''
                }
            }
        }

        stage('Provision and Deploy on Remote Server') {
            steps {
                sshagent(['ssh']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no vagrant@192.168.56.122 "
                    set -e

                    # ** HARDENING PHASE 1: Host & Permissions **

                    # Create a secure directory for the certificate in /tmp (non-shared)
                    sudo mkdir -p /tmp/certs
                    
                    # Copy the key to the secure, non-shared location
                    sudo cp /vagrant/files/buildservertest.pfx /tmp/certs/
                    
                    # Critical Fix 3.1: RESTRICT SSL KEY PERMISSIONS 
                    # Set to 600 (Read/Write for owner only, which is 'root' after sudo cp)
                    sudo chmod 600 /tmp/certs/buildservertest.pfx

                    # Critical Fix 1.1 & High Fix 1.2: FIREWALL (KEEP THIS BLOCK)
                    # ... (rest of the firewall and docker install code remains the same) ...
                    sudo ufw --force reset
                    sudo ufw default deny incoming
                    sudo ufw default allow outgoing
                    sudo ufw allow 22/tcp comment 'Allow SSH for access'
                    sudo ufw allow 5001/tcp comment 'Allow HTTPS for rise-app'
                    sudo ufw allow from 192.168.56.121 to any port 9100 proto tcp comment 'Restrict node_exporter to Prometheus IP'
                    sudo ufw --force enable

                    # Install Docker if missing (SKIP for brevity, but keep in your file)
                    # ...

                    # Load Docker image (SKIP for brevity, but keep in your file)
                    sudo docker load -i /tmp/rise-app.tar

                    # Stop old container if exists (SKIP for brevity, but keep in your file)
                    sudo docker stop rise-app || true
                    sudo docker rm rise-app || true

                    # Install netcat for connectivity test (SKIP for brevity, but keep in your file)
                    # ...
                    
                    if ! nc -z 192.168.56.121 3306; then
                        echo Database server is not reachable after 60 seconds.
                        exit 1
                    fi

                    # ** HARDENING PHASE 2: Container Configuration **
                    
                    # Critical Fix 2.1: REMOVE INSECURE --network host FLAG
                    # *** IMPORTANT: UPDATE VOLUME MOUNT TO USE THE SECURE /tmp/certs LOCATION ***
                    sudo docker run -d \\
                      -p 5001:5001 \\
                      --name rise-app \\
                      --restart unless-stopped \\
                      -v /tmp/certs/buildservertest.pfx:/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Path=/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Password=admin \\
                      -e ASPNETCORE_URLS=https://+:5001 \\
                      rise-app

                    sudo docker exec rise-app sed -i 's/localhost/192.168.56.122/g' /app/wwwroot/appsettings.json

                    # Ensure node_exporter is running (KEEP THIS BLOCK)
                    if ! sudo docker ps -q -f name=node_exporter | grep -q .; then
                        sudo docker run -d --name node_exporter -p 9100:9100 --restart unless-stopped prom/node-exporter:latest
                    else
                        echo 'node_exporter is already running, skipping...'
                    fi
                    "
                    '''
                }
            }
        }
    }
}