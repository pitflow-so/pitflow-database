#!/usr/bin/env bash
set -Eeuo pipefail

# Terraform creates the RDS instance; this script runs immediately after apply
# because the AWS provider does not manage logical PostgreSQL roles/databases.
: "${PITFLOW_SECRET_ID:?PITFLOW_SECRET_ID is required}"
: "${PITFLOW_POSTGRES_HOST:?PITFLOW_POSTGRES_HOST is required}"
: "${PITFLOW_POSTGRES_PORT:=5432}"

secret_json="$(aws secretsmanager get-secret-value \
  --secret-id "${PITFLOW_SECRET_ID}" \
  --query SecretString \
  --output text)"

required_keys=(
  PITFLOW_OPERATION_DB_NAME PITFLOW_OPERATION_DB_USERNAME PITFLOW_OPERATION_DB_PASSWORD
  PITFLOW_INVENTORY_DB_NAME PITFLOW_INVENTORY_DB_USERNAME PITFLOW_INVENTORY_DB_PASSWORD
  PITFLOW_REGISTRY_DB_NAME PITFLOW_REGISTRY_DB_USERNAME PITFLOW_REGISTRY_DB_PASSWORD
  PITFLOW_PAYMENT_DB_NAME PITFLOW_PAYMENT_DB_USERNAME PITFLOW_PAYMENT_DB_PASSWORD
)

for key in "${required_keys[@]}"; do
  if ! jq -e --arg key "${key}" '.[$key] | type == "string" and length > 0' <<<"${secret_json}" >/dev/null; then
    printf 'Required key %s is missing or empty in secret %s\n' "${key}" "${PITFLOW_SECRET_ID}" >&2
    exit 1
  fi
done

value() {
  jq -r --arg key "$1" '.[$key]' <<<"${secret_json}"
}

operation_db="$(value PITFLOW_OPERATION_DB_NAME)"
operation_user="$(value PITFLOW_OPERATION_DB_USERNAME)"
operation_password="$(value PITFLOW_OPERATION_DB_PASSWORD)"
inventory_db="$(value PITFLOW_INVENTORY_DB_NAME)"
inventory_user="$(value PITFLOW_INVENTORY_DB_USERNAME)"
inventory_password="$(value PITFLOW_INVENTORY_DB_PASSWORD)"
registry_db="$(value PITFLOW_REGISTRY_DB_NAME)"
registry_user="$(value PITFLOW_REGISTRY_DB_USERNAME)"
registry_password="$(value PITFLOW_REGISTRY_DB_PASSWORD)"
payment_db="$(value PITFLOW_PAYMENT_DB_NAME)"
payment_user="$(value PITFLOW_PAYMENT_DB_USERNAME)"
payment_password="$(value PITFLOW_PAYMENT_DB_PASSWORD)"

# The operation credentials are also the RDS master credentials in this
# disposable lab environment. Keeping logical users outside Terraform prevents
# their passwords from being copied into Terraform state.
export PGPASSWORD="${operation_password}"

psql_base=(
  --host="${PITFLOW_POSTGRES_HOST}"
  --port="${PITFLOW_POSTGRES_PORT}"
  --username="${operation_user}"
  --dbname="postgres"
  --set=ON_ERROR_STOP=1
  --no-psqlrc
)

bootstrap_role_and_database() {
  local database_name="$1"
  local username="$2"
  local password="$3"

  psql "${psql_base[@]}" \
    --set=db_name="${database_name}" \
    --set=db_user="${username}" \
    --set=db_password="${password}" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN', :'db_user')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'db_user') \gexec

SELECT format('ALTER ROLE %I LOGIN PASSWORD %L', :'db_user', :'db_password') \gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', :'db_user')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db_name') \gexec

SELECT format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'db_user') \gexec
SELECT format('REVOKE ALL ON DATABASE %I FROM PUBLIC', :'db_name') \gexec
SELECT format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO %I', :'db_name', :'db_user') \gexec
SQL
}

bootstrap_role_and_database "${operation_db}" "${operation_user}" "${operation_password}"
bootstrap_role_and_database "${inventory_db}" "${inventory_user}" "${inventory_password}"
bootstrap_role_and_database "${registry_db}" "${registry_user}" "${registry_password}"
bootstrap_role_and_database "${payment_db}" "${payment_user}" "${payment_password}"

unset PGPASSWORD secret_json operation_password inventory_password registry_password payment_password
printf 'PostgreSQL logical databases and isolated login roles were reconciled successfully.\n'
