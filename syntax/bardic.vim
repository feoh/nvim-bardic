if exists('b:current_syntax')
  finish
endif

syntax match bardicPassage /^\s*::\s\+[A-Za-z_][A-Za-z0-9_.]*/ contains=bardicPassageMarker,bardicPassageName
syntax match bardicPassageMarker /^\s*::/ contained
syntax match bardicPassageName /[A-Za-z_][A-Za-z0-9_.]*/ contained
syntax match bardicChoice /^\s*[+*]\s*\({[^}]*}\s*\)\?\[[^]]*\]\s*->\s*[A-Za-z_][A-Za-z0-9_.]*/ contains=bardicChoiceMarker,bardicCondition,bardicChoiceText,bardicArrow,bardicTarget
syntax match bardicChoiceMarker /^\s*[+*]/ contained
syntax match bardicCondition /{[^}]*}/ contained
syntax match bardicChoiceText /\[[^]]*\]/ contained
syntax match bardicArrow /->/ contained
syntax match bardicTarget /[A-Za-z_][A-Za-z0-9_.]*$/ contained
syntax match bardicJump /^\s*->\s*[A-Za-z_][A-Za-z0-9_.]*/ contains=bardicArrow,bardicTarget
syntax match bardicAssignment /^\s*\~\s*.*/
syntax match bardicExpression /{[^}]*}/
syntax match bardicDirective /^\s*@\(start\|include\|render\|input\|metadata\)\>.*/
syntax match bardicControl /^\s*@\(if\|elif\|else\|endif\|for\|endfor\|py\|endpy\)\>.*/
syntax match bardicImport /^\s*\(import\|from\)\>.*/
syntax match bardicComment /#.*$/
syntax match bardicComment +//.*$+

highlight default link bardicPassageMarker Keyword
highlight default link bardicPassageName Function
highlight default link bardicChoiceMarker Operator
highlight default link bardicCondition Conditional
highlight default link bardicChoiceText String
highlight default link bardicArrow Operator
highlight default link bardicTarget Function
highlight default link bardicAssignment Statement
highlight default link bardicExpression Identifier
highlight default link bardicDirective PreProc
highlight default link bardicControl Conditional
highlight default link bardicImport Include
highlight default link bardicComment Comment

let b:current_syntax = 'bardic'
