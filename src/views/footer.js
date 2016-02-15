/** @jsx m */

export default function view(ctrl) {
  return <div class="footer_shell">
    <div class="container">
      <div class="row">
        <div class="footer_dev">
          <div class="footer_icon">2</div>
          <div class="footer_text">Made by <a href="http://cancoin.co" target="_blank">cancoin</a> using <a href="http://libbitcoin.dyne.org" target="_blank">libbitcoin</a></div>
          <br clear="all" />
        </div>
        <div class="footer_cancoin hidden-xs">
          <div class="footer_icon">3</div>
          <div class="footer_text">Visit <a href="http://cancoin.co" target="_blank">cancoin.co</a></div>
          <br clear="all" />
        </div>
        <div class="footer_github">
          <div class="footer_icon">9</div>
          <div class="footer_text">View on <a href="http://github.com" target="_blank">Github</a></div>
          <br clear="all" />
        </div>
      </div>
    </div>
  </div>
}
