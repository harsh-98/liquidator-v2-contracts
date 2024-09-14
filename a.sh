#!/bin/sh

# array=('Liquidator')
array=('Liquidator' 'PriceHelper' 'AaveFLTaker' 'GhoFMTaker' 'GhoLiquidator')
for i in ${array[@]};
do
  cd ~/BACKUP/gearbox/liquidator-v2-contracts
  mkdir -p ~/BACKUP/gearbox/liquidator-v3/contracts/$i
  jq .abi forge-out/$i.sol/$i.json  > ~/BACKUP/gearbox/liquidator-v3/contracts/$i/a.abi
  jq .bytecode.object forge-out/$i.sol/$i.json | sed 's/"//g' > ~/BACKUP/gearbox/liquidator-v3/contracts/$i/a.bin
  cd ~/BACKUP/gearbox/liquidator-v3/contracts/$i
  abigen --bin=a.bin --abi=a.abi --pkg=$i --out=$i.go
done