#!/usr/bin/env bash
# Helm + ArgoCD 배포용 스크립트
# CI/CD 환경에서 Terraform outputs를 values.yaml에 반영 후 Helm upgrade/install

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform"
HELM_DIR="$ROOT/helm/ticketing"

# Terraform outputs 읽기
DB_WRITER_HOST="$(terraform -chdir="$TF_DIR" output -raw rds_writer_endpoint)"
DB_READER_HOST="$(terraform -chdir="$TF_DIR" output -raw rds_reader_endpoint)"
REDIS_HOST="$(terraform -chdir="$TF_DIR" output -raw redis_endpoint)"
SQS_URL="$(terraform -chdir="$TF_DIR" output -raw sqs_queue_url)"
COGNITO_JSON="$(terraform -chdir="$TF_DIR" output -raw cognito_json)"
ECR_REGISTRY="$(terraform -chdir="$TF_DIR" output -raw ecr_registry)"

# DB_PASSWORD는 환경변수로 전달
if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "ERROR: DB_PASSWORD 환경변수를 설정하세요."
  exit 1
fi

# Helm values.yaml 동적 생성
VALUES_TMP="$(mktemp)"
trap 'rm -f "$VALUES_TMP"' EXIT

cat > "$VALUES_TMP" <<EOF
image:
  eventSvc:
    repository: ${ECR_REGISTRY}/ticketing/event-svc
    tag: latest
  reservSvc:
    repository: ${ECR_REGISTRY}/ticketing/reserv-svc
    tag: latest
  workerSvc:
    repository: ${ECR_REGISTRY}/ticketing/worker-svc
    tag: latest

database:
  writerHost: ${DB_WRITER_HOST}
  readerHost: ${DB_READER_HOST}
  username: root
  password: ${DB_PASSWORD}

redis:
  host: ${REDIS_HOST}

sqs:
  url: ${SQS_URL}

cognito:
  json: '${COGNITO_JSON}'
EOF

# Helm upgrade/install
helm upgrade --install ticketing "$HELM_DIR" \
  -f "$VALUES_TMP" \
  --namespace ticketing --create-namespace \
  --wait

echo "Helm 배포 완료."