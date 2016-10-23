defmodule LibbitcoinVoyagerCacheTest do
  alias Bitcoin.Voyager.Cache, as: C
  alias Bitcoin.Voyager.Handlers.Blockchain.TransactionHandler
  use ExUnit.Case, async: false

  test "chain_state" do
    assert :ok = C.set_chain_state(cache_height: 100)
    assert 100 = C.get_chain_state(:cache_height)
  end

  @hex_hash "3c9018e8d5615c306d72397f8f5eef44308c98fb576a88e030c25456b4f3a7ac"
  @hash Base.decode16!(@hex_hash, case: :lower)
  @raw_tx Base.decode16!("010000000189632848F99722915727C5C75DA8DB2DBF194342A0429828F66FF88FAB2AF7D6000000008B483045022100ABBC8A73FE2054480BDA3F3281DA2D0C51E2841391ABD4C09F4F908A2034C18D02205BC9E4D68EAFB918F3E9662338647A4419C0DE1A650AB8983F1D216E2A31D8E30141046F55D7ADEFF6011C7EAC294FE540C57830BE80E9355C83869C9260A4B8BF4767A66BACBD70B804DC63D5BEEB14180292AD7F3B083372B1D02D7A37DD97FF5C9EFFFFFFFF0140420F000000000017A914F815B036D9BBBCE5E9F2A00ABD1BF3DC91E955108700000000")

  test "put" do
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx)
  end

  test "get" do
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx)
    assert {:ok, %{transaction: %{hash: @hex_hash}}} = C.get(TransactionHandler, %{hash: @hex_hash}, [@hash])
  end

  test "cache height" do
    assert :ok = C.set_chain_state(cache_height: 100)
    assert 100 = C.get_chain_state(:cache_height)
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx, %{cache_height: 100})
    assert {:ok, %{transaction: %{hash: @hex_hash}}} = C.get(TransactionHandler, %{hash: @hex_hash}, [@hash])
    assert :not_found = C.get(TransactionHandler, %{cache_height: 101, hash: @hex_hash}, [@hash])
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx, %{cache_height: 101})
    assert :not_found = C.get(TransactionHandler, %{cache_height: 101, hash: @hex_hash}, [@hash])
  end

  test "ets cache height" do
    assert :ok = C.set_chain_state(cache_height: 100)
    assert 100 = C.get_chain_state(:cache_height)
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx)
    assert {:ok, %{transaction: %{hash: @hex_hash}}} = C.get(TransactionHandler, %{hash: @hex_hash}, [@hash])
    assert :not_found = C.get(TransactionHandler, %{cache_height: 101, hash: @hex_hash}, [@hash])
    assert :ok = C.set_chain_state(cache_height: 101)
    assert 101 = C.get_chain_state(:cache_height)
    assert :ok = C.put(TransactionHandler, [@hash], @raw_tx)
    assert {:ok, %{transaction: %{hash: @hex_hash}}} = C.get(TransactionHandler, %{cache_height: 101, hash: @hex_hash}, [@hash])
  end

end
