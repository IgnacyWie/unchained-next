# ⛓️‍💥 Unchained Next

**Break the SaaS shackles. Deploy Next.js on your own terms.**

[](https://opensource.org/licenses/MIT)
[](https://nextjs.org/)
[](https://www.docker.com/)
[](https://zitadel.com/)

**Unchained Next** is an open-source playbook and boilerplate designed to replace the "Vercel + Clerk + Neon" tax with a robust, self-hosted alternative. We provide the configuration, manifests, and guides to run a modern full-stack app using industry-standard open-source tools.

## 🚀 Why Unchained?

The "Modern Stack" has become a subscription trap. You shouldn't have to pay per-user fees just to authenticate users or store rows in a database.

| Feature      | The "SaaS" Way (Vercel/Clerk/Neon) | The Unchained Way                         |
| :----------- | :--------------------------------- | :---------------------------------------- |
| **Hosting**  | Serverless Pricing (Unpredictable) | **Docker / K8s (Fixed Cost VPS)**         |
| **Auth**     | $ per Monthly Active User          | **Unlimited Users (Self-hosted Zitadel)** |
| **Database** | Pricing based on compute hours     | **Standard PostgreSQL Container**         |
| **Data**     | Locked in proprietary clouds       | **100% Data Sovereignty**                 |
| **Cost**     | Scales with traffic ($$$)          | **Scales with hardware ($)**              |

## 🛠️ The Stack

- **Application:** [Next.js](https://nextjs.org/) (Containerized, standalone output)
- **Authentication:** [Zitadel](https://zitadel.com/) (Open source identity management - The Clerk alternative)
- **Database:** [PostgreSQL](https://www.postgresql.org/)
- **Reverse Proxy:** [Traefik](https://traefik.io/) or Nginx
- **Infrastructure:** Docker Compose (Local) & Kubernetes (Production)

## 📂 Project Structure

```text
unchained-next/
├── app/                 # The Next.js Application
├── ops/
│   ├── docker-compose/  # Local development setup
│   │   ├── docker-compose.yml
│   │   └── zitadel-init/
│   └── k8s/             # Kubernetes manifests / Helm charts
└── README.md
```

## ⚡ Quick Start (Local Development)

Get the entire stack running locally in minutes.

### Prerequisites

  * Docker & Docker Compose
  * Node.js 18+ (for local app development)

### 1\. Clone the repo

```bash
git clone https://github.com/yourusername/unchained-next.git
cd unchained-next
```

### 2\. Environment Setup

Copy the example environment variables.

```bash
cp .env.example .env
```

### 3\. Spin up the Infrastructure

This command starts Postgres and Zitadel.

```bash
cd ops/docker-compose
docker-compose up -d
```

_Note: Zitadel takes a moment to initialize the first time._

### 4\. Configure Next.js

Once Zitadel is running (usually `http://localhost:8080`), create an Instance, grab your `Client ID` and `Client Secret`, and update your root `.env` file.

### 5\. Run the App

```bash
cd ../../app
pnpm install
pnpm run dev
```

Your app is now running at `http://localhost:3000`, authenticated against your local Zitadel instance, backed by your local Postgres.

## 🚢 Production Deployment (Kubernetes)

We believe in **"Write once, deploy anywhere."**

Inside the `ops/k8s` folder, you will find standard manifests to deploy this stack to any Kubernetes provider (DigitalOcean, Hetzner, AWS EKS, or a home lab).

1. **Build** your Next.js Docker image.
2. **Push** to your registry.
3. **Apply** the manifests in `ops/k8s`.

_(Detailed K8s guide coming soon in the /docs folder)_

## 🤝 Contributing

We are building the ultimate "SaaS-Free" playbook. Contributions are welcome\!

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes.
4.  Open a Pull Request.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

-----

### 🌟 Star this repo if you want to break free from SaaS subscriptions\!
