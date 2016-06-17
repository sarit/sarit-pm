xquery version "3.0";

import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

<results>
	<result>roman to devanagari: sukhena = {sarit-slp1:transliterate("sukhena", "roman", "deva")}</result>
	<result>devanagari to roman: सुखेन =  {sarit-slp1:transliterate("sukhena", "deva", "roman")}</result>
	<result>roman to roman (roundtrip): sukhena = {sarit-slp1:transliterate("sukhena", "roman", "roman")}</result>
</results>
