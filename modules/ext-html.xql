xquery version "3.1";

(:~
 : Non-standard extension functions, mainly used for the documentation.
 :)
module namespace pmf="http://sarit.indology.info/app/pmf-html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content, $place, $label) {
    switch ($place)
        case "margin" return
            if ($label) then (
                <span class="margin-note-ref">{$label}</span>,
                <span class="margin-note">
                    <span class="n">{$label/string()}) </span>{ $config?apply-children($config, $node, $content) }
                </span>
            ) else
                <span class="margin-note">
                { $config?apply-children($config, $node, $content) }
                </span>
        default return
            let $id := translate(util:node-id($node), "-", "_")
            let $nr :=
                if ($label) then
                    $label
                else
                    count($node/preceding::tei:note[@place != "margin"][ancestor::tei:text]) + 1
            let $content := $config?apply-children($config, $node, $content/node())
            return (
                <span id="fnref:{$id}">
                    <a class="note" rel="footnote" href="#fn:{$id}">
                    { $nr }
                    </a>
                </span>,
                <li class="footnote" id="fn:{$id}" value="{$nr}">
                    <span class="fn-content">
                        {$content}
                    </span>
                    <a class="fn-back" href="#fnref:{$id}">↩</a>
                </li>
            )
};