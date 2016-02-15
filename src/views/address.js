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

  oppositeRowType(type) {
    return type == 'spend' ? 'output' : 'spend'
  }

  linkChecksum(row) {
    return this.checksumId({type: this.oppositeRowType(row.type), checksum: row.checksum});
  }

  checksumId(row) {
    return `history_${row.type}_${row.checksum}`
  }

  findPair(ctrl, row) {
    return ctrl.history().find((find_row) => {
      let type = this.oppositeRowType(row.type);
      return find_row.type === this.oppositeRowType(row.type)
        && find_row.checksum === row.checksum
    })
  }

  historyView(ctrl) {
    return (row) => {
      let pair = this.findPair(ctrl, row)
      return <div id={this.checksumId(row)} class="inout_shell">
        <div class="block_line first solid">
          <div class="block_line_tag">TYPE</div>
          {row.type}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">AMOUNT</div>
          <span>1</span>{Util.satoshiToBtc(row.value || pair && pair.value)}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">BLOCK HEIGHT</div>
          <a href="#" onclick={this.navigate(`/block/${row.height}`)}>{row.height}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">TRANSACTION</div>
          <a href="#" onclick={this.navigate(`/tx/${row.hash}`)}>{`${row.hash}:${row.index}`}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">{row.type === 'output' ? 'SPEND' : 'PREVIOUS OUTPUT'}</div>
          <a href={`#${this.linkChecksum(row)}`}>{pair ? `${pair.hash}:${pair.index}` : 'Unspent'}</a>
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
