# dchan

A decentralized imageboard framework

## IPFS

## Memory

All posts, and threads are pre-allocated and reused over the lifetime of the contract. This cuts 
down the cost it takes to write to the contract storage. There is an overhead with garbage collecting and logically organizing objects but they are overcome by packing objects to be at most a word in length and batching writes so that objects are only written once per call to the contract.

## Gas Costs

### Allocate Posts

| Posts               | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Allocate Threads

| Threads             | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Post (New Thread)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Post (Existing Thread)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |
