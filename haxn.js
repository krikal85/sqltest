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

