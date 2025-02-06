#!/usr/bin/env bash
for charts in `find . -name 'Chart.yaml' -type f | xargs -I{} dirname {}`; do
  printf "\n\n##### CHECKING $charts #####\n";
  ct lint --charts $charts;
done