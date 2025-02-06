#!/usr/bin/env bash

for charts in $(find . -name 'Chart.yaml'); do
helm_dir=$(dirname "${charts}")
echo "Checking $helm_dir"
echo "Trying to find in-cluster-values.yaml files"
add_val_files=$(find $helm_dir -type f -name in-cluster-values.yaml)
if [ -z "$add_val_files" ]; then
    echo "No additional files found"
    values=""
else
    echo "Additional file found $add_val_files"
    values="-f $add_val_files"
fi

helm dep up "${helm_dir}"
helm lint --strict $values "${helm_dir}"
echo "Done"
done