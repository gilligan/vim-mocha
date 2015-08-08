" Get file path
let s:plugin_path = expand("<sfile>:p:h:h")
let g:spec_command = '!mocha --opts test/unit/mocha.opts --require test/babelCompiler.js --no-colors --recursive {spec}'


" Mocha Nearest Test
function! s:GetNearestTest()
  let callLine = line (".")           "cursor line
  let file = readfile(expand("%:p"))  "read current file
  let lineCount = 0                   "file line counter
  let lineDiff = 999                  "arbituary large number
  let descPattern = '\v<(it|describe|context)\s*\(?\s*[''"](.*)[''"]\s*,'
  for line in file
    let lineCount += 1
    let match = match(line,descPattern)
    if(match != -1)
      let currentDiff = callLine - lineCount
      " break if closest test is the next test
      if(currentDiff < 0 && lineDiff != 999)
        break
      endif
      " if closer test is found, cache new nearest test
      if(currentDiff <= lineDiff)
        let lineDiff = currentDiff
        let s:nearestTest = substitute(matchlist(line,descPattern)[2],'\v([''"()])','(.{1})','g')
      endif
    endif
  endfor
endfunction

" All Specs
function! RunAllSpecs()
  if isdirectory('test')
    let l:spec = "test"
  elseif isdirectory('spec')
    let l:spec = "spec"
  else
    let l:spec = ""
  endif
  call SetLastSpecCommand(l:spec)
  call RunSpecs(l:spec)
endfunction

" Current File
function! RunCurrentSpecFile()
  if InSpecFile()
    let l:spec = @%
    call SetLastSpecCommand(l:spec)
    call SetLastSpecFile(@%)
    call RunSpecs(l:spec)
  else
    call RunLastSpecFile()
  endif
endfunction

" Nearest Spec
function! RunNearestSpec()
  if InSpecFile()
    call s:GetNearestTest()
    let l:spec = @% . " -g '" . s:nearestTest . "'"
    call SetLastSpecCommand(l:spec)
    call SetLastSpecFile(@%)
    call SetLastNearestSpec(l:spec)
    call RunSpecs(l:spec)
  else
    call RunLastNearestSpec()
  endif
endfunction

" Current Spec File Name
function! InSpecFile()
  " Not a js or coffee file
  if match(expand('%'), '\v(.js|.jsx)$') == -1
    return 0
  endif
  " Check for describe block
  let l:contents = join(getline(1,'$'), "\n")
  let l:regex = '\v<describe\s*\(?\s*[''"](.*)[''"]\s*,'
  return match(l:contents, l:regex) != -1
endfunction

" Storing last commands
" =====================

" Store last spec name
function! SetLastNearestSpec(nearestSpec)
  let s:last_nearest_spec = a:nearestSpec
endfunction

" Store last spec file
function! SetLastSpecFile(file)
  let s:last_spec_file = a:file
endfunction

" Cache Last Spec Command
function! SetLastSpecCommand(spec)
  let s:last_spec_command = a:spec
endfunction

" Running last commands
" =====================

" Run Last Nearest Spec
function! RunLastNearestSpec()
  if exists("s:last_nearest_spec")
    call RunSpecs(s:last_nearest_spec)
  endif
endfunction

" Run Last Spec File
function! RunLastSpecFile()
  if exists("s:last_spec_file")
    call RunSpecs(s:last_spec_file)
  endif
endfunction

" Run Entire Last Spec
function! RunLastSpec()
  if exists("s:last_spec_command")
    call RunSpecs(s:last_spec_command)
  endif
endfunction

" Spec Runner
function! RunSpecs(spec)
  if g:spec_command ==? ""
    echom "No spec command specified."
  else
    execute substitute(g:spec_command, "{spec}", a:spec, "g")
  end
endfunction
