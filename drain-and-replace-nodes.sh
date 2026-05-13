#!/bin/bash

if [ -z "$NODEFILE" ] || [ -z "$WORKLOAD_LABEL" ]; then
  echo "Example usage: NODEFILE=./mynodes.txt WORKLOAD_LABEL=training.kubeflow.org PROJECT_ID=<my Crusoe project id> $0"
  exit 1
fi

get_pod_count() {
  kubectl get pods \
    --all-namespaces \
    --field-selector "spec.nodeName=$node" \
    -o json \
    | jq --arg label "$WORKLOAD_LABEL" '[
        .items[]
        | select(
            (
              .metadata.labels // {}
              | keys
              | any(startswith($label))
            )
            and .status.phase != "Succeeded"
            and .status.phase != "Failed"
          )
      ] | length'
}

cordon_wait_drain_delete_node() {
  local node=$1
  local vm=$(echo "$node" | sed 's/\..*//')
  echo "Got $node and $vm"
  
  kubectl cordon $node

  while true; do
    podcount=$(get_pod_count)
    echo "Workload pods still running on $node: $podcount"
    if [ "$podcount" -eq 0 ]; then
      break
    fi
    sleep 60
  done

  kubectl drain $node --ignore-daemonsets

  echo "Node $node is drained, deleting $vm to trigger replacement"

  crusoe compute vms delete -y $vm --project-id $PROJECT_ID
  
}

for cmk_node in $(cat $NODEFILE);do cordon_wait_drain_delete_node $cmk_node & done

wait

echo "All nodes in $NODEFILE have been drained and deleted"

