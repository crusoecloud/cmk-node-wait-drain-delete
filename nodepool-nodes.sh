#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <nodepool-name>" >&2
  echo "Example: $0 my-h200-nodepool" >&2
  exit 1
fi

nodepool=$1

kubectl get nodes \
  -l "crusoe.ai/nodepool.name=$nodepool" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
