# Web Application Settings
web:
  replicaCount: 2
  image:
    # --- AUTO-GENERATED: Set to the Docker image name from the script ---
    repository: {{DOCKER_IMAGE_NAME}}
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 80
    targetPort: 3000
  env:
    nodeEnv: production

# Postgres Settings
postgres:
  image:
    repository: postgres
    tag: 15-alpine
  storage:
    size: 1Gi
  service:
    port: 5432

# Secrets (Sensitive Data)
# In production, consider using external-secrets or sealing these.
secrets:
  # --- AUTO-GENERATED: Database Credentials ---
  postgresUser: "{{DB_USER}}"
  postgresPassword: "{{DB_PASSWORD}}"
  postgresDb: "{{DB_NAME}}"
  nextAuthSecret: "{{NEXTAUTH_SECRET}}"
  # --- AUTO-GENERATED: NEXT_APP_URL is derived from the ingress host ---
  nextAuthUrl: "{{NEXT_APP_DOMAIN}}"

  aws:
    region: "us-east-1"
    smtpUser: ""
    smtpPass: ""

ingress:
  enabled: true # Set to true to create the Ingress resource
  # --- AUTO-GENERATED: External DNS name for your app ---
  host: {{INGRESS_HOST}} 
  tls:
    clusterIssuer: acme-issuer
