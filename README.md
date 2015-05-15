# Pure assembly, library-free Linux threading demo

A demonstration of library-free, Pthreads-free threading in Linux with
pure x86_64 assembly. Thread stacks are allocated with the `SYS_mmap`
syscall and new threads are spawned with `SYS_clone` syscall.
Synchronization is achieved with the x86 `lock` instruction prefix.

* [Raw Linux Threads via System Calls](http://nullprogram.com/blog/2015/05/15/)
