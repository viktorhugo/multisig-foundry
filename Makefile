# exec make

-include .env

build:
	forge build -vvvv;

deploy-testnet-ganache:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL_GANACHE) --broadcast --account defaultKeyGanache --sender $(ADDRESS_SENDER_GANACHE) -vvvv

deploy-testnet-anvil:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL_ANVIL) --private-key $(PRIVATE_KEY_ANVIL)  --broadcast -vvvv

deploy-testnet-celo:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL_CELO) --account wallet-celo-test  --broadcast -vvvv

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


# Clean the repo
clean  :; forge clean

# Update Dependencies
update:; forge update

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1