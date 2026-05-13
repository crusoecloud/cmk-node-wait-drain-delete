# cmk-node-wait-drain-delete
For each node in a CMK nodepool, wait until workload pods have finished, drain other pods, then delete the node such that a fresh node is created in its place.
