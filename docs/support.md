# Currents Support & Maintenance Policy

## Introduction

This document outlines Currents’ support and maintenance policy for customers deploying Currents in self-managed (on-premises) environments. It clearly defines our responsibilities, delineates the components we fully support, and sets expectations for areas where support is advisory or out of scope.

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
  - Index settings
  - Query settings and performance
- **Redis**:
  - Cache keys and content
  - LUA scripts
  - Associated application code

- **K8S configuration**:
  - Service definitions
  - Inter-service communication

> 🛠 For issues related to core components, please follow the “Troubleshooting” section.

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
  - Provisioning access and capacity
  - Data encryption

- **Database Infrastructure**:
  - Resource allocation
  - Clustering and scaling
  - Backups and recovery

- **Secrets management**:
  - Secrets encryption and provisioning
  - Creating, syncing, or rotating secrets as needed

- **Network Configuration**:
  - Connectivity between services
  - Ingress/Egress configuration

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

## Troubleshooting

To ensure efficient issues resolution customer must provide certain technical information. We understand that some issues are complex in their nature and can be difficult to reproduce in a standalone form, however we expect customer representative to collaborate with our support team to gather as much information as possible in a timely manner.

- Detailed logs
- A standalone example and reproduction steps
- Timely responses during the troubleshooting process
- Full breakdown of involved system setups:
  - Versions
  - Configuration files
- It is **recommended** to use a shared external logging provider (e.g., Coralogix) for log access
- Feature requests are subject to our internal roadmap and will be prioritized based on availability, unless agreed otherwise in writing
- Support hours and SLA terms are governed by the customer’s signed contract


Failure to provide complete information or delayed responses may impact our ability to resolve issues effectively.
