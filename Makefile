SHARD_BIN ?= ../../bin

shim:
	mkdir -p $(SHARD_BIN)
	rm -f $(SHARD_BIN)/lucky_vite_bin
	cp ./tasks/lucky_vite $(SHARD_BIN)
