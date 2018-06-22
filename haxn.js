//zlatko:
// ------------------------
// -- logic to implement --
// ------------------------

var rechnungen = [];

function loadOverview() {
	
    var url = "http://oliverklemencic.com/campus/rechnungen.json";
    loadAjax(url, function(ajaxText){
        data = JSON.parse(ajaxText);

        for(var i = 0; i < data.length; i++){
            addRechnungToTable(data[i]);
        }
    })
    
}	

function addRechnungToTable(rechnung) {
    var body = document.getElementById("rechnungenBody");
    var reihe = document.createElement("tr");
    
    for(spalte in rechnung){
        var td = document.createElement("td");
        td.innerText = rechnung[spalte];
        reihe.appendChild(td);
    }
    var td = document.createElement("td");
    var btn = document.createElement("button");
    btn.innerText="Details";
    btn.setAttribute("id", rechnung["nummer"])
    btn.addEventListener("click", function(e) {
        showDetailsForRechnung(e.target.id);});
        td.appendChild(btn);
        reihe.appendChild(td);
        body.appendChild(reihe);
        rechnungen.push(rechnung);
        
}

function showDetailsForRechnung(rechnung) {
	
    var url = "http://oliverklemencic.com/campus/details-" + rechnung + ".json";
    loadAjax(url,function(ajaxText){
        data = JSON.parse(ajaxText);
        var name = document.getElementById("detailsName");
        name.value = data["beschreibung"];

        var preis = document.getElementById("detailsPrice");
        preis.value = data["summe"];
        
    });
    
}

function registerForSearch() {
	
}

function search(searchTerm) {
	
}


// --------------------
// -- initialization --
// --------------------

registerForSearch();
loadOverview();


// ----------------------
// -- helper functions --
// ----------------------

function loadAjax(url, callback) {
	var xhr=new XMLHttpRequest();
    xhr.onreadystatechange = function(){
        // Check for a completed connection
        if (xhr.readyState==4)
        {
            if (xhr.status==200)
            {
				callback(xhr.responseText);
				
            }
            else
            {
                alert("Problem retrieving data!");
            }
        }
    };
	xhr.open("GET", url, true);
	xhr.send("");
}
//
//
//
//




//hier bitte die lösungen rein
//von gollner es geht alles außer e
// ------------------------
// -- logic to implement --
// ------------------------

var rechnungen = [];

function loadOverview() {
	
    var url = "http://oliverklemencic.com/campus/rechnungen.json";
    loadAjax(url, function(text)
    {
        var inhalt = JSON.parse(text);
        addRechnungToTable(inhalt);
    }); 
}	

function addRechnungToTable(rechnung) {

    //table begins
    var tbl = document.getElementById("rechnungenBody");    
    for (let index = 0; index < rechnung.length; index++) 
    {
        var trelement = document.createElement("tr");
        var Name = rechnung[index].kunde;
        var Kundennummer = rechnung[index].nummer;
        var Zeit = rechnung[index].datum;
        var summe = rechnung[index].summe;

        var tdn = document.createElement("td");
        var tdk = document.createElement("td");
        var tdz = document.createElement("td");
        var tds = document.createElement("td");
        var tdd = document.createElement("a");
         tdd.innerText = "Details";
        tdd.setAttribute("id", rechnung[index].nummer );
        tdd.addEventListener("click", function(e) {
            var tdetails = e.target;
            showDetailsForRechnung(tdetails.id);
            });

       tdn.innerText = Name;
       tdk.innerText = Kundennummer;
       tdz.innerText = Zeit;
       tds.innerText = summe;
        
       trelement.appendChild(tdn);
       trelement.appendChild(tdk);
       trelement.appendChild(tdz);
       trelement.appendChild(tds);
       trelement.appendChild(tdd);
       tbl.appendChild(trelement);
    }
	
}

function showDetailsForRechnung(rechnung) {
	console.log(rechnung);
    var url = "http://oliverklemencic.com/campus/details-" + rechnung + ".json";
    loadAjax(url, function(text)
    {
     
        var inhalt = JSON.parse(text);
        var lieferant = document.getElementById("detailsName");
        var Beschreibung = document.getElementById("detailsPrice");
        
        var list = inhalt;
        console.log(list);
        console.log(list.lieferant);
        lieferant.value=list.lieferant;
        Beschreibung.value =list.beschreibung;

           
    }); 
}

function registerForSearch() {
	
}

function search(searchTerm) {
	
}


// --------------------
// -- initialization --
// --------------------

registerForSearch();
loadOverview();


// ----------------------
// -- helper functions --
// ----------------------

function loadAjax(url, callback) {
	var xhr=new XMLHttpRequest();
    xhr.onreadystatechange = function(){
        // Check for a completed connection
        if (xhr.readyState==4)
        {
            if (xhr.status==200)
            {
				callback(xhr.responseText);
				
            }
            else
            {
                alert("Problem retrieving data!");
            }
        }
    };
	xhr.open("GET", url, true);
	xhr.send("");
}



//--------------------------------------
//--von farid geht alles außer sortierung bitte ändern


<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.1">
	
  <xsl:template match="/">
    <html>
      <head><title>AgentInnen</title></head>
      <body>
        <h1>Einsatzgebiete</h1>
          <ul>
          
            <xsl:for-each select="Agenten/Geheimdienst">
                <li>
                  <xsl:value-of select="text()"/> (<xsl:value-of select="@id"/>): 
                  <xsl:for-each select="Agent"><xsl:value-of select="@location"/>   <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
   </xsl:if></xsl:for-each>
                </li>
            </xsl:for-each>
            
          </ul>

        <h1>AgentInnen</h1>
        <ul>
          <xsl:for-each select="Agenten/Geheimdienst">
            <xsl:for-each select="Agent">
             <xsl:sort select="id"/>
            <li>
           
              AgentIn <xsl:value-of select="id"/>: <xsl:value-of select="text()"/> (<xsl:value-of select="../@id"/>, <xsl:value-of select="@location"/>)
            </li>
            </xsl:for-each>
          </xsl:for-each>
        </ul>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
