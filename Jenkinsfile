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

                    # Install Docker if missing
                    if ! command -v docker &> /dev/null; then
                        sudo apt-get update -y
                        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                        echo \\\"deb [arch=\\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \\$(lsb_release -cs) stable\\\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                        sudo apt-get update -y
                        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                        sudo usermod -aG docker vagrant
                        sudo systemctl enable docker
                        sudo systemctl start docker
                    fi

                    # Load Docker image
                    sudo docker load -i /tmp/rise-app.tar

                    # Stop old container if exists
                    sudo docker stop rise-app || true
                    sudo docker rm rise-app || true

                    # Install netcat for connectivity test
                    sudo apt-get update -y && sudo apt-get install -y netcat
                    
                    if ! nc -z 192.168.56.121 3306; then
                        echo "Database server is not reachable after 60 seconds."
                        exit 1
                    fi

					# Run the app container on port 5001 with MySQL connection
					sudo docker run -d \\
					  --network host \\
					  -p 5001:5001 \\
					  --name rise-app \\
					  --restart unless-stopped \\
                      -v /vagrant/files/buildservertest.pfx:/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Path=/app/certs/buildservertest.pfx \\
                      -e Kestrel__Certificates__Default__Password=admin \\
                      -e ASPNETCORE_URLS=https://+:5001 \\
					  rise-app

                    # Ensure node_exporter is running
                    if ! sudo docker ps -q -f name=node_exporter | grep -q .; then
                        sudo docker run -d --name node_exporter --network host --restart unless-stopped prom/node-exporter:latest
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