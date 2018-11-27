{% if theme.baidushare.type === "button" %}
  <div class="bdsharebuttonbox">
    <a href="#" class="bds_weixin" data-cmd="weixin" title="分享到微信"></a>
    <a href="#" class="bds_twi" data-cmd="twi" title="分享到Twitter"></a>
    <a href="#" class="bds_fbook" data-cmd="fbook" title="分享到Facebook"></a>
    <a href="#" class="bds_tsina" data-cmd="tsina" title="分享到新浪微博"></a>
    <a href="#" class="bds_douban" data-cmd="douban" title="分享到豆瓣网"></a>
    <a href="#" class="bds_more" data-cmd="more"></a>
    <a class="bds_count" data-cmd="count"></a>
  </div>
  <script>
    window._bd_share_config = {
      "common": {
        "bdText": "",
        "bdMini": "2",
        "bdMiniList": false,
        "bdPic": ""
      },
      "share": {
        "bdSize": "24",
        "bdStyle": "0"
      },
      "image": {
        "viewList": ["tsina", "douban", "weixin", "twi", "fbook"],
        "viewText": "分享到：",
        "viewSize": "24"
      }
    }
  </script>
{% elseif theme.baidushare.type === "slide" %}
  <script>
    window._bd_share_config = {
      "common": {
        "bdText": "",
        "bdMini": "1",
        "bdMiniList":["weixin", "twi", "fbook",  "tsina", "douban"],
        "bdPic": "",
        "bdStyle":"2",
        "bdSize":"24"
      },
      "image": {
        "viewList": ["weixin", "twi", "fbook", "tsina", "douban"],
        "viewText": "分享到：",
        "viewSize": "24"
      },
      "slide": {
        "bdImg": "5",
        "bdPos": "right",
        "bdTop": "250"
      }
    }
  </script>
{% endif %}
<script>
  with(document)0[(getElementsByTagName('head')[0]||body).appendChild(createElement('script')).src='/lib/share/baidushare/js/share.js?v=89860593.js?cdnversion='+~(-new Date()/36e5)];
</script>
