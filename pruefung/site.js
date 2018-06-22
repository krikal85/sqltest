function loadRechnungen() {
   
    ajax("http://oliverklemencic.com/campus/rechnungen.json", function(resultText){
        var result = JSON.parse(resultText);
		showRechnungen(result);
    });
}

function loadDetails(nummer) {

	ajax("http://oliverklemencic.com/campus/details-" + nummer + ".json", function(resultText){
		var result = JSON.parse(resultText);
		showDetails(result);
	});
}

function showRechnungen(data){
	
	var ul = document.createElement("ul");
	var h4 = document.createElement("h4");
	h4.innerText = "Rechnungen";

    for (var rechnungId in data) {
		var rechnungsZeile = data[rechnungId];
		console.log(rechnungsZeile);

		console.log(rechnungsZeile.nummer);

		var li = document.createElement("li");
		li.innerText = rechnungsZeile.nummer + " | " + rechnungsZeile.kunde;
		ul.appendChild(li);

		// punkt c
		//detailList[restaurantId] = restaurantInfo.speisen;
		li.setAttribute("id", rechnungsZeile.nummer);

		li.addEventListener("click", function(e) {
			loadDetails(e.target.id);
		});
	}

	var container = document.getElementById("rechnungList");
	// clear content
	container.innerHTML = "";
	// set new content
	container.appendChild(h4);
	container.appendChild(ul);
}

function showDetails(details) {

	var ul = document.createElement("ul");
	var li = document.createElement("li");
	var h4 = document.createElement("h4");

	h4.innerText = "Details";

	li.innerText = details.nummer + " - " + details.kunde + " - " + details.datum + " - " + details.summe + " - " + details.lieferant + " - " + details.beschreibung;
	ul.appendChild(li);

	var container = document.getElementById("rechnungsDetails");
	// clear content
	container.innerHTML = "";
	// set new content
	container.appendChild(h4);
	container.appendChild(ul);
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
