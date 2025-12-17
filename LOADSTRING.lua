-- One-liner loadstring for mobile executors
-- Copy this entire line and paste into your executor

-- PUBLIC REPO: Direct load (if repo is public)
loadstring(game:HttpGet("https://raw.githubusercontent.com/sora598/grow-a-garden-test/main/tests/mobile_test.lua"))()

-- OR LOCAL FILE: If files are in workspace
loadstring(readfile("tests/mobile_test.lua"))()
