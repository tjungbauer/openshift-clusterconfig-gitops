#!/bin/bash
echo "Getting public key from Sealed Secrets secret and copying it to ~/.bitnami"
echo "Create dir for Sealed Secrets public key. (~/.bitnami)."
mkdir -m 700 -p ~/.bitnami
echo "Backup secret itself"
oc get $(oc get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name) -n sealed-secrets -o yaml >  ~/.bitnami/sealed-secrets-secret.yaml
echo "Get the public key from the Sealed Secrets secret."
keys=`oc get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name`
for i in $keys; do
  echo "Found $i"
  name=`echo "$i" | cut -d "/" -f 2`
  oc get $i -n sealed-secrets -o jsonpath='{.data.tls\.crt}' | base64 --decode > ~/.bitnami/$name-publickey.pem
done
