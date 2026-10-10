#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
xcrun swiftc Sources/Countdown.swift Tests/main.swift -o .build/countdown-tests
.build/countdown-tests
xcrun swiftc Sources/CountdownTextField.swift Tests/Rendering/main.swift -framework Cocoa -o .build/rendering-tests
.build/rendering-tests .build/rendering-checks
