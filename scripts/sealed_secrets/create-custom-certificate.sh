#!/bin/bash
echo "Creating custom certificate for sealed secrets"

export PRIVATEKEY="custom-tls.key"
export PUBLICKEY="custom-tls.crt"
export NAMESPACE="sealed-secrets"
export SECRETNAME="customsecret"

openssl req -x509 -days 3650 -nodes -newkey rsa:4096 -keyout "$PRIVATEKEY" -out "$PUBLICKEY" -subj "/CN=sealed-secret/O=sealed-secret"

oc -n "$NAMESPACE" create secret tls "$SECRETNAME" --cert="$PUBLICKEY" --key="$PRIVATEKEY"
oc -n "$NAMESPACE" label secret "$SECRETNAME" sealedsecrets.bitnami.com/sealed-secrets-key=active

oc delete pod -l app.kubernetes.io/name=sealed-secrets -n "$NAMESPACE"
