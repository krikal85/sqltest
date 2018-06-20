var menuList = {};

function loadRestaurants() {
    ajax("http://oliverklemencic.com/campus/restaurants.json", function(receivedText){
        var result = JSON.parse(receivedText);
        showRestaurants(result);
    });


   
}

function showRestaurants(data){
    var ul = document.createElement("ul");
    var h4 = document.createElement("h4");
    h4.innerText = "Restaurants";

    menuList = {};
    
    for(var restaurantID in data){

        var restaurant = data[restaurantID];
        var name = restaurant.name;
        var li = document.createElement("li");
        li.innerText = name;
        li.setAttribute("id", restaurantID);
        
        ul.appendChild(li);
        menuList[restaurantID] = restaurant.speisen;

        li.addEventListener("click", function(restaurant) {
            
            showMenu(restaurant.target.id);
            });
        
        
    }
    var container = document.getElementById("restaurantList");
    container.innerHTML = "";
    container.appendChild(h4);
    container.appendChild(ul);
    
    
    
}


function showMenu(restaurantID){
    var menu = document.getElementById("menu");
    var h4 = document.createElement("h4");
    h4.innerText = "Menü";
    var ul = document.createElement("ul");

    menu.innerHTML = "";
    menu.appendChild(h4);

    console.log(restaurantID);

    for(zeile in menuList[restaurantID]){
        var li = document.createElement("li");
        li.innerText = menuList[restaurantID][zeile].name;
        ul.appendChild(li);
    }

    menu.appendChild(ul);


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

