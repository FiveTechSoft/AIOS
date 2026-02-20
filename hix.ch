#ifndef HIX_CH_
#define HIX_CH_
	
#xcommand VIEW <into:TO,INTO> <o> => #pragma __cstream|<o> += %s

#xcommand VIEW <into:TO,INTO> <o> [ PARAMS [<v1>] [,<vn>] ] ;
=> ;
	#pragma __cstream|<o>+= UInlinePRG( UReplaceBlocks( %s, '<$', "$>" [,<(v1)>][+","+<(vn)>] [, @<v1>][, @<vn>] ), nil [, @<v1>][, @<vn>]  )
		

#endif /* HIX_CH_ */


 