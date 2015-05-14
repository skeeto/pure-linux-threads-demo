# Pure assembly, no pthreads, Linux threading demo

A demonstration of library-free threading in Linux with pure x86_64
assembly. Thread stacks are allocated with the `SYS_brk` syscall and
new threads are spawned with `SYS_clone` syscall. Synchronization is
achieved with the x86 `lock` instruction prefix.
