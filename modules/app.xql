xquery version "3.0";

module namespace app="http://www.tei-c.org/tei-simple/templates";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tei-to-html="http://exist-db.org/xquery/app/tei2html" at "tei2html.xql";
import module namespace sarit="http://exist-db.org/xquery/sarit";
import module namespace metadata = "http://exist-db.org/ns/sarit/metadata/" at "metadata.xqm";
import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:devnag2roman := doc($config:app-root || "/modules/transliteration-rules.xml")//*[@id = "devnag2roman"];
declare variable $app:roman2devnag := doc($config:app-root || "/modules/transliteration-rules.xml")//*[@id = "roman2devnag"];
declare variable $app:roman2devnag-search := doc($config:app-root || "/modules/transliteration-rules.xml")//*[@id = "roman2devnag-search"];
declare variable $app:expand := doc($config:app-root || "/modules/transliteration-rules.xml")//*[@id = "expand"];
declare variable $app:iast-char-repertoire-negation := '[^aābcdḍeĕghḥiïījklḷḹmṁṃnñṅṇoŏprṛṝsśṣtṭuüūvy0-9\s]';

declare
    %templates:wrap
function app:check-login($node as node(), $model as map(*)) {
    let $user := request:get-attribute("org.exist.tei-simple.user")
    return
        if ($user) then
            templates:process($node/*[2], $model)
        else
            templates:process($node/*[1], $model)
};

declare
    %templates:wrap
function app:current-user($node as node(), $model as map(*)) {
    request:get-attribute("org.exist.tei-simple.user")
};

declare
    %templates:wrap
function app:show-if-logged-in($node as node(), $model as map(*)) {
    let $user := request:get-attribute("org.exist.tei-simple.user")
    return
        if ($user) then
            templates:process($node/node(), $model)
        else
            ()
};

(:~
 : List documents in data collection
 :)
declare
    %templates:wrap
    %templates:default("order", "title")
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $browse as xs:string?,
    $order as xs:string) {
    let $cached := session:get-attribute("simple.works")
    let $filtered :=
        if ($filter) then
            let $ordered :=
                for $item in
                    ft:search($config:data-root, $browse || ":" || $filter, ("author", "title"))/search
                let $author := $item/field[@name = "author"]
                order by $author[1], $author[2], $author[3]
                return
                    $item
            for $doc in $ordered
            return
                doc($doc/@uri)/tei:TEI
        else if ($cached and $filter != "") then
            app:order-documents($cached, $order)
        else
            app:order-documents(collection($config:data-root)/tei:TEI, $order)
    return (
        session:set-attribute("simple.works", $filtered),
        session:set-attribute("browse", $browse),
        session:set-attribute("filter", $filter),
        map {
            "all" : $filtered
        }
    )
};

declare function app:order-documents($docs as element()*, $order as xs:string) {
    let $orderFunc :=
        switch ($order)
            case "author" return
                app:work-author#1
            case "lang" return
                app:work-lang#1
            default return
                app:work-title#1
    for $doc in $docs
    order by $orderFunc($doc)
    return
        $doc
};



declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:browse($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $filter as xs:string?) {
    if (empty($model?all) and (empty($filter) or $filter = "")) then
        templates:process($node/*[@class="empty"], $model)
    else
        subsequence($model?all, $start, $per-page) !
            templates:process($node/*[not(@class="empty")], map:new(($model, map { "work": . })))
};

(:template function in view-work.html:)
declare function app:header($node as node(), $model as map(*)) {
    tei-to-html:render(root($model("data"))//tei:teiHeader)
};

declare
    %templates:wrap
function app:short-header($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $id := util:document-name($work)
    let $view :=
        if (pages:has-pages($work)) then
            "page"
        else
            $config:default-view
    return
        $pm-config:web-transform($work/tei:teiHeader, map {
            "header": "short",
            "doc": $id || "?view=" || $view
        })
};

(:~
 : Create a bootstrap pagination element to navigate through the hits.
 :)
declare
    %templates:default('key', 'hits')
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function app:paginate($node as node(), $model as map(*), $key as xs:string, $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
    if ($min-hits < 0 or count($model($key)) >= $min-hits) then
        element { node-name($node) } {
            $node/@*,
            let $count := xs:integer(ceiling(count($model($key))) div $per-page) + 1
            let $middle := ($max-pages + 1) idiv 2
            return (
                if ($start = 1) then (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-backward"/></a>
                    </li>
                ) else (
                    <li>
                        <a href="?start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li>
                        <a href="?start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                    </li>
                ),
                let $startPage := xs:integer(ceiling($start div $per-page))
                let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
                let $upperBound := min(($lowerBound + $max-pages - 1, $count))
                let $lowerBound := max(($upperBound - $max-pages + 1, 1))
                for $i in $lowerBound to $upperBound
                return
                    if ($i = ceiling($start div $per-page)) then
                        <li class="active"><a href="?start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                    else
                        <li><a href="?start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
                if ($start + $per-page < count($model($key))) then (
                    <li>
                        <a href="?start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a href="?start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                ) else (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                )
            )
        }
    else
        ()
};

(:~
    Create a span with the number of items in the current search result.
:)
declare
    %templates:wrap
    %templates:default("key", "hitCount")
function app:hit-count($node as node()*, $model as map(*), $key as xs:string) {
    let $value := $model?($key)
    return
        if ($value instance of xs:integer) then
            $value
        else
            count($value)
};

declare 
    %templates:wrap
function app:checkbox($node as node(), $model as map(*), $target-texts as xs:string*) {
    let $id := $model("work")/@xml:id/string()
    return (
        attribute { "value" } {
            $id
        },
        if ($id = $target-texts) then
            attribute checked { "checked" }
        else
            ()
    )
};

declare function app:statistics($node as node(), $model as map(*)) {
        "SARIT currently contains "|| $metadata:metadata/metadata:number-of-xml-works ||" text files (TEI-XML) of " || $metadata:metadata/metadata:size-of-xml-works || " XML (" || $metadata:metadata/metadata:number-of-pdf-pages || " pages in PDF format)."
};

declare %public function app:work-author($work as element(tei:TEI)?) {
    let $work-commentators := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'commentator']/text()
    let $work-authors := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'base-author']/text()
    let $work-authors := if ($work-authors) then $work-authors else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/text()
    let $work-authors := if ($work-commentators) then $work-commentators else $work-authors
    let $work-authors := if ($work-authors) then tei-to-html:serialize-list($work-authors) else ()
    return 
        $work-authors    
};

declare function app:work-author($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $work-commentators := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'commentator']/text()
    let $work-authors := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'base-author']/text()
    let $work-authors := if ($work-authors) then $work-authors else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/text()
    let $work-authors := if ($work-commentators) then $work-commentators else $work-authors
    let $work-authors := if ($work-authors) then tei-to-html:serialize-list($work-authors) else ()
    return 
        $work-authors    
};

declare function app:work-lang($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    return
        app:work-lang($work)
};

declare function app:work-lang($work as element(tei:TEI)) {
    let $script := $work//tei:text/@xml:lang
    let $script := if ($script eq 'sa-Latn') then 'IAST' else 'Devanagari'
    let $auto-conversion := $work//tei:revisionDesc/tei:change[@type eq 'conversion'][@subtype eq 'automatic'] 
    return 
        concat($script, if ($auto-conversion) then ' (automatically converted)' else '')  
};


(:~
 :
 :)
declare function app:work-title($node as node(), $model as map(*), $type as xs:string?) {
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $id := util:document-name($work)
    let $view :=
        if (pages:has-pages($work)) then
            "page"
        else
            $config:default-view
    return
        <a href="{$node/@href}{$id}{$suffix}?view={$view}">{ app:work-title($work) }</a>
};

declare %public function app:work-title($work as element(tei:TEI)?) {
    let $mainTitle :=
        (
            $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "main"]/text(),
            $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
        )[1]
    let $subTitles := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "sub"][@subtype = "commentary"]
    return
        if ($subTitles) then
            string-join(( $mainTitle, ": ", string-join($subTitles, " and ") ))
        else
            $mainTitle
};

declare function app:download-link($node as node(), $model as map(*), $type as xs:string, $doc as xs:string?,
    $source as xs:boolean?) {
    let $file :=
        if ($model?work) then
            replace(util:document-name($model("work")), "^(.*?)\.[^\.]*$", "$1")
        else
            replace($doc, "^(.*)\..*$", "$1")
    let $uuid := util:uuid()
    return
        element { node-name($node) } {
            $node/@*,
            attribute data-token { $uuid },
            attribute href { $node/@href || $file || "." || $type || "?token=" || $uuid || "&amp;cache=no"
                || (if ($source) then "&amp;source=yes" else ())
            },
            $node/node()
        }
};

declare
    %templates:wrap
function app:fix-links($node as node(), $model as map(*)) {
    app:fix-links(templates:process($node/node(), $model))
};

declare function app:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(a) | element(link) return
                (: skip links with @data-template attributes; otherwise we can run into duplicate @href errors :)
                if ($node/@data-template) then
                    $node
                else
                    let $href :=
                        replace(
                            $node/@href,
                            "\$app",
                            (request:get-context-path() || substring-after($config:app-root, "/db"))
                        )
                    return
                        element { node-name($node) } {
                            attribute href {$href}, $node/@* except $node/@href, app:fix-links($node/node())
                        }
            case element() return
                element { node-name($node) } {
                    $node/@*, app:fix-links($node/node())
                }
            default return
                $node
};

(: Search :)

declare function app:work-authors($node as node(), $model as map(*)) {
    let $authors := distinct-values(collection($config:data-root)//tei:fileDesc/tei:titleStmt/tei:author)
    let $authors := for $author in $authors order by translate($author, 'ĀŚ', 'AS') return $author
    let $control :=
        <select multiple="multiple" name="work-authors" class="form-control">
            <option value="all" selected="selected">In Texts By Any Author</option>
            {for $author in $authors
            return <option value="{$author}">{$author}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function app:preprocess-query-string($query-string as xs:string?) {
	let $results := string-join(
		for $w in tokenize($query-string, "\s")
		return
		if (matches($w, "^AND|NOT|OR$")) then
		$w
		else
		sarit-slp1:transcode($w),
		" ")
	return $results
};

(:~
: Execute the query. The search results are not output immediately. Instead they
: are passed to nested templates through the $model parameter.
:
: @author Wolfgang M. Meier
: @author Jens Østergaard Petersen
: @param $node
: @param $model
: @param $query The query string. This string is transformed into a <query> element containing one or two <bool> elements in a Lucene query and it is transformed into a sequence of one or two query strings in an ngram query. The first <bool> and the first string contain the query as input and the second the query as transliterated into Devanagari or IAST as determined by $query-scripts. One <bool> and one query string may be empty.
: @param $index The index against which the query is to be performed, as the string "ngram" or "lucene".
: @param $tei-target A sequence of one or more targets within a TEI document, the tei:teiHeader or tei:text.
: @param $work-authors A sequence of the string "all" or of the xml:ids of the documents associated with the selected authors.
: @param $query-scripts A sequence of the string "all" or of the values "sa-Latn" or "sa-Deva", indicating whether or not the user wishes to transliterate the query string.
: @param $target-texts A sequence of the string "all" or of the xml:ids of the documents selected.

: @return The function returns a map containing the $hits, the $query, and the $query-scope. The search results are output through the nested templates, app:hit-count, app:paginate, and app:show-hits.
:)
(:template function in search.html:)
declare
    %templates:default("index", "lucene")
    %templates:default("tei-target", "tei-text")
    %templates:default("query-scope", "narrow")
    %templates:default("work-authors", "all")
    %templates:default("query-scripts", "all")
    %templates:default("target-texts", "all")
    %templates:default("bool", "new")
function app:query($node as node()*, $model as map(*), $query as xs:string?, $index as xs:string, $tei-target as xs:string+, $query-scope as xs:string, $work-authors as xs:string+, $query-scripts as xs:string, $target-texts as xs:string+, $bool as xs:string) as map(*) {
        (:If there is no query string, fill up the map with existing values:)
        if (empty($query))
        then
            let $hits := session:get-attribute("apps.sarit.hits")
            return
                map {
                    "hits" : $hits,
                    "hitCount": count($hits),
                    "index" : session:get-attribute("apps.sarit.index"),
                    "ngram-query" : session:get-attribute("apps.sarit.ngram-query"),
                    "lucene-query" : session:get-attribute("apps.sarit.lucene-query"),
                    "scope" : $query-scope (:NB: what about the other arguments?:)
                }
        else
            (:Otherwise, perform the query.:)
            let $queries := app:preprocess-query-string($query)            
            (:First, which documents to query against has to be found out. Users can either make no selections in the list of documents, passing the value "all", or they can select individual document, passing a sequence of their xml:ids in $target-texts. Users can also select documents based on their authors. If no specific authors are selected, the value "all" is passed in $work-authors, but if selections have been made, a sequence of their xml:ids is passed. :)
            (:$target-texts will either have the value 'all' or contain a sequence of document xml:ids.:)
            let $target-texts :=
                (:("target-texts", "all")("work-authors", "all"):)
                (:If no texts have been selected and no authors have been selected, search in all texts:)
                if ($target-texts = 'all' and $work-authors = 'all')
                then 'all'
                else
                    (:("target-texts", "sequence of document xml:ids")("work-authors", "all"):)
                    (:If one or more texts have been selected, but no authors, search in selected texts:)
                    if ($target-texts != 'all' and $work-authors = 'all')
                    then $target-texts
                    else
                        (:("target-texts", "all")("work-authors", "sequence of document xml:ids"):)
                        (:If no texts, but one or more authors have been selected, search in texts selected by author:)
                        if ($target-texts = 'all' and $work-authors != 'all')
                        then distinct-values(collection($config:data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id)
                        else
                            (:("target-texts", "sequence of document xml:ids")("work-authors", "sequence of text xml:ids"):)
                            (:If one or more texts and more authors have been selected, search in the union of selected texts and texts selected by authors:)
                            if ($target-texts != 'all' and $work-authors != 'all')
                            then distinct-values(($target-texts, collection($config:data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id))
                            else ()
            (:After it has been determined which documents to query, we have to find out which document parts are targeted, the query "context". There are two parts, the text element ("tei-text") and the TEI header ("tei-header"). It is possible to select multiple contexts:)
            let $context :=
                (:If all documents have been selected for query, set the context as $config:data-root:)
                if ($target-texts = 'all')
                then
                    (:if there are two tei-targets, set the context below $config:data-root to the common parent of tei-text and tei-header, the document element TEI, otherwise set it to tei-text and tei-header, respectively.:)
                    if (count($tei-target) eq 2)
                    then collection($config:data-root)/tei:TEI
                    else
                        if ($tei-target = 'tei-text')
                        then collection($config:data-root)/tei:TEI/tei:text
                        else
                            if ($tei-target = 'tei-header')
                            then collection($config:data-root)/tei:TEI/tei:teiHeader
                            else ()
                else
                    (:If individual documents have been selected for query, use the sequence of xml:ids in $target-texts to filter the documents below $config:data-root:)
                    if (count($tei-target) eq 2)
                    (:if there are two tei-targets, set the context below $config:data-root to the common parent of tei-text and tei-header, the document element TEI, otherwise set it to tei-text and tei-header, respectively.:)
                    then collection($config:data-root)//tei:TEI[@xml:id = $target-texts]
                    else
                        if ($tei-target = 'tei-text')
                        then collection($config:data-root)//tei:TEI[@xml:id = $target-texts]/tei:text
                        else
                            if ($tei-target = 'tei-header')
                            then collection($config:data-root)//tei:TEI[@xml:id = $target-texts]/tei:teiHeader
                            else ()
            (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
            (:The query passed to a Lucene query in ft:query is a string containing one or two queries joined by an OR. The queries contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
            let $hits :=
                if ($index eq 'lucene')
                then
                    (:If the $query-scope is narrow, query the elements immediately below the lowest div in tei:text and the four major element below tei:teiHeader.:)
                    if ($query-scope eq 'narrow')
                    then
                        for $hit in
                            (:If both tei-text and tei-header is queried.:)
                            if (count($tei-target) eq 2)
                            then
                                (
                                $context//tei:p[ft:query(., $queries)],
                                $context//tei:head[ft:query(., $queries)],
                                $context//tei:lg[ft:query(., $queries)],
                                $context//tei:trailer[ft:query(., $queries)],
                                $context//tei:note[ft:query(., $queries)],
                                $context//tei:list[ft:query(., $queries)],
                                $context//tei:l[not(local-name(./..) eq 'lg')][ft:query(., $queries)],
                                $context//tei:quote[ft:query(., $queries)],
                                $context//tei:table[ft:query(., $queries)],
                                $context//tei:listApp[ft:query(., $queries)],
                                $context//tei:listBibl[ft:query(., $queries)],
                                $context//tei:cit[ft:query(., $queries)],
                                $context//tei:label[ft:query(., $queries)],
                                $context//tei:encodingDesc[ft:query(., $queries)],
                                $context//tei:fileDesc[ft:query(., $queries)],
                                $context//tei:profileDesc[ft:query(., $queries)],
                                $context//tei:revisionDesc[ft:query(., $queries)]
                                )
                            else
                                if ($tei-target = 'tei-text')
                                then
                                    (
                                    $context//tei:p[ft:query(., $queries)],
                                    $context//tei:head[ft:query(., $queries)],
                                    $context//tei:lg[ft:query(., $queries)],
                                    $context//tei:trailer[ft:query(., $queries)],
                                    $context//tei:note[ft:query(., $queries)],
                                    $context//tei:list[ft:query(., $queries)],
                                    $context//tei:l[not(local-name(./..) eq 'lg')][ft:query(., $queries)],
                                    $context//tei:quote[ft:query(., $queries)],
                                    $context//tei:table[ft:query(., $queries)],
                                    $context//tei:listApp[ft:query(., $queries)],
                                    $context//tei:listBibl[ft:query(., $queries)],
                                    $context//tei:cit[ft:query(., $queries)],
                                    $context//tei:label[ft:query(., $queries)]
                                    )
                                else
                                    if ($tei-target = 'tei-header')
                                    then
                                        (
                                        $context//tei:encodingDesc[ft:query(., $queries)],
                                        $context//tei:fileDesc[ft:query(., $queries)],
                                        $context//tei:profileDesc[ft:query(., $queries)],
                                        $context//tei:revisionDesc[ft:query(., $queries)]
                                        )
                                    else ()
                        order by ft:score($hit) descending
                        return $hit
                    (:If the $query-scope is broad, query the lowest div in tei:text and tei:teiHeader.:)
                    else
                        for $hit in
                            if (count($tei-target) eq 2)
                            then
                                (
                                $context//tei:div[not(tei:div)][ft:query(., $queries)],
                                $context/descendant-or-self::tei:teiHeader[ft:query(., $queries)](:NB: Can divs occur in the header? If so, they have to be removed here5:)
                                )
                            else
                                if ($tei-target = 'tei-text')
                                then
                                    (
                                    $context//tei:div[not(tei:div)][ft:query(., $queries)]
                                    )
                                else
                                    if ($tei-target = 'tei-header')
                                    then
                                        $context/descendant-or-self::tei:teiHeader[ft:query(., $queries)]
                                    else ()
                        order by ft:score($hit) descending
                        return $hit
                (: The part with the ngram query mirrors that for the Lucene query, but here $queries contains a sequence of one or two non-empty strings containing the original query and the transliterated query, as indicated by the user in $query-scripts:)
                else
                    if ($query-scope eq 'narrow' and count($tei-target) eq 2)
                    then
                        for $hit in
                            (
                            (:Only query if there is a value in the first item.:)
                            if ($queries[1])
                            then (
                                $context//tei:p[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:head[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:lg[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:trailer[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:note[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:list[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:l[not(local-name(./..) eq 'lg')][ngram:wildcard-contains(., $queries[1])],
                                $context//tei:quote[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:table[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:listApp[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:listBibl[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:cit[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:label[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:fileDesc[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:profileDesc[ngram:wildcard-contains(., $queries[1])],
                                $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[1])]
                                )
                            else ()
                            ,
                            (:Only query if there is a value in the second item.:)
                            if ($queries[2])
                            then (
                                $context//tei:p[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:head[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:lg[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:trailer[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:note[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:list[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:l[not(local-name(./..) eq 'lg')][ngram:wildcard-contains(., $queries[2])],
                                $context//tei:quote[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:table[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:listApp[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:listBibl[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:cit[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:label[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:fileDesc[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:profileDesc[ngram:wildcard-contains(., $queries[2])],
                                $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[2])]
                                )
                            else ()
                            )
                        order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                        return $hit
                    else
                        if ($query-scope eq 'narrow' and $tei-target eq 'tei-text')
                        then
                            for $hit in
                                (
                                if ($queries[1])
                                then (
                                    $context//tei:p[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:head[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:lg[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:trailer[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:note[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:list[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:l[not(local-name(./..) eq 'lg')][ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:quote[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:table[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:listApp[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:listBibl[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:cit[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:label[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:fileDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:profileDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[1])]
                                    )
                                else ()
                                ,
                                if ($queries[2])
                                then (
                                    $context//tei:p[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:head[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:lg[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:trailer[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:note[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:list[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:l[not(local-name(./..) eq 'lg')][ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:quote[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:table[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:listApp[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:listBibl[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:cit[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:label[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:fileDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:profileDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[2])]
                                )
                        else ()
                        )
                            order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                            return $hit
                        else
                            if ($query-scope eq 'narrow' and $tei-target eq 'tei-header')
                            then
                            for $hit in
                                (
                                if ($queries[1])
                                then (
                                    $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:fileDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:profileDesc[ngram:wildcard-contains(., $queries[1])],
                                    $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[1])]
                                ) else ()
                                ,
                                if ($queries[2])
                                then (
                                    $context//tei:encodingDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:fileDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:profileDesc[ngram:wildcard-contains(., $queries[2])],
                                    $context//tei:revisionDesc[ngram:wildcard-contains(., $queries[2])]
                                ) else ()
                                )
                            order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                            return $hit
                            else
                                if ($query-scope eq 'broad' and count($tei-target) eq 2)
                                then
                                    for $hit in
                                        (
                                        if ($queries[1])
                                        then
                                            (
                                            $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queries[1])],
                                            $context//tei:teiHeader[ngram:wildcard-contains(., $queries[1])]
                                            )
                                        else ()
                                        ,
                                        if ($queries[2])
                                        then (
                                            $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queries[2])],
                                            $context//tei:teiHeader[ngram:wildcard-contains(., $queries[2])]
                                            )
                                        else ()
                                        )
                                    order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                    return $hit
                                else
                                    if ($query-scope eq 'broad' and $tei-target eq 'tei-text')
                                    then
                                        for $hit in (
                                            if ($queries[1])
                                            then
                                                $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queries[1])]
                                            else ()
                                            ,
                                            if ($queries[2])
                                            then
                                                $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queries[2])]
                                            else ()
                                        )
                                        order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                        return $hit
                                    else
                                        if ($query-scope eq 'broad' and $tei-target eq 'tei-header')
                                        then
                                        for $hit in (
                                            if ($queries[1]) then
                                                $context//tei:teiHeader[ngram:wildcard-contains(., $queries[1])]
                                            else ()
                                            ,
                                            if ($queries[2]) then
                                                $context//tei:teiHeader[ngram:wildcard-contains(., $queries[2])]
                                            else
                                                ()
                                            )
                                            order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                            return $hit
                                        else ()
            let $hits :=
                if ($bool eq 'or')
                then session:get-attribute("apps.sarit.hits") union $hits
                else
                    if ($bool eq 'and')
                    then session:get-attribute("apps.sarit.hits") intersect $hits
                    else
                        if ($bool eq 'not')
                        then session:get-attribute("apps.sarit.hits") except $hits
                        else $hits
            (:gather up previous searches for match highlighting.:)
            (:NB: lucene-queries may have slashes added, so they may be different from ngram-queries:)
            let $ngram-query :=
                if ($index eq 'ngram')
                then
                    if ($bool eq 'new')
                    then $queries
                    else
                        if ($bool = ('or', 'and'))
                        then ($queries, session:get-attribute("apps.sarit.ngram-query"))
                        else
                            if ($bool eq 'not')
                            then session:get-attribute("apps.sarit.ngram-query")
                            else ''
                else ''
            let $lucene-query :=
                if ($index eq 'lucene')
                then
                    if ($bool eq 'new')
                    then $queries
                    else
                        if ($bool = ('or', 'and'))
                        then ($queries, session:get-attribute("apps.sarit.lucene-query"))
                        else
                            if ($bool eq 'not')
                            then session:get-attribute("apps.sarit.lucene-query")
                            else ''
                else ''
    
            let $store := (
                session:set-attribute("apps.sarit.hits", $hits),
                session:set-attribute("apps.sarit.index", $index),
                session:set-attribute("apps.sarit.ngram-query", $ngram-query),
                session:set-attribute("apps.sarit.lucene-query", $lucene-query),
                session:set-attribute("apps.sarit.scope", $query-scope),
                session:set-attribute("apps.sarit.bool", $bool)
                )
            
            return
                (: The hits are not returned directly, but processed by the nested templates :)
                map {
                    "hits" : $hits,
                    "hitCount": count($hits),
                    "ngram-query" : $ngram-query,
                    "lucene-query" : $lucene-query
                }
};

(:~
    app:expand-query transliterates the query string from Devanagari to IAST transcription and/or from IAST transcription to Devanagari,
    if the user has indicated that this is wanted in $query-scripts.
:)
declare %private function app:expand-query($query as xs:string*, $query-scripts as xs:string?) as xs:string* {
    if ($query)
    then (
        sarit:create("devnag2roman", $app:devnag2roman/string()),
        sarit:create("roman2devnag", $app:roman2devnag-search/string()),
        sarit:create("expand", $app:expand/string()),
        (:if there is input exclusively in IAST romanization:)
        if (not(matches($query, $app:iast-char-repertoire-negation)))
        then
            (:if the user wants to search in Devanagri, then transliterate and discard the original query:)
            if ($query-scripts eq "sa-Deva")
            then
                sarit:transliterate("expand",translate(sarit:transliterate("roman2devnag", $query), "&#8204;", ""))
            else
                (:if the user wants to search in both IAST and Devanagri, then transliterate the original query and keep it:)
                if ($query-scripts eq "all")
                then
                    ($query, sarit:transliterate("expand",translate(sarit:transliterate("roman2devnag", $query), "&#8204;", "")))
                else
                    (:if the user wants to search in romanization, then do not transliterate but keep original query:)
                    if ($query-scripts eq "sa-Latn")
                    then
                        $query
                    (:this exhausts all options for IAST input strings:)
                    else ''
        else
            (:if there is input exclusively in Devanagari:)
            if (empty(string-to-codepoints($query)[not(. = (9-13, 32, 133, 160, 2304 to 2431, 43232 to 43259, 7376 to 7412))]))
            then
                (:if the user wants to search in IAST, then transliterate the original query but delete it:)
                if ($query-scripts eq "sa-Latn")
                then
                    sarit:transliterate("devnag2roman", $query)
                else
                    (:if the user wants to search in both Devanagri and IAST, then transliterate the original query and keep it:)
                    if ($query-scripts eq "all")
                    then
                        (sarit:transliterate("expand",$query), sarit:transliterate("devnag2roman", $query))
                    else
                        (:if the user wants to search in Devanagri, then do not transliterate original query but keep it:)
                        if ($query-scripts eq "sa-Deva")
                        then
                            sarit:transliterate("expand", $query)
                        else ''
            (:there should only be two options: IAST and Devanagari input. If the query is not pure IAST and is not pure Devanagari, then do not (try to) transliterate the original query but keep it as it is.:)
            else
                $query
    )
    else ()
};

declare function app:expand-hits($divs as element()*, $index as xs:string) {
    let $queries :=
        switch($index)
            case "ngram" return
                session:get-attribute("apps.sarit.ngram-query")
            default return
                session:get-attribute("apps.sarit.lucene-query")
                
    for $div in $divs
    let $result := 
                $div[ft:query(., session:get-attribute("apps.sarit.lucene-query"))]
    return
        util:expand($result, "add-exist-id=all")
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
    %templates:default("index", "ngram")
function app:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?,
    $index as xs:string) {
    let $view := if ($view) then $view else $config:default-view
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $parent := $hit/ancestor-or-self::tei:div[1]
    let $parent := if ($parent) then $parent else $hit/ancestor-or-self::tei:teiHeader
    let $parent := if ($parent) then $parent else root($hit)
    let $div := app:get-current($parent)
    let $parent-id := util:document-name($parent) || "?root=" || util:node-id($parent)
    let $div-id := util:document-name($div) || "?root=" || util:node-id($div)
    (:if the nearest div does not have an xml:id, find the nearest element with an xml:id and use it:)
    (:is this necessary - can't we just use the nearest ancestor?:)
(:    let $div-id := :)
(:        if ($div-id) :)
(:        then $div-id :)
(:        else ($hit/ancestor-or-self::*[@xml:id]/@xml:id)[1]/string():)
    (:if it is not a div, it will not have a head:)
    let $div-head := $parent/tei:head/text()
    (:TODO: what if the hit is in the header?:)
    let $work := $hit/ancestor::tei:TEI
    let $work-title := app:work-title($work)
    (:the work always has xml:id.:)
    let $work-id := $work/@xml:id/string()
    let $work-id := util:document-name($work)

    let $loc :=
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <span class="headings">
                    <a href="{$work-id}">{$work-title}</a>{if ($div-head) then ' / ' else ''}<a href="{$parent-id}&amp;action=search">{$div-head}</a>
                </span>
            </td>
        </tr>
    let $expanded := util:expand($hit, "add-exist-id=all")
    return (
        $loc,
        for $match in subsequence($expanded//exist:match, 1, 5)
        let $matchId := $match/../@exist:id
        let $docLink :=
            if ($view = "page") then
                let $contextNode := util:node-by-id($div, $matchId)
                let $page := $contextNode/preceding::tei:pb[1]
                return
                    util:document-name($work) || "?root=" || util:node-id($page)
            else
                $div-id
        let $link := $docLink || "&amp;action=search&amp;view=" || $view || "&amp;index=" || $index || "#" || $matchId
        let $config := <config width="60" table="yes" link="{$link}"/>
        let $kwic := kwic:get-summary($expanded, $match, $config)
        let $output :=
            if ($index = "ngram" and contains($model?ngram-query, "*")) then
                <tr>
                    <td colspan="3" class="text">
                        {
                            <span class="previous">{normalize-space($kwic//td[@class = "previous"]/node())}</span>,
                            <a href="{$link}"><i class="material-icons">play_arrow</i></a>,
                            <span class="hi">{normalize-space($kwic//td[@class = "hi"]//text())}</span>,
                            <span class="following">{normalize-space($kwic//td[@class = "following"]/node())}</span>
                        }
                    </td>
                </tr>
            else
                $kwic
        return $output
    )
};

declare %private function app:get-current($div as element()?) {
    if (empty($div)) then
        ()
    else
        if ($div instance of element(tei:teiHeader)) then
        $div
        else
            if (
                empty($div/preceding-sibling::tei:div)  (: first div in section :)
                and count($div/preceding-sibling::*) < 5 (: less than 5 elements before div :)
                and $div/.. instance of element(tei:div) (: parent is a div :)
            ) then
                pages:get-previous($div/..)
            else
                $div
};
