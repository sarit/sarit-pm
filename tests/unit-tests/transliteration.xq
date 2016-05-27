xquery version "3.0";

import module namespace sarit = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

<results>
	<result>roman to devanagari: sukhena = {sarit:transliterate("sukhena", "roman", "deva")}</result>
	<result>devanagari to roman: सुखेन = {sarit:transliterate("sukhena", "deva", "roman")}</result>
	<result>roman to roman (roundtrip): sukhena = {sarit:transliterate("sukhena", "roman", "roman")}</result>
</results>
