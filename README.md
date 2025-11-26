forge create \
  --rpc-url https://aeneid.storyrpc.io \
  --private-key $PRIVATE_KEY \
  script/LyricToken.s.sol:LyricTokenScript \
  --verify \
  --verifier blockscout \
  --verifier-url https://www.blockscout.com/api/