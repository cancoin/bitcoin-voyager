let noop = function(){}

export default class VoyagerClient {
  constructor(uri, onOpen, onDisconnect, onError) {
    this.handlers = {};
    this.connected = false;
    this.socket = new WebSocket(uri);
    this.socket.onopen = (event) => {
        this.connected = true;
        onOpen(event);
    };
    this.socket.onclose = (event) => {
        this.connected = false;
        this.handlers = {};
        this.socket = null;
        onDisconnect(event);
    };
    this.socket.onerror = (event) => {
      this.socket.close();
      onError(event);
    };
    this.socket.onmessage = (event) => {
      this.handleMessage(event);
    }
  }

  onMessage(event) {}

  subscribeBlocks(resolve, reject) {
    return this.sendSubscription('subscribe.block', [], resolve, reject)
  }

  subscribeTransactions(resolve, reject) {
    return this.sendSubscription('subscribe.transaction', [], resolve, reject)
  }

  subscribeHeartbeats(resolve, reject) {
    return this.sendSubscription('subscribe.heartbeat', [], resolve, reject)
  }

  fetchLastHeight(cb) {
    return this.sendRequest('blockchain.last_height', [])
  }

  fetchBlockHeader(height) {
    return this.sendRequest('blockchain.block_header', {height: height})
  }

  fetchBlockHeight(hash) {
    return this.sendRequest('blockchain.block_height', {hash: hash})
  }

  fetchBlockTransactionHashes(hash) {
    return this.sendRequest('blockchain.block_transaction_hashes', {hash: hash})
  }

  fetchTransactionIndex(hash) {
    return this.sendRequest('blockchain.transaction_index', {hash: hash})
  }

  fetchBlockchainTransaction(hash) {
    return this.sendRequest('blockchain.transaction', {hash: hash})
  }

  fetchTransactionPoolTransaction(hash) {
    return this.sendRequest('transaction_pool.transaction', {hash: hash})
  }

  fetchAddressHistory2(address, count) {
    return this.sendRequest('address.history2', {address: address, count: count})
  }

  fetchBlockchainHistory(address=null) {
    return this.sendRequest('blockchain.history', {address: address})
  }

  fetchTotalConnections() {
    return this.sendRequest('protocol.total_connections', {})
  }

  sendSubscription(command, params, resolve=noop, reject=noop) {
    let id = command;
    let request = JSON.stringify({
      id: id,
      command: command,
      params: params
    })

    this.socket.send(request);

    return this.handlers[id] = {resolve: resolve, reject: reject}
  }

  sendRequest(command, params, id=this.randomInteger()) {
    let request = JSON.stringify({
      id: id,
      command: command,
      params: params
    })

    this.socket.send(request);

    return new Promise((resolve, reject) => {
      this.handlers[id] = {resolve: resolve, reject: reject};
    });
  }

  handleMessage(event) {
    var response = JSON.parse(event.data);
    this.onMessage(response);
    var handler = this.handlers[response.id];
    if (handler) {
      if (response.error) {
        handler.reject(response.error)
      } else if (response.result) {
        handler.resolve(response.result)
      } else {
        console && console.error(response)
      }

      if (! /^subscribe\./.test(response.id)) {
        delete this.handlers[response.id];
      }
    }
  }

  randomInteger() {
    return Math.floor((Math.random() * 4294967296));
  }
}

