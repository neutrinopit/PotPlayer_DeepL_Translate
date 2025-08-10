// ==UserScript==
// @name         Search Engine Switcher
// @namespace    http://tampermonkey.net/
// @version      0.1.26
// @description  Search Engine Switcher
// @author       https://twitter.com/rockucn

// @match        *://duckduckgo.com/*
// @match        *://search.brave.com/search*
// @match        *://www.google.com/search*
// @match        *://www.bing.com/search*

// @grant        unsafeWindow
// @grant        window.onload
// @grant        GM_getValue
// @grant        GM_setValue
// @run-at       document-body

// @license     MIT
// @downloadURL https://update.greasyfork.org/scripts/446492/%E6%90%9C%E7%B4%A2%E5%BC%95%E6%93%8E%E5%88%87%E6%8D%A2%E5%99%A8%20%20Search%20Engine%20Switcher.user.js
// @updateURL https://update.greasyfork.org/scripts/446492/%E6%90%9C%E7%B4%A2%E5%BC%95%E6%93%8E%E5%88%87%E6%8D%A2%E5%99%A8%20%20Search%20Engine%20Switcher.meta.js
// ==/UserScript==

// 搜索网址配置
const urlMapping = [
  {
    name: "Google",
    searchUrl: "https://www.google.com/search?q=",
    keyName: "q",
    testUrl: /https:\/\/www.google.com\/search.*/,
  },
  {
    name: "Duck",
    searchUrl: "https://duckduckgo.com/?q=",
    keyName: "q",
    testUrl: /https:\/\/duckduckgo.com\/*/,
  },
  {
    name: "Brave",
    searchUrl: "https://search.brave.com/search?q=",
    keyName: "q",
    testUrl: /https:\/\/search.brave.com\/search.*/,
  },
];

// JS获取url参数
function getQueryVariable(variable) {
  let query = window.location.search.substring(1);
  let pairs = query.split("&");
  for (let pair of pairs) {
    let [key, value] = pair.split("=");
    if (key == variable) {
      return decodeURIComponent(value);
    }
  }
  return null;
}

// 从url中获取搜索关键词
function getKeywords() {
  let keywords = "";
  for (let item of urlMapping) {
    if (item.testUrl.test(window.location.href)) {
      keywords = getQueryVariable(item.keyName);
      break;
    }
  }
  console.log(keywords);
  return keywords;
}

// 适配火狐浏览器的百度搜索
const isFirefox = () => {
  if (navigator.userAgent.indexOf("Firefox") > 0) {
    console.warn("[ Firefox ] 🚀");
    urlMapping[0].searchUrl = "https://www.baidu.com/baidu?wd=";
    urlMapping[0].testUrl = /https:\/\/www.baidu.com\/baidu.*/;
  } else {
    return;
  }
}


// 添加节点
function addBox() {
  isFirefox();
  // 主元素
  const div = document.createElement("div");
  div.id = "search-app-box";
  div.style = `
    position: fixed;
    top: 140px;
    left: 10px;
    width: 88px;
    background-color: hsla(200, 40%, 96%, .8);
    font-size: 12px;
    border-radius: 6px;
    z-index: 99999;`;
  document.body.insertAdjacentElement("afterbegin", div);

  // 标题
  let title = document.createElement("span");
  title.innerText = "Search";
  title.style = `
    display: block;
	color: hsla(211, 60%, 35%, .8);
    text-align: center;
    margin-top: 10px;
    margin-bottom: 5px;
    font-size: 12px;
    font-weight: bold;
    -webkit-user-select:none;
    -moz-user-select:none;
    -ms-user-select:none;
    user-select:none;`;
  div.appendChild(title);

  // 搜索列表
  for (let index in urlMapping) {
    let item = urlMapping[index];

    // 列表样式
    let style = `
        display: block;
		color: hsla(211, 60%, 35%, .8) !important;
        padding: 8px;
        text-decoration: none;`;
    let defaultStyle = style + "color: hsla(211, 60%, 35%, .8) !important;";
    let hoverStyle =
      style + "background-color: hsla(211, 60%, 35%, .1);";

    // 设置搜索引擎链接
    let a = document.createElement("a");
    a.innerText = item.name;
    a.style = defaultStyle;
    a.className = "search-engine-a";
    a.href = item.searchUrl + getKeywords();

    // 鼠标移入&移出效果，相当于hover
    a.onmouseenter = function () {
      this.style = hoverStyle;
    };
    a.onmouseleave = function () {
      this.style = defaultStyle;
    };
    div.appendChild(a);
  }
}

(function () {
  "use strict";
  window.onload = addBox();
})();