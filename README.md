# ⛓️‍💥 Unchained Next

**Break the SaaS shackles. Deploy Next.js on your own terms.**

[](https://opensource.org/licenses/MIT)
[](https://nextjs.org/)
[](https://turbo.build/)
[](https://www.prisma.io/)

**Unchained Next** is an open-source playbook and boilerplate designed to replace the "Vercel + Clerk + Neon" tax with a robust, self-hosted alternative. We provide the configuration, manifests, and guides to run a modern full-stack app using industry-standard open-source tools.

## 🚀 Why Unchained?

The "Modern Stack" has become a subscription trap. You shouldn't have to pay per-user fees just to authenticate users or store rows in a database.

| Feature          | The "SaaS" Way (Vercel/Clerk/Neon) | The Unchained Way                    |
| :--------------- | :--------------------------------- | :----------------------------------- |
| **Hosting**      | Serverless Pricing (Unpredictable) | **Docker / K8s (Fixed Cost VPS)**    |
| **Auth**         | $ per Monthly Active User          | **NextAuth + Prisma (Free & Owned)** |
| **Database**     | Pricing based on compute hours     | **Standard PostgreSQL Container**    |
| **Architecture** | Scattered Microservices            | **Unified Monorepo (Turborepo)**     |
| **Cost**         | Scales with traffic ($$$)          | **Scales with hardware ($)**         |

## 🛠️ The Stack & Architecture

We stripped away the complexity of external auth services in favor of a pure architecture that you own completely, organized via **Turborepo**.

- **Monorepo Tooling:** [Turborepo](https://turbo.build/) (High-performance build system).
- **Application:** [Next.js](https://nextjs.org/) (Located in `apps/web`).
- **Authentication:** [NextAuth.js](https://next-auth.js.org/) with **Credentials Provider**.
- **ORM:** [Prisma](https://www.prisma.io/) (Located in `packages/db`).
- **Database:** [PostgreSQL](https://www.postgresql.org/).
- **Infrastructure:** Docker Compose (Local) & Kubernetes (Production).

### How it works

Instead of redirecting users to a third-party login page, **Unchained Next** handles auth internally:

1. User submits email/password to the Next.js API.
2. **NextAuth** verifies credentials against the database via **Prisma**.
3. Session tokens are issued without external dependencies.
4. All database schemas are managed centrally in `packages/db`.

## 📂 Project Structure

```text
unchained-next/
├── apps/
│   └── web/                  # The Main Next.js Application
├── packages/
│   ├── db/                   # Prisma Schema, Migrations & Client
│   ├── design-system/        # Shared UI Components
│   ├── eslint-config/        # Shared Linting rules
│   └── typescript-config/    # Shared TS Configs
├── ops/
│   └── k8s/                  # Kubernetes manifests
├── templates/                # Environment variable templates (.tpl)
├── setup-env.sh              # Script to generate .env files from templates
├── docker-compose.yml        # Local development setup
└── turbo.json                # Turborepo configuration
```

## ⚡ Quick Start (Local Development)

Get the entire stack running locally in minutes.

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ & **pnpm**

### 1\. Clone the repo

```bash
git clone https://github.com/yourusername/unchained-next.git
cd unchained-next
```

### 2\. Environment Setup

We use a script to generate `.env` files from the `templates/` directory to ensure consistency across the monorepo.

```bash
chmod +x setup-env.sh
./setup-env.sh
```

### 3\. Install Dependencies

```bash
pnpm install
```

### 4\. Spin up the Infrastructure

Start the PostgreSQL container (defined in `docker-compose.yml`).

```bash
docker-compose up -d
```

### 5\. Initialize Database

Push the Prisma schema from `packages/db` to your local Postgres instance.

```bash
# Run the db push script defined in package.json
pnpm db:push
```

### 6\. Run the App

```bash
pnpm dev
```

Your app is now running at `http://localhost:3000`.

---

## 🗺️ Roadmap & Todos

We are actively working on standardizing the deployment pipeline. Help is welcome\!

### Configuration & Standards

- [ ] **Standardize `IMAGE_NAME`:** Update `.env` templates and `k8s` manifests to use a consistent variable for the Docker image name/tag to prevent mismatches during build/deploy.

### Documentation

- [ ] **K8s Registry Auth:** Add documentation/templates for creating `imagePullSecrets` (Docker Login) within the Kubernetes cluster (for private registries).
- [ ] **Secret Management:** Add a guide on mapping generated `.env` files to Kubernetes Secrets.

### Automation (CI/CD)

- [ ] **GitHub Actions:** Create a standard workflow (`.github/workflows/deploy.yml`) that:
  1. Builds the Next.js Docker image (using Turbo cache).
  2. Pushes to GHCR or Docker Hub.
  3. Triggers a rollout restart on the Kubernetes cluster.

## 🚢 Production Deployment (Kubernetes)

We believe in **"Write once, deploy anywhere."**

Inside `ops/k8s`, you will find standard manifests to deploy this stack to any Kubernetes provider.

1. **Build** your application image.
2. **Push** to your registry.
3. **Apply** the manifests in `ops/k8s`.
   _(Tip: Use the templates in `templates/k8s._.tpl` to generate your production configs)\*

## 🤝 Contributing

We are building the ultimate "SaaS-Free" playbook. Contributions are welcome\!

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes.
4. Open a Pull Request.

## 📄 License

Distributed under the MIT License.

---

### 🌟 Star this repo if you want to break free from SaaS subscriptions\
