# S3 CLI Tool Deployment

A Kubernetes deployment with MinIO Client (`mc`) for searching and listing S3 buckets.

## Features

- List all S3 buckets
- List objects in a bucket
- Get bucket info and stats
- Works with AWS S3, MinIO, and any S3-compatible storage

## Quick Start

### 1. Update Credentials

Edit the Secret in `deployment.yaml` with your S3 credentials:

```yaml
stringData:
  AWS_ACCESS_KEY_ID: "your-access-key"
  AWS_SECRET_ACCESS_KEY: "your-secret-key"
  S3_ENDPOINT: "https://s3.amazonaws.com"  # Or your endpoint
```

For **OpenShift Data Foundation (ODF)**, use:
```yaml
S3_ENDPOINT: "https://s3.openshift-storage.svc:443"
```

For **MinIO**, use:
```yaml
S3_ENDPOINT: "http://minio.minio-namespace.svc:9000"
```

### 2. Deploy

```bash
oc apply -f deployment.yaml
```

### 3. Connect to the Pod

```bash
# Get the pod name
oc get pods -n s3-tools

# Exec into the pod
oc exec -it -n s3-tools deploy/s3-cli-tool -- /bin/sh
```

## Usage

### Using the provided scripts:

```bash
# List all buckets
/scripts/list-buckets.sh

# List objects in a bucket
/scripts/list-objects.sh my-bucket

# List objects with a prefix
/scripts/list-objects.sh my-bucket logs/2024/

# Get bucket info
/scripts/bucket-info.sh my-bucket
```

### Using `mc` directly:

```bash
# Set up the alias (done automatically by scripts)
mc alias set s3 $S3_ENDPOINT $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY

# List buckets
mc ls s3/

# List objects
mc ls s3/my-bucket/

# List recursively
mc ls --recursive s3/my-bucket/

# Find files by pattern
mc find s3/my-bucket --name "*.log"

# Get disk usage
mc du s3/my-bucket/

# Copy a file
mc cp s3/my-bucket/file.txt /tmp/

# Mirror a bucket
mc mirror s3/my-bucket/ /tmp/backup/
```

## Example Output

```
=== Listing S3 Buckets ===
[2024-01-15 10:30:00 UTC]     0B loki-chunks/
[2024-01-15 10:30:00 UTC]     0B tempo-traces/
[2024-01-15 10:30:00 UTC]     0B backups/

=== Bucket Info: loki-chunks ===
--- Disk Usage ---
1.2GiB  1234 objects  s3/loki-chunks/

--- Object Count ---
1234
```

## Using with SealedSecrets

For production, use SealedSecrets instead of plain Secrets:

```bash
# Create a sealed secret
echo -n 'your-access-key' | oc create secret generic s3-credentials \
  --namespace=s3-tools \
  --from-literal=AWS_ACCESS_KEY_ID=your-access-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret-key \
  --from-literal=S3_ENDPOINT=https://s3.amazonaws.com \
  --dry-run=client -o yaml | kubeseal -o yaml > sealed-secret.yaml
```

## Cleanup

```bash
oc delete -f deployment.yaml
```
