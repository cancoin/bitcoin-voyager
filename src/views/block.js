import Component from '../component';
import header from './header';
import footer from './footer';
import * as Util from '../modules/util';

/** @jsx m */

export default class Block extends Component {

  init(ctrl) {
    let hash = m.route.param('hash');

    ctrl.height = m.prop(0)
    ctrl.block = m.prop({})
    ctrl.block_transactions = m.prop([])
    ctrl.transactions = m.prop([])
    ctrl.tx_cursor = m.prop(0)

    window.onscroll = this.onScroll(ctrl);

    this.getLastHeight(ctrl);

    if (hash.length === 64) {
      this.fetchByHash(ctrl, hash);
    } else {
      this.fetchByHeight(ctrl, parseInt(hash, 10));
    }
  }

  onUnload(event) {
    window.onscroll = undefined;
  }

  onScroll(ctrl) {
    return (_event) => {
      this.fetchSeenTransactions(ctrl);
    }
  }

  getLastHeight(ctrl) {
    this.client.fetchLastHeight().then((reply) => {
      this.vm.last_height(reply.height)
    })
  }

  fetchByHash(ctrl, hash) {
    m.startComputation()
    this.client.fetchBlockHeight(hash).then((resp) => {
      this.fetchByHeight(ctrl, resp.height);
      m.endComputation()
    }, (error) => {
      this.vm.error(error)
      m.endComputation()
    })
  }

  fetchByHeight(ctrl, height) {
    if (height < 0) height = this.vm.last_height() + height + 1;
    m.startComputation()
    this.client.fetchBlockHeader(height).then((resp) => {
      ctrl.height(height);
      ctrl.block(resp.block_header);
      m.endComputation()
      this.fetchTransasctionHashes(ctrl)
    }, (error) => {
      this.fetchByHeight(ctrl, -1);
      m.endComputation()
    })

  }

  fetchTransasctionHashes(ctrl) {
    let block = ctrl.block()
    if (!block) return;
    m.startComputation()
    this.client.fetchBlockTransactionHashes(block.hash).then((resp) => {
      ctrl.block_transactions(resp.transactions);
      m.endComputation()
    }, (error) => {
      throw(error)
      this.vm.error(error)
      m.endComputation()
    })

  }

  getTxCursor(ctrl) {
    let index = ctrl.tx_cursor();
    return ctrl.block_transactions()[index];
  }

  fetchSeenTransactions(ctrl) {
    let hash = this.getTxCursor(ctrl);
    if (!hash) return true;
    let el = document.getElementById(Util.txHashId(hash));
    if (!el) return true;
    if (Util.elementViewed(el)) {
      this.fetchTransaction(ctrl, ctrl.transactions(), hash);
      ctrl.tx_cursor(ctrl.tx_cursor() + 1)
      this.onScroll(ctrl)(event);
      return true
    }
  }

  fetchTransaction(ctrl, transactions, hash) {
    if (!transactions[hash]) {
      m.startComputation()
      transactions[hash] = this.client.fetchBlockchainTransaction(hash).then((resp) => {
        transactions[resp.transaction.hash] = resp.transaction;
        ctrl.transactions(transactions)
        m.endComputation()
      }, (error) => {
        this.vm.error(error)
        m.endComputation()
      })
    }
  }

  fetchAllTransactions(ctrl) {
    resp.transactions.forEach((hash) => {
      this.client.fetchBlockchainTransaction(hash).then((resp) => {
        var transactions = ctrl.transactions();
        transactions[resp.transaction.hash] = resp.transaction;
        ctrl.transactions(transactions)
        m.redraw('diff')
      }, (error) => {
        throw(error)
        this.vm.error(error)
      })

    })
  }

  view(ctrl) {
    let transactions = ctrl.transactions();
    let block = ctrl.block();

    if (!block) {
      return <div>
        {header(this)}
        not found
        {footer(this)}
      </div>
    }

    return <div>
      {header(this)}
      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="block_next">
              {ctrl.height() < this.vm.last_height()
                ? m('a', {onclick: this.navigate(`/block/${ctrl.height() + 1}`)}, 'O')
                : ''}
            </div>
            <div class="block_prev">
              <a href="#" onclick={this.navigate(`/block/${ctrl.height() - 1}`)}>N</a>
            </div>
            <div class="body_head_icon">1</div>
            Block <span>#{ctrl.height()}</span>
          </div>
        </div>
        <div class="row">
          <div class="block_shell">
            <div class="block_height">
              <div class="block_height_tag">Block Height</div>
              <div class="block_height_icon">4</div>
              {ctrl.height()}<br></br>
            </div>
            <div class="block_line">
              <div class="block_line_icon">7</div>
              {block ? new Date(block.timestamp * 1000) : ''}
            </div>
            <div class="block_line">
              <div class="block_line_tag">BLOCK SIZE</div>
              {block.size}
            </div>
            <div class="block_line">
              <div class="block_line_tag">BLOCK HASH</div>
              <a href="#" onclick={this.navigate(`/block/${block.hash}`)}>{block.hash}</a>
            </div>
            <div class="block_line">
              <div class="block_line_tag">MERKLE ROOT</div>
              {block.merkle}
            </div>
            <div class="block_line">
              <div class="block_line_tag">NONCE</div>
              {block.nonce}
            </div>
            <div class="block_line">
              <div class="block_line_tag">BITS</div>
              {block.bits}
            </div>
            <div class="block_line">
              <div class="block_line_tag">BLOCK VERSION</div>
              {block.version}
            </div>
            <div class="block_line">
              <div class="block_line_tag">PREVIOUS BLOCK HASH</div>
              <a href="#" onclick={this.navigate(`/block/${block.previous_block_hash}`)}>{block.previous_block_hash}</a>
            </div>
          </div>
        </div>
      </div>

      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="body_head_icon">1</div>
            Transactions in block <span>#{ctrl.height()}</span>
          </div>
        </div>
        <div class="row">
        {ctrl.block_transactions().map((hash) => {
          let tx = transactions[hash];
          return <div id={Util.txHashId(hash)}>
            <div class="block_line" style="text-align:left;">
              <a href="#" onclick={this.navigate(`/tx/${hash}`)}>{hash}</a>
              <div class="block_trans_amount">{tx && Util.satoshiToBtc(tx.value) || ''}<span>1</span></div>
              <div style="clear:both;"></div>
            </div>
          </div>
        })}
        </div>
      </div>
      {footer(this)}
    </div>

  }

}
