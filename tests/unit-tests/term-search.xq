xquery version "3.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../../modules/config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $query-string := <query><term>suKena</term></query>
let $hits := collection($config:data-root)//tei:l[ft:query(., $query-string)]

return
	<result hits-number="{count($hits)}"> 
		{
			$hits
		}
	</result>
