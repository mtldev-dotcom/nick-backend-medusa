#!/bin/sh
set -e

echo "Running Medusa migrations..."
yarn medusa db:migrate

echo "Starting Medusa server..."
exec yarn start
