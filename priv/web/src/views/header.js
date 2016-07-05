import m from 'mithril';

/** @jsx m */

let toggleSearch = function() {
  this.vm.searchOpen(!this.vm.searchOpen())
}

let searchSubmit = function(self) {
  return () => {
    m.route(search.call(self, self.vm.search()))
    return false;
  }
}

let searchDrop = function(self) {
  return <div class={self.vm.searchOpen() ? "head_search_row" : "head_search_row closed"}>
    <div class="head_search_shell">
      <form action="" id="search-form" onsubmit={searchSubmit(self)}>
        <div class="input-group">
          <input type="submit" value="A" class="head_search_btn"></input>
          <input type="text" oninput={m.withAttr('value', self.vm.search)} class="head_search_form" placeholder="Search by block hash, block height, transaction or address" ></input>
          <div style="clear:both;"></div>
        </div>
      </form>
    </div>
  </div>
}

let search = function(value) {
  if (value.length === 64) {
    if (value.match(/^00000000/)) {
      return ("/block/" + value)
    } else {
      return ("/tx/" + value)
    }
  } else if (Number(value) > 0) {
    return ("/block/" + value)
  } else {
    return("/address/" + value)
  }
}

let showError = function(self) {
  return <h1>Error: {self.vm.error()}</h1>
}

export default function view(self) {
  return <div class="head_shell">
    <div class="container">
      <div class="row">
      <div class="head_search">
        <div class="head_icon">M</div>
        <a role="button" href="#" onclick={toggleSearch.bind(self)}>Search</a>
      </div>
        <div class="head_stat hide">
          <a onclick={self.navigate('/')} class="head_icon">8</a>
          {self.vm.last_height()}
        </div>
        <div class="head_stat hide">
          <div class="head_icon">G</div>
          {self.vm.socket_connected() ? 'Connected' : 'Connecting'}
        </div>
        <a href="/"><div class="head_logo">2</div></a>
      </div>
    </div>
      <div class="container">
        <div class="row">
          {searchDrop(self)}
        </div>
        <div class="row">
          {self.vm.error() ? showError(self) : ''}
        </div>
      </div>
  </div>

}
