pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image from the Dockerfile in this repo
                    sh '''
                        docker build -t testapp-image .
                    '''
                }
            }
        }

        stage('Transfer Image to Remote Server') {
            steps {
                sshagent(['ssh']) {
                    sh '''
                        # Save Docker image to a tarball
                        docker save testapp-image -o testapp-image.tar

                        # Copy the tarball to remote server
                        scp -o StrictHostKeyChecking=no testapp-image.tar vagrant@192.168.56.122:/tmp/
                    '''
                }
            }
        }

        stage('Provision and Run on Remote') {
            steps {
                sshagent(['ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no vagrant@192.168.56.122 "
                        set -e

                        # Install Docker if not present
                        if ! command -v docker &> /dev/null; then
                          sudo apt-get update -y
                          sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
                          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                          echo \\"deb [arch=\\\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \\\$(lsb_release -cs) stable\\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                          sudo apt-get update -y
                          sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                          sudo usermod -aG docker vagrant
                          sudo systemctl enable docker
                          sudo systemctl start docker
                        fi

                        # Load image and run container
                        docker load -i /tmp/testapp-image.tar || true
                        docker stop testapp || true
                        docker rm testapp || true
                        docker run -d --name testapp -p 80:80 \
                          -e DOTNET_ENVIRONMENT=\\"Development\\" \
                          -e DOTNET_ConnectionStrings__SqlDatabase=\\"Server=192.168.56.121;Port=3306;Database=mydatabase;User Id=root;Password=supersecretpassword;\\" \
                          --restart unless-stopped testapp-image

                        # Run node_exporter if not already
                        docker ps | grep node_exporter || docker run -d --name node_exporter --network host --restart unless-stopped prom/node-exporter:latest
                        "
                    '''
                }
            }
        }
    }
}
