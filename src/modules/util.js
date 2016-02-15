import Big from 'big.js'

const SATOSHI = Big(100000000)

const timeOptions = {
  hour: 'numeric', minute: 'numeric', second: 'numeric',
  hour12: true
};

export function formatTime(seconds, options=timeOptions) {
  if (+seconds === NaN) return;
  return new Date(+seconds * 1000).toLocaleString('en-US', options);
}

export function satoshiToBtc(satoshi) {
  if (satoshi === undefined) return null;
  return Big(satoshi).div(SATOSHI).toString()
}


export function elementViewed(el) {
  var top = el.offsetTop;
  var height = el.offsetHeight;

  while(el.offsetParent) {
    el = el.offsetParent;
    top += el.offsetTop;
  }

  return (
    (top + height) <= (window.pageYOffset + window.innerHeight)
  );
}

export function txHashId(hash) {
  return `tx_${hash.slice(0, 16)}`
}

