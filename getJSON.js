function getJSON_1(url, callback) {
  if (!getJSON.index) getJSON.index = 0;
  getJSON.index++;
  const script = document.createElement("script");
  function realCallback() {
      callback(...arguments);
      script.remove();
  }
  getJSON["c" + getJSON.index] = realCallback;
  script.src = url + (url.match(/\?/) ? "&" : "?") + "callback=getJSON.c" + getJSON.index;
  document.body.appendChild(script);
}

function getJSON_2(a, b) {
  getJSON.callbacks || (getJSON.callbacks = {});
  var c = "abcdefghijklmnopqrstuvwxyz";
  c += c.toUpperCase();
  for (var d = ""; d.length < 9 || getJSON.callbacks[d]; d += c[Math.floor(Math.random() * c.length)]) { }
  getJSON.callbacks[d] = b, a += a.indexOf("?") > -1 ? "&" : "?", a += "callback=getJSON.callbacks." + d;
  var e = document.createElement("script");
  e.src = a, document.head.appendChild(e)
}
