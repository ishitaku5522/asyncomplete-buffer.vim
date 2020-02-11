let s:words = {}
let s:last_word = ''
let g:asyncomplete_buffer_clear_cache = get(g:, 'asyncomplete_buffer_clear_cache', 1)

let g:asyncomplete_buffer_split_pattern = '!"#$%&''()*+,-./:;<=>?@\[\]^`{|}~ \t\r\n　、。，．・：；？！‘’“”（）〔〕［］｛｝〈〉《》「」『』【】'

function! asyncomplete#sources#buffer#completor(opt, ctx)
    call timer_start(1, function('s:completor', [a:opt, a:ctx]))
endfunction

function! s:completor(opt, ctx, timer)
    let l:typed = a:ctx['typed']

    call s:refresh_keyword_incremental(l:typed)

    if empty(s:words)
        return
    endif

    let l:matches = []

    let l:col = a:ctx['col']

    let l:kw = matchstr(l:typed, '\k\+$')
    let l:kwlen = len(l:kw)

    let l:matches = map(keys(s:words),'{"word":v:val,"dup":1,"icase":1,"menu": "[buffer]"}')
    let l:startcol = l:col - l:kwlen

    call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
endfunction

function! asyncomplete#sources#buffer#get_source_options(opts)
    return extend({
        \ 'events': ['BufEnter', 'InsertEnter', 'InsertLeave'],
        \ 'on_event': function('s:on_event'),
        \}, a:opts)
endfunction

function! s:should_ignore(opt) abort
    let l:max_buffer_size = 5000000 " 5mb
    if has_key(a:opt, 'config') && has_key(a:opt['config'], 'max_buffer_size')
        let l:max_buffer_size = a:opt['config']['max_buffer_size']
    endif
    if l:max_buffer_size != -1
        let l:buffer_size = line2byte(line('$') + 1)
        if l:buffer_size > l:max_buffer_size
            call asyncomplete#log('asyncomplete#sources#buffer', 'ignoring buffer autocomplete due to large size', expand('%:p'), l:buffer_size)
            return 1
        endif
    endif

    return 0
endfunction

let s:last_ctx = {}
function! s:on_event(opt, ctx, event) abort
    if s:should_ignore(a:opt) | return | endif

    if a:event == 'BufEnter' || a:event == 'InsertEnter' || a:event == 'InsertLeave'
        call timer_start(1, function('s:refresh_keywords'))
    endif
endfunction

function! s:refresh_keywords(timer) abort
    if g:asyncomplete_buffer_clear_cache
        let s:words = {}
    endif
    let l:text = ""
    for l:bufnr in tabpagebuflist()
      let l:text = l:text . join(getbufline(l:bufnr, 1, '$'), "\n") . "\n"
    endfor
    for l:word in split(l:text, '['.g:asyncomplete_buffer_split_pattern.']\+')
        if len(l:word) > 1
            let s:words[l:word] = 1
        endif
    endfor
    call asyncomplete#log('asyncomplete#buffer', 's:refresh_keywords() complete')
endfunction

function! s:refresh_keyword_incremental(typed) abort
    let l:words = split(a:typed, '['.g:asyncomplete_buffer_split_pattern.']\+')
    for l:word in l:words
        if len(l:word) > 1
            let s:words[l:word] = 1
        endif
    endfor
endfunction
