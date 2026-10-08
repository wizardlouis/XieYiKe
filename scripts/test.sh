#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
xcrun swiftc Sources/Countdown.swift Tests/main.swift -o .build/countdown-tests
.build/countdown-tests
