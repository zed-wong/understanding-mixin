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
``` set up rpc server
`return node.Loop()` call node loop in `boot.go`.


Now it's the logic of `Loop()` in boot.go:


`rand.Seed(clock.Now().UnixNano())` set random seed.

`err := node.PingNeighborsFromConfig()` This function will ping all the GossipNeighbors set in the config file using Quic method.

`err := node.ListenNeighbors()` This function will create a Quic server, listen for Neighbors connection. Constantly update `gossipRound`, which is neighbor map.

`go node.LoopCacheQueue()` Looks like here is where main snapshot handling happens. Inside this function, it's a endless for loop, 




### Domain

### RPC

### Storage

### Custodian

### Utils