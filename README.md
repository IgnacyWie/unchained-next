# ⛓️‍💥 Unchained Next

**Break the SaaS shackles. Deploy Next.js on your own terms.**

[](https://opensource.org/licenses/MIT)
[](https://nextjs.org/)
[](https://turbo.build/)
[](https://www.prisma.io/)

**Unchained Next** is an open-source playbook and boilerplate designed to replace the "Vercel + Clerk + Neon" tax with a robust, self-hosted alternative. We provide configuration, manifests, and guides to run a modern full-stack app using industry-standard open-source tools.

---

## 🚀 Why Unchained?

The "Modern Stack" has become a subscription trap. You shouldn't have to pay per-user fees just to authenticate users or store rows in a database.

| Feature          | The "SaaS" Way (Vercel/Clerk/Neon) | The Unchained Way                    |
| :--------------- | :--------------------------------- | :----------------------------------- |
| **Hosting**      | Serverless Pricing (Unpredictable) | **Docker / K8s (Fixed Cost VPS)**    |
| **Auth**         | $ per Monthly Active User          | **NextAuth + Prisma (Free & Owned)** |
| **Database**     | Pricing based on compute hours     | **Standard PostgreSQL Container**    |
| **Architecture** | Scattered Microservices            | **Unified Monorepo (Turborepo)**     |
| **Cost**         | Scales with traffic ($$$)          | **Scales with hardware ($)**         |

---

## 🛠️ Stack & Architecture

We stripped away the complexity of external auth services in favor of a pure architecture that you own completely, organized via **Turborepo**.

- **Monorepo Tooling:** [Turborepo](https://turbo.build/)
- **Application:** [Next.js](https://nextjs.org/) (`apps/web`)
- **Authentication:** [NextAuth.js](https://next-auth.js.org/) with **Credentials Provider**
- **ORM:** [Prisma](https://www.prisma.io/) (`packages/db`)
- **Database:** [PostgreSQL](https://www.postgresql.org/)
- **Infrastructure:** Docker Compose (Local) & Helm / Kubernetes (Production)

### How it Works

1. User submits email/password to the Next.js API.
2. **NextAuth** verifies credentials against the database via **Prisma**.
3. Session tokens are issued without external dependencies.
4. All database schemas are managed centrally in `packages/db`.

---

## 📂 Project Structure

```text
unchained-next/
├── apps/
│   └── web/                  # The Main Next.js Application
├── packages/
│   ├── db/                   # Prisma Schema, Migrations & Client
│   ├── design-system/        # Shared UI Components
│   ├── eslint-config/        # Shared Linting Rules
│   └── typescript-config/    # Shared TS Configs
├── docker/                   # Docker related files
├── ops/
│   └── helm/                 # Helm Charts for Production Deployment
├── templates/                # Environment variable templates (.tpl)
├── setup-env.sh              # Script to generate .env files from templates
├── docker-compose.yml        # Local development
├── docker-compose.preprod.yml# Pre-production setup
├── LICENSE
├── package.json
├── pnpm-lock.yaml
├── pnpm-workspace.yaml
├── README.md
└── turbo.json
```

---

## ⚡ Quick Start (Local Development)

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ & **pnpm**

### 1. Clone the Repo

```bash
git clone https://github.com/yourusername/unchained-next.git
cd unchained-next
```

### 2. Generate Environment Files

```bash
chmod +x setup-env.sh
./setup-env.sh
```

This will generate `.env` files based on the templates in `templates/`.

### 3. Install Dependencies

```bash
pnpm install
```

### 4. Spin up Local Infrastructure

```bash
docker-compose up -d
```

### 5. Initialize Database

```bash
pnpm db:push
```

### 6. Run the App

```bash
pnpm dev
```

Visit `http://localhost:3000` to see your app.

---

## 🚢 Deploy to Kubernetes with Helm

For production, we use Helm charts stored in `ops/helm`.

```bash
cd ops/helm
helm install CHANGE_RELEASE_TAG ./unchained-web -f ./unchained-web/values.yaml
```

Replace `CHANGE_RELEASE_TAG` with your release name.

> Note: `values.yaml` are generated automatically with the help of the `/setup-env.sh` script

---

## 🗺️ Roadmap & Todos

### Authentication

- [ ] Integrate WebAuthn (Passkeys) in NextAuth.js

### Configuration & Standards

- [x] Standardize `IMAGE_NAME` across `.env` templates and Helm charts.

### Documentation

- [ ] Add documentation for creating `imagePullSecrets` in Kubernetes for private registries.
- [ ] Add documentation for creating ingress and cert-manager in Kubernetes.

### Automation (CI/CD)

- [x] GitHub Actions workflow for building, caching, and deploying Docker images.
- [ ] GitHub Actions workflow for automatically running `prisma db push` on production DB.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Open a Pull Request

---

## 📄 License

Distributed under the MIT License.

---

### 🌟 Star this repo if you want to break free from SaaS subscriptions
