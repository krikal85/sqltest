loadData();

function loadData() 
{

   ajax("http://oliverklemencic.com/campus/rechnungen.json", function(text)
    {
        var dat = JSON.parse(text);
        showData(dat);
    }); 
}



    function showData(text)
    {
        console.log(text);
        var divp = document.getElementById("resultContainer"); //Hier alle kinder Anhängen
        var h1 = document.createElement("h1");
        h1.innerText = "Kunden";
        divp.appendChild(h1);
        console.log(text.length);
        // ul begins Kundennamen
        var ul = document.createElement("ul");
         for (let index = 0; index < text.length; index++) {
            var Name = text[index].kunde;
            console.log(Name);
            var li = document.createElement("li");
            console.log(text[index].nummer);
            li.setAttribute("id", text[index].nummer );
            li.innerText = Name;
            li.addEventListener("click", function(e) {
                var liElement = e.target;
                subajax(liElement.id);
                });
            ul.appendChild(li);
            
        }
        divp.appendChild(ul);
        //Zwischenbereich ul Tbl
        var h2 = document.createElement("h1");
        h2.innerText = "Tabelle";
        divp.appendChild(h2);
        //table begins
        var tbl = document.createElement("table");
        tbl.border = 1;
        var thn = document.createElement("th");
        var thk = document.createElement("th");
        var thz = document.createElement("th");
        var ths = document.createElement("th");
        var trh = document.createElement("tr");
        thn.innerText = "Name";
        thk.innerText = "Kundennummer";
        thz.innerText = "Datum";
        ths.innerText = "Summe";

        trh.appendChild(thn);
        trh.appendChild(thk);
        trh.appendChild(thz);
        trh.appendChild(ths);
        tbl.appendChild(trh);
        for (let index = 0; index < text.length; index++) 
        {
            var trelement = document.createElement("tr");
            var Name = text[index].kunde;
            var Kundennummer = text[index].nummer;
            var Zeit = text[index].datum;
            var summe = text[index].summe;
            console.log
           var tdn = document.createElement("td");
           var tdk = document.createElement("td");
           var tdz = document.createElement("td");
           var tds = document.createElement("td");

           tdn.innerText = Name;
           tdk.innerText = Kundennummer;
           tdz.innerText = Zeit;
           tds.innerText = summe;

           trelement.appendChild(tdn);
           trelement.appendChild(tdk);
           trelement.appendChild(tdz);
           trelement.appendChild(tds);
           tbl.appendChild(trelement);
        }
        divp.appendChild(tbl);
    }

    function subajax(text)
{
    ajax("http://oliverklemencic.com/campus/details-" + text + ".json",function(inhalt)
    {
        var dat = JSON.parse(inhalt);
        console.log(dat);
        showData1(dat);
    });
}

function showData1(text)
{
        var divp = document.getElementById("details"); //Hier alle kinder Anhängen
        console.log(text);
       divp.innerHTML = "";
        var h1 = document.createElement("h1");
        h1.innerText = "KTest";
        divp.appendChild(h1);
        var ul = document.createElement("ul");
        console.log(text.length);
        console.log(text);
        for (var i in text) {
            var list = text;
            console.log(list);
           var li = document.createElement("li");
           li.innerText = text[i];
           ul.appendChild(li);
        }
        divp.appendChild(ul);

}

    function ajax(resourceName, callback) {
	
        xhr = new XMLHttpRequest();
        
        xhr.onreadystatechange = function(){
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
        
        xhr.open("GET", resourceName, true);
        xhr.send("");
    }

