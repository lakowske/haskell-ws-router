#!/bin/bash

cabal update

cabal install

./dist/build/haskell-ws-router/haskell-ws-router
