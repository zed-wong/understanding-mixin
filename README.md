# Understanding Mixin

This is an overview of the Mixin Source code (https://github.com/MixinNetwork/mixin). Based on version 0.15.

## Table of contents

- Kernel
- Domain
- RPC
- Storage
- Custodian
- Utils...

### Kernel

Let's start from the kernel. The kernel code starts in `kernelCmd` defined in line 542 of the `main.go`:

`runtime.GOMAXPROCS(runtime.NumCPU())` sets the maximum number of CPUs that can be executing simultaneously.

`custom, err := config.Initialize(c.String("dir") + "/config.toml")` initialize config file.

`cache, err := newCache(custom)` create new cache.

`store, err := storage.NewBadgerStore(custom, c.String("dir"))` create badger storage.

`node, err := kernel.SetupNode(custom, store, cache, addr, c.String("dir"))` setup node.

```go
go func() {
		server := rpc.NewServer(custom, store, node, c.Int("port")+1000)
		err := server.ListenAndServe()
}
# set up rpc server
``` 
`return node.Loop()` call node loop in `boot.go`.


Now it's the logic of `Loop()` in boot.go:


`rand.Seed(clock.Now().UnixNano())` set random seed.

`err := node.PingNeighborsFromConfig()` This function will ping all the GossipNeighbors set in the config file using Quic method.

`err := node.ListenNeighbors()` This function will create a Quic server, listen for Neighbors connection. Constantly update `gossipRound`, which is neighbor map.

`go node.LoopCacheQueue()` Looks like here is where main snapshot handling happens. Inside this function, it's a endless for loop.

Inside this function, it would call `node.QueueState()` to update cache. It's like keep refreshing the list of active nodes. 

Then, `node.persistStore.CacheRetrieveTransactions(100)` gets 100 transactions, gets each one's hash, filter stale ones, and validate them all. The validation process is consists of these steps:

1. `txType := tx.TransactionType()` get transaction type. The transaction type could be:

- In
  - TransactionTypeMint
  - TransactionTypeDeposit
  - TransactionTypeUnknown
- Out
  - TransactionTypeWithdrawalSubmit
  - TransactionTypeWithdrawalFuel
  - TransactionTypeWithdrawalClaim
  - TransactionTypeNodePledge
  - TransactionTypeNodeAccept
  - TransactionTypeNodeRemove
  - TransactionTypeDomainAccept
  - TransactionTypeDomainRemove
  - TransactionTypeNodeCancel
  - TransactionTypeScript

2. `if tx.Version < TxVersionReferences && len(tx.References) > 0 { panic(tx.Version) }`  Check transaction version.

3. `if ver.Version < TxVersionCommonEncoding {return ver.validateV1(store, fork) }` Verify version 1 transaction. We would skip the details of verifying version 1 tx here. The core logic is inside `v1.go`.

4. `if ver.Version != TxVersionReferences && ver.Version != TxVersionBlake3Hash && ver.Version != TxVersionCommonEncoding ` Filter all the transactions except these 3 types.

5. `if txType == TransactionTypeUnknown ` filter TransactionTypeUnknown.

6. `if len(tx.Inputs) < 1 || len(tx.Outputs) < 1 ` filter low input and output.

7. `if len(tx.Inputs) > SliceCountLimit || len(tx.Outputs) > SliceCountLimit || len(tx.References) > SliceCountLimit ` filter inputs, outputs and references too large (>256).

8. `if len(tx.Extra) > tx.getExtraLimit()` filter too large `Extra`. The `getExtraLimit()` would determine if this transaction carries XIN to buy more `extra` places. And determine the `extra` size by the amount of XIN the transaction carries. The price is `0.001 XIN / extra 1024 spaces` The transaction must satisfy:
- tx.Asset = XINAssetId
- len(tx.Outputs) > 1
- len(tx.Outputs[0].Keys) = 1
- tx.Outputs[0].Type = OutputTypeScript
- tx.Outputs[0].Script.String() = "fffe40"
- Xin amount < 0.001 * 1024 * 4 = 4.096

9. `if len(msg) > config.TransactionMaximumSize` filter too large overall transaction size.

10. `validateReferences(store, tx)` validates UTXO references. Still not sure about what `reference` mean here.

11. `inputsFilter, inputAmount, err := validateInputs(store, tx, msg, ver.PayloadHash(), txType, fork)` This step validates UTXO inputs. 
- 


### Domain

### RPC

### Storage

### Custodian

### Utils