::  primary feedback:
::  - multi-line apppropriately but use your runes to get
::    things nice and tight
::  - where you have things defined in the sur file, use
::    =on e.g. instead of on=?(%.y %.n). (also, just do on=? in sur)
::  - if you have encode-request-body, as a wet gate but then only
::    handle one case there and do the other one in line in your last
::    function, it seems weird to me
::  - don't do one line :_  e.g. :_  this  ~[some cards]
::    instead, do [~[some cards] this] - it's very strange otherwise
::  
/-  *hue
/+  default-agent, dbug, hjc=hue-json-encoder
    :: *hue-json-decoder,  seemingly not in use yet.
|%
+$  versioned-state
  $%  state-0
  ==
::
+$  state-0
  $:  %0
      url=@t
      code=@t
      username=@t
      access-token=@t
      refresh-token=@t
      on=?
      bri=@ud
      logs=(list [@da ? @ud])
    ==
::
+$  card  card:agent:gall

--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
=<
  |_  =bowl:gall
  +*  this  .
      def   ~(. (default-agent this %.n) bowl)
      hc    ~(. +> bowl)
  ++  on-init
    ^-  (quip card _this)
    :-  ~
    %=  this
      url  'https://api.meethue.com/route/api/'
      code  ''
      username  ''
      access-token  ''
      refresh-token  ''
      on  %.n
      bri  254
      logs  *(list [@da ? @ud])
    ==
  ++  on-save
    ^-  vase
    !>(state)
  ++  on-load
    |=  old-state=vase
    ^-  (quip card _this)
    =/  old  !<(versioned-state old-state)
    ?-  -.old
      %0  `this(state old)
    ==
  ::
  ++  on-poke
    |=  [=mark =vase]
    ::
    ::  poke types:
    ::  %toggle: turn on/off the lights
    ::  %bri:  change brightness (0-254). Assumes lights are on.
    ::  %code: pass code to backend for generating tokens.
    ::
    ^-  (quip card _this)
    ?>  ?=(%hue-action mark)
    =/  act  !<(action vase)
    ?-  -.act
        %toggle
      :_  this
      ::  changed this to produce a list of cards.
      %-  change-light-state:hc
      [url +.act bri username access-token]
    ::
        %bri
      :_  this
      %-  change-light-state:hc
      [url %.y +.act username access-token]
    ::
        %code
      [(setup-with-code:hc +.act) this]
    ==
  ++  on-watch  on-watch:def
  ++  on-leave  on-leave:def
  ++  on-peek
    |=  =path
    ::
    ::  scry from frontend, asking for current state.
    ::
    ^-  (unit (unit cage))
    ?>  ?=([%x %update ~] path)
    ``json+!>((update-to-json:hjc [on bri code]))
  ++  on-agent  on-agent:def
  ++  on-arvo
    |=  [=wire sign=sign-arvo]
    ::
    ::  wire types:
    ::  /light:  resp from light state change
    ::  /setup:  resp. from setup-bridge. Contains auth/tokens.
    ::  /refresh: behn alert to refresh tokens
    ::  /tokens: resp. from token refresh
    ::
    ^-  (quip card _this)
    ?+  wire  (on-arvo:def wire sign)
        [%light ~]
      ?>  ?=([%khan %arow *] sign)
      ?:  ?=(%.y -.p.sign)
        =/  resp  !<(@t q.p.p.sign)
        ::=/  jon  (de-json:html resp)
        ::=/  state  (state-from-json (need jon))
        ::=/ new-logs (limo (welp ~[[now.bowl on.state bri.state]] logs))
        ::`this(logs new-logs, on on.state, bri bri.state)
        `this
      `this :: error! TODO
      ::
        [%setup ~]
      ?>  ?=([%khan %arow *] sign)
      ?:  ?=(%.y -.p.sign)
        =/  resp  !<  
          $:  
            username=@t 
            code=@t 
            access-token=@t 
            refresh-token=@t
          ==
          q.p.p.sign
        :-  (set-refresh-timer:hc now.bowl)
        %=  this
          username  username.resp
          code  code.resp
          access-token  access-token.resp
          refresh-token  refresh-token.resp
        ==
      `this :: error! TODO
      :: either retry (infinite loop potentially)
      :: or notify user that their code is wrong
      ::
        [%refresh ~]
      ?>  ?=([%behn %wake *] sign)
      [(refresh-tokens:hc refresh-token) this]
      ::
        [%tokens ~]
      ?>  ?=([%khan %arow *] sign)
      ?:  ?=(%.y -.p.sign)
        =/  resp
          !<([access-token=@t refresh-token=@t] q.p.p.sign)
        :-  (set-refresh-timer:hc now.bowl)
        %=  this
          access-token  access-token.resp
          refresh-token  refresh-token.resp
        ==
      `this :: error! TODO
    ==
  ++  on-fail   on-fail:def
  --
|_  bol=bowl:gall
::  +change-light-state:
::
::    since you use username and access-token,
::    we suggest you make bri into brightness.
::
::    also please do `on=?(%.y %.n)` => `on=?`
::
::    alias some of these things in sur maybe.
::
++  change-light-state
  |=  [url=@t on=? bri=@ud username=@t access-token=@t]
  |^
    =/  body  ~[['on' b+on] ['bri' n+`@t`(scot %ud bri)]]
    =/  auth  `@t`(cat 3 'Bearer ' access-token)
    =;  cag=cage
      [%pass /light %arvo %k %fard %hue %put-request cag]~
    :-  %noun
    !>  ^-  [@t (list [@t @t]) (unit octs)]
    :-  `@t`(rap 3 url username '/groups/0/action' ~)
    :_  (encode-request-body body)
    :~  ['Content-Type' 'application/json']
        ['Authorization' auth]
    ==
  ::  why is this a crazy wet gate? also why use a lib here
  ::  but then not in refresh tokens where ur doing the same?
  ::  
  ++  encode-request-body
    |*  body=*
    ^-  (unit octs)
    %-  some
    %-  as-octt:mimes:html
    (en-json:html o+(malt (limo body)))
  --
::
++  setup-with-code
  |=  [code=@t]
  ^-  (list card)
  [%pass /setup %arvo %k %fard %hue %setup-bridge noun+!>(code)]~
::
++  set-refresh-timer
  |=  [now=@da]
  ^-  (list card)
  [%pass /refresh %arvo %b %wait (add ~d6 now)]~
++  refresh-tokens
  |=  [refresh-token=@t]
  ^-  (list card)
  =;  cag=cage
    [%pass /tokens %arvo %k %fard q.byk.bol %post-for-tokens cag]~
  :-  %noun
  !>  ^-  [url=@t headers=(list [@t @t]) body=(unit octs)]
  :-  'https://api.meethue.com/oauth2/refresh?grant_type=refresh_token'
  :_  (some (as-octt:mimes:html (weld "refresh_token=" (trip refresh-token))))
  :~  ['Authorization' 'Basic ZWF6UGRNWkJHOUxIZkdCb2lkN3REbVpyekNlN0VGM1Y6aWxiTXkwZkxsajlPT29jZw==']
      ['Content-Type' 'application/x-www-form-urlencoded']
  ==
--