# Distributed Queue In D

This is a work queue, and potentially more, written in D.

# DESCRIPTION

This was created to solve the problem where we wish to submit tasks from a
client to a worker reliably.  The requirements are:

* Allow the user to set the size of the queue to an arbitrary value.
* When the queue is full, prevent new messages from being placed onto the
  queue.
* Do not drop any messages at any time.
  * No implicit removals, only explicit.
  * E.g. if the queue is full, don't remove messages from the queue.
* Replicate data to multiple machines so that no work is lost due to a queue
  dying.
  * The goal is to have no data loss unless all of the nodes are lost.
* The queue can work in an environment where requests are routed through a
  proxy.

The main goal is reliability with performance being secondary.  When
replication is implemented, no message will be placed onto the queue until it
has been replicated first.

# USAGE

    dqid --size=<size>

# DESIGN

The initial design is to create a work queue that can work in a distributed
fashion and can work well in an environment where the host can die
unexpectantly.  It does this by storing the queue in memory and replicated the
data across multiple machines.

Development will be done in phases.

## Phase 1 (AKA Get something working even if it's crap!)

* Implement REST interface for the following operations:
  * Submit a message
  * Retrieve a message
  * Get statistics about the queue

### Endpoints

    /push  - POST
    /get   - GET
    /stats - GET

## Phase 2 (Make it durable!)

Each node will contain the following:

1. The queue it is maintaining.
2. A copy of the queue from each node in the cluster.

This means that we can lose all but one node and still have all of the
messages that have been successfully submitted.  If a node crashes, the queue
will be preserved on the other nodes until a new instance is added to the
cluster.  The current thought is that if a node goes down, that node's queue
is not accessible until a replacement node is stood up.  This assumes that the
queue is running in an environment where if an instance goes down, a new
instance will be stood up.

## Phase 3

* Test, test, test...

## Future

* Logging
* Code cleanup
* Add support for non-HTTP Protocol.
