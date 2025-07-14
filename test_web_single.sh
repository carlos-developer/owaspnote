#!/bin/bash

# Test single integration test on web

echo "Starting ChromeDriver..."
./chromedriver/linux-138.0.7204.94/chromedriver-linux64/chromedriver --port=4444 --silent &
CHROMEDRIVER_PID=$!
sleep 3

echo "Running auth_flow_test.dart..."
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  -d chrome \
  --web-port=8080 \
  --browser-name=chrome \
  --no-headless

echo "Killing ChromeDriver..."
kill $CHROMEDRIVER_PID 2>/dev/null