Bitcoin Voyager
===============

A Websocket and REST server for querying [Libbitcoin Server](https://github.com/libbitcoin/libbitcoin-server). It is written in Elixir using the Cowboy HTTP Server and connects to Libbitcoin Server via a ZeroMQ C-Port process pool.

### Configuration

All configuration takes place in the `config/config.exs` file. You must supply the libbitcoin server URI and optionally a heartbeat, block, and transaction subscription URIs. If a subscription URI is given then a single supervised connection will be automatically started for each available endpoint.

```elixir
config :bitcoin_voyager,
  port: 9090,
  bind: '127.0.0.1',
  uri: "tcp://voyager-api.cancoin.co:9091",
  heartbeat_uri: "tcp://voyager-api.cancoin.co:9092",
  block_uri: "tcp://voyager-api.cancoin.co:9093",
  transaction_uri: "tcp://voyager-api.cancoin.co:9094",
  pool: [size: 4],
  pidfile: "/tmp/bitcoin_voyager.pid"
```


### Getting Started
You must install Erlang R18+ and Elixir 1.2.0+

You must install also libbitcoin 3.0 and include it in your `LD_LIBRARY_PATH` when running. See [libbitcoin-nif](https://github.com/cancoin/libbitcoin-nif) for more info.


```bash
wget https://raw.githubusercontent.com/libbitcoin/libbitcoin/master/install.sh
bash install.sh --prefix=/usr/local/libbitcoin-master
mix deps.get
LD_LIBRARY_PATH=/usr/local/libbitcoin-master/lib mix test
```

### Building a Release

To make a release run the following commands

```bash
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
LD_LIBRARY_PATH=/usr/local/libbitcoin-master/lib ./rel/bitcoin_voyager/bin/bitcoin_voyager start
./rel/bitcoin_voyager/bin/bitcoin_voyager stop
```



## REST API

All requests are over standard HTTP with no rate limiting and api keys required.

```bash
➜ curl https://voyager.cancoin.co/api/v1/blockchain/last_height
{"height":418101}
```

## Websocket API

The websocket api uses a serialization format simmilar to libbitcoin server ZMQ requests. All requests must contain a semi-random unique ID, a command, and a set of parameters for the command.


Example querying for the latest known block height from javascript:

```js
function id() {
  return Math.floor(Math.random() * 4294967296)
}

var websocket = new WebSocket("wss://voyager.cancoin.co/api/v1/websocket")

websocket.onmessage = function(event) {
  var message = JSON.parse(event.data)
  console.log(message.result)
}

websocket.onopen = function(event) {
  var request = JSON.stringify({
    id: id(),
    command: "blockchain.last_height",
    params: {}
  })
  
  websocket.send(request)
}


```

The response will include the ID that was sent with the request along with an `result` or an `error` value.

```
{id: id(), error: <string>}
{id: id(), result: <object>}

```


## Commands

### Last Height

WebSocket Message:

```js
{
   id: id(),
   command: "blockchain.last_height",
   params: {}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/last\_height](https://voyager.cancoin.co/api/v1/blockchain/last_height)

```json
{"height":417983}
```

### Block Height

WebSocket Message:

```js
{
   id: id(),
   command: "blockchain.block_height",
   params: {hash: "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/block\_height/\<hash>](https://voyager.cancoin.co/api/v1/blockchain/block_height/000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3)

```json
{"height":205296}
```

### Block Header

WebSocket Message:

```js
{
   id: id(),
   command: "blockchain.block_header",
   params: {height: 170}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/block\_header/\<height>](https://voyager.cancoin.co/api/v1/blockchain/block_header/170)


```json
{
	"block_header": {
		"bits": 486604799,
		"hash": "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee",
		"merkle": "7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff",
		"nonce": 1889418792,
		"previous_block_hash": "000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55",
		"size": 81,
		"timestamp": 1231731025,
		"version": 1
	}
}
```

### Block Transaction Hashes


WebSocket Message:

```js
{
  id: id(),
  command: "blockchain.block_transaction_hashes",
  params: {hash: "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"}
}
```

REST Request: 
[http://localhost:9090/api/v1/blockchain/block\_transaction\_hashes/\<hash>](https://voyager.cancoin.co/api/v1/blockchain/block_transaction_hashes/00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee)

```json
{
	"transactions": [
	  "b1fea52486ce0c62bb442b530a3f0132b826c74e473d1f2c220bfa78111c5082",
	  "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"
	]
}
```

### Blockchain Transaction


WebSocket Message:

```js
{
  id: id(),
  command: "blockchain.transaction",
  params: {hash: "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/transaction/\<txid>](https://voyager.cancoin.co/api/v1/blockchain/transaction/f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16)

```json
{
	"transaction": {
		"coinbase": false,
		"hash": "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16",
		"inputs": [{
			"previous_output": {
				"hash": "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9",
				"index": 0
			},
			"script": "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901",
			"script_asm": "[ 304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901 ]",
			"sequence": 4294967295
		}],
		"locktime": 0,
		"outputs": [{
			"address": "1Q2TWHE3GMdB6BZKafqwxXtWAWgFt5Jvm3",
			"script": "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac",
			"script_asm": "[ 04ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84c ] checksig",
			"size": 76,
			"value": 1000000000
		}, {
			"address": "12cbQLTFMXRnSzktFkuoG3eHoMeFtpTu3S",
			"script": "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
			"script_asm": "[ 0411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3 ] checksig",
			"size": 76,
			"value": 4000000000
		}],
		"size": 275,
		"value": 5000000000,
		"version": 1
	}
}
```

### Transaction Pool Transaction


WebSocket Message:

```js
{
  id: id(),
  command: "transaction_pool.transaction",
  params: {hash: "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"}
}
```

REST Request:
[http://localhost:9090/api/v1/transaction\_pool/transaction/\<txid>](https://voyager.cancoin.co/api/v1/transaction_pool/transaction/f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16)


```json
{
	"transaction": {
		"coinbase": false,
		"hash": "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16",
		"inputs": [{
			"previous_output": {
				"hash": "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9",
				"index": 0
			},
			"script": "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901",
			"script_asm": "[ 304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901 ]",
			"sequence": 4294967295
		}],
		"locktime": 0,
		"outputs": [{
			"address": "1Q2TWHE3GMdB6BZKafqwxXtWAWgFt5Jvm3",
			"script": "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac",
			"script_asm": "[ 04ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84c ] checksig",
			"size": 76,
			"value": 1000000000
		}, {
			"address": "12cbQLTFMXRnSzktFkuoG3eHoMeFtpTu3S",
			"script": "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
			"script_asm": "[ 0411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3 ] checksig",
			"size": 76,
			"value": 4000000000
		}],
		"size": 275,
		"value": 5000000000,
		"version": 1
	}
}
```

### Transaction Index


WebSocket Message:

```js
{
   id: id(),
   command: "blockchain.transaction_index",
   params: {hash: "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/transaction\_index/\<txid>](https://voyager.cancoin.co/api/v1/blockchain/transaction_index/f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16)

```json
{"height":170,"index":1}
```

### Spend Transaction Index


WebSocket Message:

```js
{
  id: id(),
  command: "blockchain.spend",
  params: {hash: "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16", index: 1}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/spend/\<txid>/\<vout>](
    https://voyager.cancoin.co/api/v1/blockchain/spend/f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16/1)
    
```json
{"hash":"a16f3ce4dd5deb92d98ef5cf8afeaf0775ebca408f708b2146c4fb42b41e14be","index":0}
```

### Address History

WebSocket Message:

```js
{
  id: id(),
  command: "address.history",
  params: {address: "1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn", height: 0}
}
```

REST Request:
[http://localhost:9090/api/v1/address/history/\<address>/\<from\_height>](https://voyager.cancoin.co/api/v1/address/history/1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn/0)


```json
{
	"history": [{
		"output_hash": "fff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4",
		"output_height": 100000,
		"output_index": 0,
		"spend_hash": "5aa8e36f9423ee5fcf17c1d0d45d6988b8a5773eae8ad25d945bf34352040009",
		"spend_height": 105001,
		"spend_index": 6,
		"value": 556000000
	}]
}
```

### Address History 2


WebSocket Message:

```js
{
  id: id(),
  command: "address.history2",
  params: {address: "1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn", count: 0}
}
```

REST Request:
[http://localhost:9090/api/v1/address/history2/\<address>/\<height>](
    https://voyager.cancoin.co/api/v1/address/history2/1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn/0)

```json
{
	"history": [{
		"checksum": "5A7BDD3000000000",
		"hash": "5aa8e36f9423ee5fcf17c1d0d45d6988b8a5773eae8ad25d945bf34352040009",
		"height": 105001,
		"index": 6,
		"type": "spend"
	}, {
		"checksum": "5A7BDD3000000000",
		"hash": "fff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4",
		"height": 100000,
		"index": 0,
		"type": "output",
		"value": 556000000
	}]
}
```

### Blockchain History

WebSocket Message:

```js
{
  id: id(),
  command: "blockchain.history",
  params: {address: "1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn", height: 0}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/history/\<address>/\<from\_height>](https://voyager.cancoin.co/api/v1/blockchain/history/1JqDybm2nWTENrHvMyafbSXXtTk5Uv5QAn/0)


```json
{
	"history": [{
		"checksum": "5A7BDD3000000000",
		"hash": "5aa8e36f9423ee5fcf17c1d0d45d6988b8a5773eae8ad25d945bf34352040009",
		"height": 105001,
		"index": 6,
		"type": "spend"
	}, {
		"checksum": "5A7BDD3000000000",
		"hash": "fff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4",
		"height": 100000,
		"index": 0,
		"type": "output",
		"value": 556000000
	}]
}
```

### Stealth Scan


WebSocket Message:

```js
{
  id: id(),
  command: "blockchain.stealth",
  params: {filter: "11111111111111111", height: 0}
}
```

REST Request:
[http://localhost:9090/api/v1/blockchain/stealth/\<filter>/\<from\_height>](https://voyager.cancoin.co/api/v1/blockchain/stealth/11111111111111111/0)


```json
[{
	"address": "d4b516796c8be0b529d0aa6317b9087598f2d709",
	"ephemkey": "0269642b87b0898e1f079be72d194b86aca0b54eff41844ac28ec70c564db4991a",
	"tx_hash": "f12551534a2a8ff97ed80ee4742beae2569b663ba319070742d0f4bf88b654c3"
}]
```

### Broadcast Transaction

_todo

### Total Connections

WebSocket Message:

```js
{
  id: id(),
  command: "protocol.total_connections",
  params: {}
}
```

REST Request:
[http://localhost:9090/api/v1/protocol/total_connections](https://voyager.cancoin.co/api/v1/protocol/total\_connections)


```json
{"total_connections":16}
```

