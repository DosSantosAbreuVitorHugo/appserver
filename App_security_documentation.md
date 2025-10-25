# Application Security and Hardening Documentation

## Introduction

This document summarizes the recent security and hardening changes we've implemented in our CI/CD pipeline and deployment setup for the App Server (`192.168.56.122`). These steps are crucial for protecting our application and maintaining a secure environment.

***

## 1. Pipeline Security Gates

These checks happen before deployment to ensure our Docker image meets essential security standards.

| Implementation | Description | Security Benefit |
| :--- | :--- | :--- |
| **Vulnerability Scanning (Trivy)** | We've added an inline security scanner (Trivy) that runs immediately after the Docker image builds. | The pipeline now **fails** if the image contains any **CRITICAL** or **HIGH** severity vulnerabilities, blocking the deployment of high-risk code. |
| **Base Image Freshness** | The `docker build` now uses the `--no-cache` flag, forcing Docker to pull the newest base image layers every time. | Ensures we use the most recent, patched versions of Linux and .NET dependencies, drastically reducing exposure to known vulnerabilities. |

***

## 2. Deployment Environment Hardening

These changes secure the host machine and the application container itself.

### 2.1 PFX Certificate and Key Management

| Implementation | Description | Security Benefit |
| :--- | :--- | :--- |
| **Secure Key Path Cleanup** | The pipeline now uses a command (`sudo rm -f /vagrant/files/buildservertest.pfx`) to **remove the certificate** from the shared, network-accessible `/vagrant/files` directory after it's securely copied. | Prevents the private PFX key from being left in an insecure, easily accessible location, significantly improving key confidentiality. |
| **PFX Access Control** | We adjusted the mounted PFX certificate's file permissions to **`644`**. | Ensures the non-root user running the application can read the certificate, but **cannot modify or execute it**, which follows the principle of least privilege. |

### 2.2 Host and Container Logging

| Implementation | Description | Security Benefit |
| :--- | :--- | :--- |
| **Docker Log Rotation** | We've configured the Docker daemon (`/etc/docker/daemon.json`) to limit container log files to **10MB max size** and **3 files per container**. | This prevents a potential **Denial of Service (DoS)** scenario where a compromised or misbehaving application could flood the host system's disk with excessive log data, taking the host offline. |

***

## 3. Network Security (UFW Firewall)

We've locked down the App Server's network access using the **Uncomplicated Firewall (UFW)**.

| Implementation | Description | Security Benefit |
| :--- | :--- | :--- |
| **Default Deny Policy** | UFW is configured to **block all incoming traffic** by default, allowing only explicitly defined ports. | Drastically reduces the attack surface by closing all ports except those absolutely necessary for the app and monitoring. |
| **Restricted Monitoring Access (CRITICAL)** | The firewall rule for the Node Exporter was corrected and now strictly allows access **only** from the Monitoring Server's IP address. | **Port 9100:** Access is restricted to **`192.168.56.123`** (Monitoring Server). This prevents unauthorized actors from scraping performance metrics, which could be used for reconnaissance in an attack. |