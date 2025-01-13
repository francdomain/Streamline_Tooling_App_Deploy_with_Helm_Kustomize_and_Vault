#!/bin/bash

# Set environment variables for DB credentials
export DB_USER="admin"
export DB_PASSWORD="password1234$"
export DB_NAME="tooling_db"

DB_HOST=$(terraform output -raw aurora_endpoint)

# Verify that the DB endpoint was fetched successfully
if [ -z "$DB_HOST" ]; then
  echo "Failed to fetch Aurora DB endpoint. Exiting."
  exit 1
fi
echo "Aurora DB endpoint fetched: $DB_HOST"

# Download tooling-db.sql from GitHub
GITHUB_REPO_URL="https://github.com/francdomain/tooling/raw/main/tooling-db.sql"
echo "Downloading tooling-db.sql from GitHub..."
curl -L -o /tmp/tooling-db.sql "$GITHUB_REPO_URL"
if [ $? -ne 0 ]; then
  echo "Error downloading tooling-db.sql. Exiting."
  exit 1
fi
echo "Downloaded tooling-db.sql successfully."
echo "$(ls /tmp)"

echo "Connecting to DB at $DB_HOST with user $DB_USER on database $DB_NAME"

# Import tooling.sql into Aurora database
echo "Loading tooling-db.sql into the Aurora database..."
mysql -h "$DB_HOST" -P 3306 -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < /tmp/tooling-db.sql
if [ $? -ne 0 ]; then
  echo "Error loading tooling-db.sql into the database. Exiting."
  exit 1
fi

# Cleanup downloaded file
rm -f /tmp/tooling-db.sql
echo "Database loaded successfully and temporary file cleaned up."