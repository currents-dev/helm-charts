# Currents Support & Maintenance Policy

## Introduction

This document outlines the support and maintenance policy for Currents. It is intended for customers deploying Currents in self-managed (on-prem) environments. The goal is to clearly define our responsibilities, provide guidance on components we support directly, and set expectations for areas where support is advisory or excluded.

This document may be shared with customers and incorporated into future support material and onboarding guides.

---

## System Components & Support Scope

Currents components fall into three categories:

1. **Core (Fully Supported)**
2. **Advisory Support**
3. **Excluded (No Support)**

---

### 1. Core Components (Fully Supported)

Once Currents is deployed and the correct setup is confirmed, Currents is responsible for the reliable and performant operation of the core services. This includes:

- **Currents services running within the Kubernetes (K8S) cluster**
- **Helm chart** configuration, parameters, and definitions
- **Database configuration**:
  - Indexes and query performance
  - Data integrity and settings (e.g., backups, rollover policies)
- **Redis configuration**:
  - Cache keys and content
  - LUA scripts
  - Associated application code
- **Storage configuration**:
  - Encryption
  - Read/write access
  - Secrets management
- **K8S configuration**:
  - Service definitions
  - Inter-service communication

> 🛠 For issues related to core components, please create a support ticket following the “Troubleshooting” section.

---

### 2. Advisory Support (Customer-Managed)

Currents will provide **recommendations and minimal examples** for components in this category, but direct support is limited. These components are considered external to Currents' internal systems and fall under customer responsibility.

- **K8S Management Layer**:
  - Scaling settings
  - Load balancer setup
  - Certificate management
  - Permissions
  - Access from/to external services

- **Storage Infrastructure** (e.g., S3 buckets)

- **Database Infrastructure**:
  - Resource allocation
  - Clustering and scaling

- **Network Configuration**:
  - Connectivity between services

- **Instrumentation & Monitoring**:
  - Currents can provide example metrics for performance and health
  - Customers are responsible for setting up monitoring, alerting, and incident response
  - Currents can offer ad-hoc consultation as needed

- **Infrastructure Versions**:
  - Minimum viable versions will be provided for required components

---

### 3. Excluded Components (No Support)

Currents does **not** provide support for the following:

- Infrastructure component upgrades (e.g., DB engine upgrades, OS updates)
- Network configuration and external service management
- Provisioning access to the system
- Infrastructure availability and uptime

---

## Maintenance Responsibilities

### Service Upgrades

- Currents will publish updated Docker images and Helm charts
- A changelog and upgrade instructions/tools will be included
- Customers are responsible for applying upgrades at their discretion
- Currents is available for support in case of upgrade issues, within the defined support perimeter

### Data Migration

- If data migration is needed, Currents will supply instructions and tooling
- Execution and validation are the customer’s responsibility

### Infrastructure Maintenance

- OS, network, and storage infrastructure are fully customer-managed

---

## Troubleshooting Expectations

To ensure efficient issue resolution, the following are required when submitting a support ticket:

- Detailed logs
- A standalone reproduction of the issue
- Timely responses during the troubleshooting process
- Full breakdown of involved system setups:
  - Versions
  - Configuration files
- It is **strongly recommended** to use a shared external logging provider (e.g., Coralogix) for log access
- Incomplete information or lack of response may result in the ticket being closed
- Feature requests are subject to our internal roadmap and will be prioritized based on availability, unless agreed otherwise in writing
- Support hours and SLA terms are governed by the customer’s signed contract