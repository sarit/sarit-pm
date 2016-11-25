xquery version "3.1";

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Unit tests</title>
    </head>
    <style type="text/css">
        <![CDATA[
            body > a {
                display: block;
            }
        ]]>
    </style>    
    <body>
        <h1>Unit tests for sarit-pm</h1>
        <h2>Question mark searches</h2>
        <a href="leading-question-mark-search.xql" target="_blank">leading question mark</a>
        <a href="intermediate-question-mark-search.xql" target="_blank">intermediate question mark</a>
        <a href="trailing-question-mark-search.xql" target="_blank">trailing question mark</a>
        
        <h2>Asterisk searches</h2>
        <a href="leading-asterisk-search.xql" target="_blank">leading asterisk</a>
        <a href="intermediate-asterisk-search.xql" target="_blank">intermediate asterisk</a>
        <a href="trailing-asterisk-search.xql" target="_blank">trailing asterisk</a>
        
        <h2>Other searches</h2>
        {
            for $resource-name in xmldb:get-child-resources("/apps/sarit-pm/tests/unit-tests")[not(. = ('index.xql', 'intermediate-question-mark-search.xql', 'leading-question-mark-search.xql', 'trailing-question-mark-search.xql', 'leading-asterisk-search.xql', 'intermediate-asterisk-search.xql', 'trailing-asterisk-search.xql'))]
            order by $resource-name
            
            return <a href="{$resource-name}" target="_blank">{$resource-name}</a>
        }
    </body>
</html>
