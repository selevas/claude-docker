if (
  set -o pipefail
  podman build --build-arg CLAUDE_CODE_VERSION=2.1.301 -t claude-sandbox ./ 2>&1 | tee ./build.log
); then
  echo "Build OK"
else
  echo "Build FAILED — see build.log"
  tail -20 ./build.log
fi
