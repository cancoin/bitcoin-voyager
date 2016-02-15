import Component from '../component';
import header from './header';
import footer from './footer';
import * as Util from '../modules/util';

/** @jsx m */

export default class Address extends Component {

  init(ctrl) {
    ctrl.address = m.prop(m.route.param('address'))
    ctrl.history = m.prop([]);
    ctrl.count   = m.prop(20);

    this.fetchHistory(ctrl);
  }

  onUnload() {
  }

  fetchHistory(ctrl) {
    this.client.fetchAddressHistory2(ctrl.address(), ctrl.count()).then((resp) => {
      ctrl.history(resp.history)
      m.redraw('diff')
    }).catch((error) => {
      alert(error)
    })
  }

  loadMoreHistory(ctrl) {
    return () => {
      ctrl.count(ctrl.count() + 20);
      this.fetchHistory(ctrl);
    }
  }

  historyView(ctrl) {
    return (row) => {
      return <div class="inout_shell">
        <div class="block_line first solid">
          <div class="block_line_tag">TYPE</div>
          {row.type}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">AMOUNT</div>
          <span>1</span>{Util.satoshiToBtc(row.value)}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">HASH</div>
          <a href="#" onclick={this.navigate(`/tx/${row.hash}`)}>{row.hash}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">HEIGHT</div>
          <a href="#" onclick={this.navigate(`/block/${row.height}`)}>{row.height}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">INDEX</div>
          {row.index}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">CHECKSUM</div>
          {row.checksum}
        </div>
        <div class="horline"></div>
      </div>
    }
  }

  loadMoreHistoryView(ctrl) {
    if (ctrl.history().length < ctrl.count()) return;
    return <div class="row">
      <button class="" onclick={this.loadMoreHistory(ctrl)}>Load More</button>
    </div>
  }
  view(ctrl) {
    return <div>
      {header(this)}
      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="body_head_icon">1</div>
            Bitcoin <span>Address</span>
          </div>
        </div>
        <div class="row">
          <div class="block_shell nomarg">
            <div class="address">
              <div class="address_tag">Address</div>
              <div class="address_icon">I</div>
              {ctrl.address()}
            </div>
          </div>
        </div>
        <div class="row">
          <div class="inout_arrow_down"></div>
        </div>
        <div class="row">
          <div class="block_shell">
            <div class="inout_head">
              <div class="inout_head_icon">J</div>Address Transactions
            </div>
            {ctrl.history().map(this.historyView(ctrl))}
          </div>
        </div>
        {this.loadMoreHistoryView(ctrl)}
      </div>
      {footer(this)}
    </div>
  }
}
