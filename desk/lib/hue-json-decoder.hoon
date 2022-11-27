|%
+$  tokens
  $:  access-token=@t
      refresh-token=@t
  ==
+$  state
  $:  on=?
      bri=@ud
  ==
::
++  tokens-from-json
  =,  dejs:format
  ^-  $-(json tokens)
  %-  ot
  :~
    [`@tas`'access_token' so]
    [`@tas`'refresh_token' so]
  ==
++  username-from-json
  =,  dejs:format
  %-  ar
  %-  ot
  :~  :-  %success
      %-  ot
      :~  username+so
      ==
  ==
:: ++  state-from-json
::   =,  dejs:format
::   ^-  $-(json state)
::   %-  ar
::   %-  ot
::   :~  :-  %success
::       %-  ot
::       :~  ['/groups/0/action/on' bo]
::       ==
::   :-  %success
::       %-  ot
::       :~  ['/groups/0/action/bri' ni]
::       ==
::   ==
--

::  top level


^-  $-(json (list ?([%tog ?] [%bri @ud])))
=action %-  ar:dejs:format
|=  j=json
?>  ?=([%o *] j)
?~  move=(~(get by p.j) 'success')  ~
%+  turn  u.move
^-  $-(json *)
%-  ot:dejs:format
:~  '/groups/0/action/bri'^ni:dejs:format
==




=actions ^-  $-(json (list ?([%toggle ?] [%bri @ud])))
|=  j=json
?>  ?=([%a *] j)
^-  zing
^-  (list (list ?([%toggle ?] [%bri @ud])))
%+  turn  p.j
|=  jo=json
?>  ?=([%o *] jo)
=-  (slog leaf+"{<->}")
^-  (list ?([%toggle ?] [%bri @ud]))
%-  ~(rep by p.jo)
|=  [[k=@t v=json] o=(list ?([%toggle ?] [%bri @ud]))]
?.  =('success' k)  o
?>  ?=([%o *] v)
?~  bru=(~(get by p.v) '/groups/0/action/bri')
  ?~  un=(~(get by p.v) '/groups/0/action/on')
    o
  [[%toggle (bo:dejs:format u.un)] o]
[[%bri (ni:dejs:format u.bru)] o]

?:  =('/groups/0/action/bri' k)
  %-  (slog 'this' ~)
  (~(put by o) 'brightness' v)
?.  =('/groups/0/action/on' k)  ((slog k ~) o)
((slog 'the-other' ~) (~(put by o) 'on' v))

=converter (ar:dejs:format (ot:dejs:format ~[success+actions])