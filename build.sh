podman build --build-arg CLAUDE_CODE_VERSION=2.1.240 -t claude-sandbox ./ >./build.log 2>&1 &&
  echo "Build OK" ||
  {
    echo "Build FAILED — see build.log"
    tail -20 ./build.log
  }
