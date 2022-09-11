# Lua Promises and async/await functions

This is an experimental implementation of Promises and async/await pattern for Lua.

See `Promise-test.lua` and `AsyncAwait-test.lua` for usage examples.

The library is designed to mimic javascript behavior of the corresponding concepts.

In order to make use of Promises (and async functions) you will first need a Lua library
with asynchronous API based on callback concepts (for example, Node MCU).
The reference implementation of Lua does not have one.
