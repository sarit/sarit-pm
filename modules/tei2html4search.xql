xquery version "3.1";

(: Format parts of TEI documents for display of search results :) 

module namespace tei-to-html4search="http://sarit.indology.info/xquery/app/tei2html4search";

declare namespace tei="http://www.tei-c.org/ns/1.0";


(: A helper function in case no options are passed to the function :)
declare function tei-to-html4search:render($content as node()*) as element()+ {
    tei-to-html4search:render($content, <parameters/>)
};

(: The main function for the tei-to-html module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei-to-html4search:render($content as node()*, $options as element(parameters)*) as element()+ {
    <div class="document">
        { tei-to-html4search:dispatch($content, 0, $options) }
    </div>
};


declare function tei-to-html4search:dispatch($nodes as node()*, $depth as xs:integer, $options) as item()* {
    for $node in $nodes
    return
        typeswitch($node)
					case text() return if (normalize-space($node) = '' and $options/delete-white-space) then () else $node
					case element(exist:match) return tei-to-html4search:exist-match($node, $options)
					case element() return
					if (empty($node/node()))
					then ()
					else
						<div style="padding-left: {string($depth)}%;" id="{tei-to-html4search:get-id($node)}" class="search-tei-{local-name($node)}">
								<span class="search-tag">&lt;{local-name($node)}&gt;</span>
									{tei-to-html4search:recurse($node, $depth, $options)}
								<span class="search-tag">&lt;/{local-name($node)}&gt;</span>
						</div>
					
					default return ()
};

declare function tei-to-html4search:recurse($node as node(), $options) as item()* {
	tei-to-html4search:recurse($node, 0, $options)
};

declare function tei-to-html4search:recurse($node as node(), $depth as xs:integer, $options) as item()* {
    for $node in $node/node()
    return
        tei-to-html4search:dispatch($node, $depth + 1, $options)
};


declare function tei-to-html4search:exist-match($node as element(), $options) as element() {
    <mark xmlns="http://www.w3.org/1999/xhtml">{ $node/node() }</mark>                    
};

declare %private function tei-to-html4search:get-id($node as element()) {
    ($node/@xml:id, $node/@exist:id)[1]
};