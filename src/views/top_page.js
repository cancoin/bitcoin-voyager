import Component from '../component';
import header from './header';
import footer from './footer';
import * as Util from '../modules/util';

/** @jsx m */

export default class TopPage extends Component {

  init(ctrl) {
    Object.assign(ctrl, {
      blocks: m.prop([]),
      transactions: m.prop([]),
      heartbeats: m.prop([])
    });

    ctrl.total_connections = m.prop();

    this.getLastHeight(ctrl);
    this.getTotalConnections(ctrl);
    this.subscribe(ctrl);
  }

  onSubscription(prop, size=12) {
    return (resp) => {
      var items = prop();
      if (items[0] === resp ||
          (typeof items[0] === 'object' &&
           items[0].hash === resp.hash)) return;
      items.unshift(resp);
      prop(items.slice(0, size));
      m.redraw('diff');
    }
  }
  subscribe(ctrl) {
    this.client.subscribeTransactions(this.onSubscription(ctrl.transactions, 20))
    this.client.subscribeBlocks(this.onSubscription(ctrl.blocks))
    this.client.subscribeHeartbeats(this.onSubscription(ctrl.heartbeats))
  }

  getLastHeight(ctrl) {
    m.startComputation()
    this.client.fetchLastHeight().then((reply) => {
      this.vm.last_height(reply.height);
      m.endComputation()
      this.fetchBlocks(ctrl, reply.height, 12);
    })
  }

  getTotalConnections(ctrl) {
    m.startComputation()
    this.client.fetchTotalConnections().then((reply) => {
      ctrl.total_connections(reply.total_connections);
      m.endComputation()
    })
  }

  fetchBlocks(ctrl, height, count) {
    if (count == 0) return;
    m.startComputation()
    this.client.fetchBlockHeader(height).then((reply) => {
      var blocks = ctrl.blocks();
      var header = reply.block_header;
      var next_block = blocks[blocks.length - 1];
      if (next_block === undefined ||
          next_block.previous_block_hash === header.hash){
        header.height = height;
        header.time = Util.formatTime(header.timestamp);
        blocks.push(header);
        ctrl.blocks(blocks)
        m.endComputation()
        this.fetchBlocks(ctrl, height - 1, count - 1)
      } else {
        alert('There seems to be a fork in the chain..')
      }
    })
  }

  view(ctrl) {
    let blocks = ctrl.blocks();
    let last_block = blocks[0];
    let transactions = ctrl.transactions();

    return <div>
      {header(this)}
      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="body_head_icon">1</div>
            Latest <span>bitcoin</span> blocks
          </div>
        </div>
      </div>
      <div class="container">
      <div class="row index_block_row">
        {blocks.map((header) => {
          return <a href="#" onclick={this.navigate(`/block/${header.height}`)}><div class="index_block_shell pullDown">
            <div class="index_block_height">
              {header.height}
              <br></br>
              <span>{header.hash.slice(0, 22)}</span>
            </div>

            <div class="index_block_time">
              <div class="index_block_time_icon">7</div>
              {header.time}
            </div>
            <div class="index_block_nonce">
              <div class="index_block_nonce_tag">Nonce</div>
              0x{header.nonce.toString(16)}
            </div>
          </div>
          </a>
        })}
      </div>
      </div>
      <div class="container">
        <div class="row widg_pad">
          <div class="col-lg-4 col-md-4 col-sm-4 no_pad">
            <div class="widg_l">
              <div class="widg_icon">5</div>
              <div class="widg_content">{ctrl.total_connections()}</div>
              <div class="widg_label">Nodes Connected</div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-4 no_pad">
            <div class="widg_c">
              <div class="widg_icon">H</div>
              <div class="widg_content">{ctrl.heartbeats()[0]}</div>
              <div class="widg_label">Heartbeat</div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-4 no_pad">
            <div class="widg_r">
              <div class="widg_icon">4</div>
              <div class="widg_content">{last_block && last_block.time}</div>
              <div class="widg_label">Latest Block Time (GMT)</div>
            </div>
          </div>
        </div>
      </div>
      <div class="container">
        <div class="row">
          <div class="body_head">
            <div class="body_head_icon">1</div>
            Latest <span>bitcoin</span> transactions
          </div>
        </div>
      </div>
      <div class="container">
        <div class="row">
          <div class="index_trans_shell">
            {transactions.map((tx) => {
              return <div class="index_trans_line">
                <div class="index_trans_amount"><span>1</span>{Util.satoshiToBtc(tx.value)}</div>
                {m('div', {style: `background-color: #${tx.hash.slice(0, 6)}; float:left; width:8px; height:8px; border-radius:8px; margin-right:20px; margin-top:3px;`})}
                <a href="#" onclick={this.navigate(`/tx/${tx.hash}`)} class="index_trans_address">{tx.hash}</a>
              </div>
            })}
          </div>
        </div>
      </div>
      {footer(this)}
    </div>
  }
}
