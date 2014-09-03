let s:save_cpo = &cpo
set cpo&vim

function! unite#libs#http#oauth_dl(url, ctx, file, ...)
  let params = a:0 > 0 ? a:000[0] : {}
  let getdata = a:0 > 1 ? a:000[1] : {}
  let headdata = a:0 > 2 ? a:000[2] : {}
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = webapi#sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:ctx.consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "GET"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:ctx.access_token
  let query["oauth_version"] = "1.0"
  if type(params) == 4
    for key in keys(params)
      let query[key] = params[key]
    endfor
  endif
  if type(getdata) == 4
    for key in keys(getdata)
      let query[key] = getdata[key]
    endfor
  endif
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= webapi#http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= webapi#http#encodeURI(webapi#http#encodeURI(query))
  let hmacsha1 = webapi#hmac#sha1(webapi#http#encodeURI(a:ctx.consumer_secret) . "&" . webapi#http#encodeURI(a:ctx.access_token_secret), query_string)
  let query["oauth_signature"] = webapi#base64#b64encodebin(hmacsha1)
  if type(getdata) == 4
    for key in keys(getdata)
      call remove(query, key)
    endfor
  endif
  let auth = 'OAuth '
  for key in sort(keys(query))
    let auth .= key . '="' . webapi#http#encodeURI(query[key]) . '", '
  endfor
  let auth = auth[:-3]
  let headdata["Authorization"] = auth
  call unite#libs#http#download(a:url, a:file, getdata, headdata)
endfunction

function! unite#libs#http#download(url, file, ...)
  let getdata = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
  let url = a:url
  let getdatastr = webapi#http#encodeURI(getdata)
  if strlen(getdatastr)
    let url .= "?" . getdatastr
  endif
  if executable('curl')
    let command = 'curl -s -k -o "'.a:file.'"'
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . headdata[key] . quote
      endif
    endfor
    let command .= " ".quote.url.quote
    call system(command)
  elseif executable('wget')
    let command = 'wget --save-headers --server-response -q -O "'.a:file.'"'
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " --header=" . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " --header=" . quote . key . ": " . headdata[key] . quote
      endif
    endfor
    let command .= " ".quote.url.quote
    call = system(command)
  else
    throw "require `curl` or `wget` command"
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
