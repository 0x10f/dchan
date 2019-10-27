# dchan

A decentralized imageboard framework

## Notice

With the upcoming changes coming with Istanbul the method of preallocating memory will become more costly than just writing new memory with the [EIP-2200](https://gist.github.com/karalabe/adc43c07db9f03be82093cd5466562b0), so effectively this project is dead in the water. We recommend you check out [0xChan](https://0xchan.net/) which is still under development as I am updating this README but will be released shortly. Thanks!

## Memory

All posts, and threads are pre-allocated and reused over the lifetime of the contract. This cuts 
down the cost it takes to write to the contract storage. There is an overhead with garbage collecting and logically organizing objects but they are overcome by packing objects to be at most a word in length and batching writes so that objects are only written once per call to the contract.

Coniderations were made to use a LRU cache to garbage collect threads. However, the expenses of managing a LRU cache were almost as much as the costs of just appending new data to the contract. The contract currently uses a FIFO queue to garbage collect stale threads.

## Gas Costs

### Allocate Posts

| Posts               | Gas Consumption     | Cost (USD ETH@$200) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Allocate Threads

| Threads             | Gas Consumption     | Cost (USD ETH@$200) |
|---------------------|---------------------|---------------------|
|                   1 |               53207 |            $0.01064 |
|                   2 |               73466 |            $0.01469 |

### Post (New Thread)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@$200) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Post (Existing Thread)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@$200) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |
