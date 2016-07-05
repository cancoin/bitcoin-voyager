defmodule LibbitcoinVoyagerWebSocketTest do
  use ExUnit.Case, async: true

  @timeout 5000 # for really slow connections

  setup do
    host = Application.get_env(:bitcoin_voyager, :host, '127.0.0.1')
    port = Application.get_env(:bitcoin_voyager, :port, 9090)

    {:ok, conn_pid} = :gun.open(host, port)
    {:ok, _proto} = :gun.await_up(conn_pid)

    on_exit fn ->
      :ok = :gun.shutdown(conn_pid)
    end

    {:ok, %{conn: conn_pid}}
  end

  def assert_upgrade(conn) do
    _ref = :gun.ws_upgrade(conn, "/api/v1/websocket")
    assert_receive {:gun_ws_upgrade, ^conn, :ok, _headers}
    {:ok, conn}
  end

  def new_id, do: :erlang.unique_integer([:positive])

  def websocket_result(conn, command, params, id \\ new_id, timeout \\ @timeout) do
    {:ok, conn} = assert_upgrade(conn);
    command = JSX.encode!(%{id: id, command: command, params: params})
    :gun.ws_send(conn, {:text, command})
    assert_receive {:gun_ws, conn, {:text, json}}, timeout
    assert {:ok, %{"id" => ^id, "result" => result}} = JSX.decode(json)
    result
  end

  test "open websocket connection", ctx do
    conn = ctx[:conn]
    assert is_pid(conn)
    assert {:ok, ^conn} = assert_upgrade(conn)
  end

  test "subscribe.heartbeat", ctx do
    if System.get_env("TEST_SUBSCRIPTION") == "true" do
      heartbeat = websocket_result(ctx[:conn], "subscribe.heartbeat", [], "subscribe.heartbeat")
      assert is_integer(heartbeat)
    end
  end

  test "subscribe.transaction", ctx do
    if System.get_env("TEST_SUBSCRIPTION") == "true" do
      assert %{"inputs" => _inputs, "outputs" => _outputs} =
        websocket_result(ctx[:conn], "subscribe.transaction", [], "subscribe.transaction", 10000)
    end
  end

  @tag timeout: 9000000
  test "subscribe.block", ctx do
    if System.get_env("TEST_BLOCK_SUBSCRIPTION") == "true" do
      assert %{"hash" => _hash} = websocket_result(ctx[:conn], "subscribe.block", [], "subscribe.block", 9000000)
    end
  end

  test "blockchain.fetch_last_height", ctx do
    assert %{"height" => height} = websocket_result(ctx[:conn], "blockchain.last_height", [])
    assert is_integer(height)
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @height 205296

  test "blockchain.block_height", ctx do
    assert %{"height" => @height} = websocket_result(ctx[:conn], "blockchain.block_height", %{height: @height, hash: @hash})
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @header %{"bits" => 436565487, "hash" => "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3",
            "merkle" => "cbd0b198cc7416c61820df459711023f76489dbd749854cbd9375bae61ef1ca0", "nonce" => 155484339,
            "previous_block_hash" => "0000000000000511d5ed1fb477e24cf0e1b1e34a75a2b6a03b2b722e52adae91",
            "size" => 81, "timestamp" => 1351375752, "version" => 1}

  test "blockchain.block_header", ctx do
    assert %{"block_header" => @header} =
      websocket_result(ctx[:conn], "blockchain.block_header", %{height: @height})
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @transaction_hashes [
    "e6e09250ed7bd7fae5786ea83e409dd8a03f802de71beb37494f376edac4e03b",
    "49759d432e89ed88460b290e9bd3d8c588507cf25e54a8ed39285ab23e41f0ea",
    "5bc7fae2eb695c5afed4fb1581b9e084c9a6cef35ab79d7899395f110edee328",
    "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
    "4074763ef3d62b43718dfb704ea3ac111e2228da65fcbe062648bf7f1b249b98"]

  test "blockchain/block_transaction_hashes", ctx do
    assert %{"transactions" => @transaction_hashes} =
      websocket_result(ctx[:conn], "blockchain.block_transaction_hashes", %{hash: @hash})
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @tx_in %{"address" => "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui", "previous_output" => %{"hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea", "index" => 0},
          "script" => "48304502210087d298e9ff50496dd9a3b3fd88e130037d9e413072a2f4d1c7538b5a842b40f302205501df0247fc622568730a970209aeffb69810babd91879adcecc87a0fde162d0141040de3ec8ac99ddd8029cca332de7f75a408c50af34a5ea4368beac7d2effd21a8c4c09973176719f6fd835d849c9d1804c5bb565a2f29165231887da937c22577",
          "script_asm" => "[ 304502210087d298e9ff50496dd9a3b3fd88e130037d9e413072a2f4d1c7538b5a842b40f302205501df0247fc622568730a970209aeffb69810babd91879adcecc87a0fde162d01 ] [ 040de3ec8ac99ddd8029cca332de7f75a408c50af34a5ea4368beac7d2effd21a8c4c09973176719f6fd835d849c9d1804c5bb565a2f29165231887da937c22577 ]",
          "sequence" => 4294967295}
  @tx_out %{"address" => "1Ps2ciLdb4b8vLJs8PpWxivNrGj5Hbe9S5", "script" => "76a914fac8ea01420f21d82b80df4b86e2ade4bdb7043e88ac", "script_asm" => "dup hash160 [ fac8ea01420f21d82b80df4b86e2ade4bdb7043e ] equalverify checksig", "size" => 34,
          "value" => 1017559369}

  test "blockchain.transaction", ctx do
    assert %{"transaction" => %{"coinbase" => false, "hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
        "inputs" => [tx_in], "locktime" => 0,
        "outputs" => [tx_out], "size" => 224, "value" => 1017559369, "version" => 1}} =
      websocket_result(ctx[:conn], "blockchain.transaction", %{hash: @hash})
    assert tx_in == @tx_in
    assert tx_out == @tx_out
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @height 205296
  @index 3

  test "blockchain.transaction_index", ctx do
    assert %{"height" => @height, "index" => @index} =
      websocket_result(ctx[:conn], "blockchain.transaction_index", %{hash: @hash})
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @index 0
  @spend_hash "95f00d46b48edccbc1eae8cc4b7c6686e162c57b9008ea062e6ab169d0a29a66"
  @spend_index 0

  test "blockchain.spend", ctx do
    assert %{"hash" => @spend_hash, "index" => @spend_index} =
      websocket_result(ctx[:conn], "blockchain.spend", %{hash: @hash, index: @index })
  end

  @address "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui"
  @from_height 0
  @history [%{"output_hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea",
     "output_height" => 205290, "output_index" => 0,
     "spend_hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
     "spend_height" => 205296, "spend_index" => 0, "value" => 1017559369}]

  test "address.history", ctx do
    assert %{"history" => @history} =
      websocket_result(ctx[:conn], "address.history", %{address: @address, from_height: @from_height})
  end

  @address "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui"
  @from_height 0
  @history [%{"hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
     "checksum" => "63C92DED00000000",
     "height" => 205296, "index" => 0, "type" => "spend"},
   %{"hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea",
     "checksum" => "63C92DED00000000",
     "height" => 205290, "index" => 0, "type" => "output",
     "value" => 1017559369}]

  test "address.history2", ctx do
    assert %{"history" => @history} =
      websocket_result(ctx[:conn], "address.history2", %{address: @address, from_height: @from_height})
  end

  @address "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui"
  @from_height 0
  @history [%{"checksum" => "63C92DED00000000", "hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235", "height" => 205296, "index" => 0, "type" => "spend"},
            %{"checksum" => "63C92DED00000000", "hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea", "height" => 205290, "index" => 0, "type" => "output", "value" => 1017559369}]

  test "blockchain.history", ctx do
    assert %{"history" => @history} =
      websocket_result(ctx[:conn], "blockchain.history", %{address: @address, from_height: @from_height})
  end

end
