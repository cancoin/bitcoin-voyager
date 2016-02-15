import Component from '../component';
import header from './header';
import footer from './footer';
import * as Util from '../modules/util';


import Big from 'big.js';

/** @jsx m */

export default class Transaction extends Component {

  init(ctrl) {
    let hash = m.route.param('hash')
    ctrl.hash = m.prop(hash);
    ctrl.height = m.prop(null);
    ctrl.index = m.prop(null);
    ctrl.tx = m.prop({});
    ctrl.header = m.prop({});

    this.fetchTransactionIndex(ctrl);
  }

  fetchTransactionIndex(ctrl) {
    m.startComputation()
    this.client.fetchTransactionIndex(ctrl.hash()).then((resp) => {
      ctrl.height(resp.height)
      ctrl.index(resp.index)
      this.fetchBlock(ctrl);
      this.fetchTransaction(ctrl);
      m.endComputation()
    }).catch((error) => {
      if (error === 'not_found') {
         ctrl.height(0);
         ctrl.index(null);
         this.fetchTransaction(ctrl);
      }
      m.endComputation()
    })
  }

  fetchBlock(ctrl) {
    if(ctrl.height() > 0) {
      m.startComputation()
      this.client.fetchBlockHeader(ctrl.height()).then((resp) => {
        ctrl.header(resp.block_header);
        m.endComputation()
      })
    }

  }

  fetchTransaction(ctrl) {
    m.startComputation()
    if(ctrl.height() > 0) {
      this.client.fetchBlockchainTransaction(ctrl.hash()).then((resp) => {
        ctrl.tx(resp.transaction);
        m.endComputation()
      })
    } else {
      this.client.fetchTransactionPoolTransaction(ctrl.hash()).then((resp) => {
        ctrl.tx(resp.transaction);
        m.endComputation()
      })
    }
  }

  inputView(ctrl) {
    return (input) => {
      return <div class="inout_shell">
        <div class="block_line">
          <div class="block_line_tag">INPUT ADDRESS</div>
          <a href="#" onclick={this.navigate(`/address/${input.address}`)}>{input.address}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">PREVIOUS OUTPUT</div>
          <a href="#" onclick={this.navigate(`/tx/${input.previous_output.hash}`)}>{input.previous_output.hash}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">PREVIOUS OUTPUT INDEX</div>
          {input.previous_output.index}
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">SEQUENCE</div>
          {input.sequence}
        </div>
        <div class="horline"></div>
      </div>

    }
  }

  outputView(ctrl) {
    return (output) => {
      return <div class="inout_shell">
        <div class="block_line">
          <div class="block_line_tag">OUTPUT ADDRESS</div>
          <a href="#" onclick={this.navigate(`/address/${output.address}`)}>{output.address}</a>
        </div>
        <div class="block_line">
          <div class="block_line_tag alt">OUTPUT VALUE</div>
          <span>1</span>{Util.satoshiToBtc(output.value)}
        </div>
        <div class="horline"></div>
      </div>
    }
  }

  view(ctrl) {
    var tx = ctrl.tx()
    return <div>
      {header(this)}
      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="body_head_icon">1</div>
            Bitcoin <span>Transaction</span>
          </div>
        </div>
        <div class="row">
          <div class="block_shell nomarg">
            <div class="block_height mobile">
              <div class="block_height_tag">Amount</div>
              <div class="block_height_icon">J</div>
              {Util.satoshiToBtc(ctrl.tx().value)} btc<br></br>
            </div>
            <div class="block_line">
              <div class="block_line_tag">TRANSACTION HASH</div>
              {ctrl.tx().hash}
            </div>
            <div class="block_line">
              <div class="block_line_tag">BLOCK HASH</div>
              <a href="#" onclick={this.navigate(`/block/${ctrl.header().hash}`)}>{ctrl.header().hash || 'Unconfirmed Transaction'}</a>
            </div>
            <div class="block_line">
              <div class="block_line_tag">BLOCK NUMBER</div>
              <a href="#" onclick={this.navigate(`/block/${ctrl.height()}`)}>{ctrl.height() || this.vm.last_height() + '?'}</a>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="inout_arrow_down"></div>
        </div>
        <div class="row">
          <div class="block_shell">
            <div class="inout_head">
              <div class="inout_head_icon">L</div>Transaction Inputs
            </div>
            {tx.inputs && tx.inputs.map(this.inputView(ctrl))}
          </div>
        </div>

        <div class="row">
          <div class="block_shell">
            <div class="inout_head">
              <div class="inout_head_icon">K</div>Transaction Outputs
            </div>
            {tx.outputs && tx.outputs.map(this.outputView(ctrl))}
          </div>
        </div>
      </div>

      {footer(this)}
    </div>
  }
}
