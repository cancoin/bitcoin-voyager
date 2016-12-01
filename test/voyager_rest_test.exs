defmodule LibbitcoinVoyagerRESTTest do
  use ExUnit.Case, async: true

  @timeout 5000 # for really slow connections

  setup do
    host = Application.get_env(:bitcoin_voyager, :host, '127.0.0.1')
    port = Application.get_env(:bitcoin_voyager, :port, 9090)

    {:ok, conn_pid} = :gun.open(host, port)
    {:ok, proto} = :gun.await_up(conn_pid)

    on_exit fn ->
      :ok = :gun.shutdown(conn_pid)
    end

    {:ok, conn: conn_pid, proto: proto}
  end

  test "open connection", ctx do
    assert is_pid(ctx[:conn])
    assert ctx[:proto] == :http
  end

  test "blockchain/last_height", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/last_height")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"height" => height} = assert_data(ctx[:conn], ref)
    assert is_integer(height)
    assert height > 392098
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @height 205296

  test "blockchain/block_height", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/block_height/#{@hash}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"height" => @height} = assert_data(ctx[:conn], ref)
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @header %{"bits" => 436565487,
            "hash" => "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3",
            "merkle" => "cbd0b198cc7416c61820df459711023f76489dbd749854cbd9375bae61ef1ca0",
            "nonce" => 155484339,
            "previous_block_hash" => "0000000000000511d5ed1fb477e24cf0e1b1e34a75a2b6a03b2b722e52adae91",
            "size" => 81, "timestamp" => 1351375752, "version" => 1}

  test "blockchain/block_header", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/block_header/#{@height}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"block_header" => @header} = assert_data(ctx[:conn], ref)
  end

  @hash "000000000000008c8261e0d246855d29683fe7405e9090967d81c28c36e8c7e3"
  @transaction_hashes [
    "e6e09250ed7bd7fae5786ea83e409dd8a03f802de71beb37494f376edac4e03b",
    "49759d432e89ed88460b290e9bd3d8c588507cf25e54a8ed39285ab23e41f0ea",
    "5bc7fae2eb695c5afed4fb1581b9e084c9a6cef35ab79d7899395f110edee328",
    "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
    "4074763ef3d62b43718dfb704ea3ac111e2228da65fcbe062648bf7f1b249b98"]

  test "blockchain/block_transaction_hashes", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/block_transaction_hashes/#{@hash}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"transactions" => @transaction_hashes} = assert_data(ctx[:conn], ref)
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @tx_in %{"address" => "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui", "previous_output" => %{"hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea", "index" => 0},
          "script" => "48304502210087d298e9ff50496dd9a3b3fd88e130037d9e413072a2f4d1c7538b5a842b40f302205501df0247fc622568730a970209aeffb69810babd91879adcecc87a0fde162d0141040de3ec8ac99ddd8029cca332de7f75a408c50af34a5ea4368beac7d2effd21a8c4c09973176719f6fd835d849c9d1804c5bb565a2f29165231887da937c22577",
          "script_asm" => "[ 304502210087d298e9ff50496dd9a3b3fd88e130037d9e413072a2f4d1c7538b5a842b40f302205501df0247fc622568730a970209aeffb69810babd91879adcecc87a0fde162d01 ] [ 040de3ec8ac99ddd8029cca332de7f75a408c50af34a5ea4368beac7d2effd21a8c4c09973176719f6fd835d849c9d1804c5bb565a2f29165231887da937c22577 ]",
          "sequence" => 4294967295}
  @tx_out %{"address" => "1Ps2ciLdb4b8vLJs8PpWxivNrGj5Hbe9S5", "script" => "76a914fac8ea01420f21d82b80df4b86e2ade4bdb7043e88ac", "script_asm" => "dup hash160 [ fac8ea01420f21d82b80df4b86e2ade4bdb7043e ] equalverify checksig", "size" => 34,
          "value" => 1017559369}

  test "blockchain/transaction", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/transaction/#{@hash}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"transaction" => %{"coinbase" => false, "hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
        "inputs" => [tx_in], "locktime" => 0,
        "outputs" => [tx_out], "size" => 224, "value" => 1017559369, "version" => 1}} = assert_data(ctx[:conn], ref)
    assert tx_in == @tx_in
    assert tx_out == @tx_out
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @height 205296
  @index 3

  test "blockchain/transaction_index", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/transaction_index/#{@hash}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"height" => @height, "index" => @index} = assert_data(ctx[:conn], ref)
  end

  @hash "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235"
  @index 0
  @spend_hash "95f00d46b48edccbc1eae8cc4b7c6686e162c57b9008ea062e6ab169d0a29a66"
  @spend_index 0

  test "blockchain/spend", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/spend/#{@hash}/#{@index}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"hash" => @spend_hash, "index" => @spend_index} = assert_data(ctx[:conn], ref)
  end

  @address "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui"
  @from_height 0
  @history [%{"output_hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea",
     "output_height" => 205290, "output_index" => 0,
     "spend_hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
     "spend_height" => 205296, "spend_index" => 0, "value" => 1017559369}]

  test "address/history", ctx do
    ref = :gun.get(ctx[:conn], url "address/history/#{@address}/#{@from_height}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"history" => @history} = assert_data(ctx[:conn], ref)
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

  test "address/history2", ctx do
    ref = :gun.get(ctx[:conn], url "address/history2/#{@address}/#{@from_height}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"history" => @history} = assert_data(ctx[:conn], ref)
  end

  @address "1AgctCm8pGRVRwySFKvgNcsx5vGq78bLui"
  @from_height 0
  @history [%{"checksum" => "63C92DED00000000", 
    "hash" => "888a30be32d8ffdbee46dd909c447c7991eb50af24a51601809089cfe2637235",
     "height" => 205296, "index" => 0, "type" => "spend"},
   %{"checksum" => "63C92DED00000000",
     "hash" => "ab00248cd12452c2c45be7ca91899fd8e174595b4d16e2f2e3c92dedbb1d8cea",
     "height" => 205290, "index" => 0, "type" => "output",
     "value" => 1017559369}]

  test "blockchain/history", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/history/#{@address}/#{@from_height}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert %{"history" => @history} = assert_data(ctx[:conn], ref)
  end

  @stealth_bits "11111111111111111"
  @stealth_history %{
    "ephemkey" => "0269642b87b0898e1f079be72d194b86aca0b54eff41844ac28ec70c564db4991a",
    "address" =>  "d4b516796c8be0b529d0aa6317b9087598f2d709",
    "tx_hash" =>  "f12551534a2a8ff97ed80ee4742beae2569b663ba319070742d0f4bf88b654c3"}

  test "blockchain/stealth", ctx do
    ref = :gun.get(ctx[:conn], url "blockchain/stealth/#{@stealth_bits}/#{@from_height}")
    assert 200 = assert_response(ctx[:conn], ref)
    assert [@stealth_history|_] = Enum.reverse(assert_data(ctx[:conn], ref))
  end

  defp assert_response(conn, ref) do
    assert_receive {:gun_response, conn_resp, ref_resp, :nofin, status, _headers}, @timeout
    assert conn == conn_resp
    assert ref == ref_resp
    status
  end

  defp assert_data(conn, ref) do
    assert_receive {:gun_data, conn_resp, ref_resp, :fin, data}, @timeout
    assert conn == conn_resp
    assert ref == ref_resp
    JSX.decode!(data)
  end

  defp url(fragment) do
    "/api/v1/#{fragment}"
  end


end

