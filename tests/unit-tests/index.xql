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
        {
            for $resource-name in xmldb:get-child-resources("/apps/sarit-pm/tests/unit-tests")[. != 'index.xql']
            order by $resource-name
            
            return <a href="{$resource-name}" target="_blank">{$resource-name}</a>
        }
    </body>
</html>
