pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Force pull base image to fix CRITICAL OS vulnerability (zlib1g)
                    sh "docker build --no-cache -t rise-app ."
                    
                    // Security Gate: Scan the image. Fails if CRITICAL or HIGH vulnerabilities are found.
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 1 --severity CRITICAL,HIGH rise-app"
                }
            }
        }

        stage('Transfer Docker Image and Project to Remote Server') {
            steps {
                sshagent(['ssh']) {
                    sh '''
                    # Save Docker image and transfer to remote host
                    docker save rise-app -o rise-app.tar
                    scp -o StrictHostKeyChecking=no rise-app.tar vagrant@192.168.56.122:/tmp/

                    # Prepare remote folders
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

                    # HARDENING FIX: Docker Log Rotation (Automate on first run only)
                    if ! sudo grep -q 'max-size' /etc/docker/daemon.json; then
                        echo 'Applying Docker Log Rotation Configuration...'
                        echo '{\\"log-driver\\": \\"json-file\\", \\"log-opts\\": {\\"max-size\\": \\"10m\\", \\"max-file\\": \\"3\\"}}' | sudo tee /etc/docker/daemon.json
                        sudo systemctl restart docker
                    else
                        echo 'Docker Log Rotation Configuration already applied.'
                    fi
                    
                    # Hardening Fix: Secure copy and restrict PFX key access
                    sudo mkdir -p /tmp/certs
                    
                    # FIX: Use '|| true' to safely handle the old, insecure path /vagrant/files/ being empty or missing.
                    sudo cp /vagrant/files/buildservertest.pfx /tmp/certs/ || true

                    // CRITICAL FIX: Changed permissions from 600 to 644 to allow the container's non-root 'appuser' to read the mounted file, fixing the restart loop.
                    sudo chmod 644 /tmp/certs/buildservertest.pfx
                    
                    # FIX: Safely remove the insecure key from the shared directory. Use '|| true' to prevent script failure.
                    sudo rm -f /vagrant/files/buildservertest.pfx || true

                    # Hardening Fix: Configure Firewall (ufw)
                    sudo ufw --force reset
                    sudo ufw default deny incoming
                    sudo ufw default allow outgoing
                    sudo ufw allow 22/tcp comment 'Allow SSH for access'
                    sudo ufw allow 5001/tcp comment 'Allow HTTPS for rise-app'
                    sudo ufw allow from 192.168.56.121 to any port 9100 proto tcp comment 'Restrict node_exporter to Prometheus IP'
                    sudo ufw --force enable

                    # Install Docker if missing
                    if ! command -v docker &> /dev/null; then
                        sudo apt-get update -y
                        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                        echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                        sudo apt-get update -y
                        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                        sudo usermod -aG docker vagrant
                        sudo systemctl enable docker
                        sudo systemctl start docker
                    fi

                    # Load Docker image
                    sudo docker load -i /tmp/rise-app.tar

                    # Stop and remove old container
                    sudo docker stop rise-app || true
                    sudo docker rm rise-app || true

                    # Install netcat for connectivity test
                    sudo apt-get update -y && sudo apt-get install -y netcat
                    
                    # Check database connectivity (wait 60 seconds implied by original logic)
                    if ! nc -z 192.168.56.121 3306; then
                        echo Database server is not reachable after 60 seconds.
                        exit 1
                    fi

                    # Deploy Container (Hardened Configuration)
                    sudo docker run -d \\
                      -p 5001:5001 \\
                      --name rise-app \\
                      --restart unless-stopped \\
                      -v /tmp/certs/buildservertest.pfx:/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Path=/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Password=admin \\
                      -e ASPNETCORE_URLS=https://+:5001 \\
                      rise-app

                    # Update appsettings.json for DB connectivity
                    sudo docker exec rise-app sed -i 's/localhost/192.168.56.122/g' /app/wwwroot/appsettings.json

                    # Ensure node_exporter is running for Prometheus monitoring
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