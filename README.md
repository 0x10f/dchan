# dchan

A decentralized imageboard framework

## Memory

All posts, threads, and memory pages are pre-allocated and reused over the lifetime of the contract. This cuts 
down the cost it takes to write to the contract storage by 75\% (5,000 versus 20,0000 gas) in most cases. There 
is an overhead with garbage collecting and logically organizing objects, but they are overcome by packing objects
to be at most a word in length and batching writes so that objects are only written once per call to the contract. 

Threads are stored in a LRU (Least Recently Used) cache structure which allows for recycling to free resources
for new threads. 

## Gas Costs

### Allocate Memory

This chart was made with the assumption that each memory page holds 8 words (256 bytes) along with its required 
metadata.

| Pages               | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

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

### Post (Existing Thread, Single Page)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

### Post (Existing Thread, Two Pages)

| Post Length (Words) | Gas Consumption     | Cost (USD ETH@200$) |
|---------------------|---------------------|---------------------|
|                   1 |                   0 |                   0 |

## Potential Features

- Huffmans encoding: To allow for internalization (custom encoding trees), and compression of data to write more characters.