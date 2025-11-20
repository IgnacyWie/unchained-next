# --- Local Development ---
# Connects to localhost because the app runs on the host, DB runs in Docker
DATABASE_URL={{CONN_STRING_LOCAL}}

NEXTAUTH_URL={{NEXT_APP_URL}}
NEXTAUTH_SECRET={{NEXTAUTH_SECRET}}

# Connects to localhost forwarded port
EMAIL_SERVER_HOST={{EMAIL_HOST_LOCAL}}
EMAIL_SERVER_PORT=1025
EMAIL_SERVER_USER=none
EMAIL_SERVER_PASSWORD=none
EMAIL_FROM={{EMAIL_FROM}}
