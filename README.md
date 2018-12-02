# ActiveProxy

## Assumptions
- The application process can only run one active node at a time.
- All nodes are running already running the application process.
- The application process only writes when receiving requests.

## Automatically Detecting When to Fail-over
TODO

## Fail-over Process
1. Pause in flight requests incoming to proxy
1. Wait the sync timeout to make sure nodes caught up
1. Send SIGTERM to active node to flush
1. Kill active node's sync
1. Treat inactive as active, route the requests to it
1. Configure tail node to sync to what was originally the active node
1. Enqueue previous active node to the upstream hosts
1. Finished
