# cmk-node-wait-drain-delete
For each node in a list of CMK nodepool nodes, wait until targeted workload pods have finished, drain non-workload pods, then delete the node such that a fresh node is created in its place. drain-and-replace-nodes.sh drains and deletes nodes listed in mynodes.txt ** in parallel ** to save time.

## Usage
1. Ensure you have kubectl installed with its context set to your target cluster
2. Ensure that Crusoe CLI is configured and working, with admin rights for your target project
3. Create file(s) containing lists of node names - one complete node name, as shown by `kubectl get nodes`, per line. This script lists the node names of the specified nodepool:
```
./nodepool-nodes.sh mynodepoolname | tee mynodes.txt
```
4. (Optional) To maintain overall availability of the nodepool, you might want to break mynodes.txt down into a number of smaller files, so that only a certain percentage of nodes are being deleted and recreated at any one time.
5. Run drain-and-replace-nodes.sh:
```
NODEFILE=./mynodes.txt
WORKLOAD_LABEL=training.kubeflow.org
PROJECT_ID=6b60dd75-ea5f-4fae-81b8-12bbe3049e2a
./drain-and-replace-nodes.sh
```
The script launches a background process for each node listed in NODEFILE. Each process:
  - Cordons its target node
  - Checks every minute until no more workload pods (as targeted by WORKLOAD_LABEL) are running on that node
  - Drains other non-daemonset pods from the nodes
  - Deletes the node, then finishes.
Subsequently, and outside of the script's scope, Crusoe Managed Kubernetes will automatically create a new node, with a new name, to replace the deleted node.  

Keep a copy of the original output of nodepool-nodes.sh and use the same script later on to determine when none of the original node names exists any more (at which point the cycling of the entire nodepool is complete)