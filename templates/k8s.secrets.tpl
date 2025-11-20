apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # These values are injected as Base64 encoded strings
  POSTGRES_USER: {{B64_DB_USER}}
  POSTGRES_PASSWORD: {{B64_DB_PASSWORD}}
  POSTGRES_DB: {{B64_DB_NAME}}
  DATABASE_URL: {{B64_CONN_STRING_K8S}}
  NEXTAUTH_SECRET: {{B64_NEXTAUTH_SECRET}}
  NEXTAUTH_URL: {{B64_NEXT_APP_DOMAIN}}
  
  # Placeholders for AWS SES (Manual update required later)
  AWS_REGION: {{B64_AWS_REGION}}
  AWS_SMTP_USER: {{B64_AWS_USER}}
  AWS_SMTP_PASS: {{B64_AWS_PASS}}
