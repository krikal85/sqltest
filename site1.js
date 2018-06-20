
var menuList = {};

function loadRestaurants() {
    
    ajax("http://oliverklemencic.com/campus/restaurants.json",function(text){
        var json = JSON.parse(text);
        showRestaurants(json);
    });

    

    
}


function showRestaurants(result){
    
    var restaurantList = document.getElementById("restaurantList");
    restaurantList.innerHTML = "";
    var ul = document.createElement("ul");
    
    var h1_1 = document.createElement("h1");
    h1_1.innerText = "Restaurants"
    restaurantList.appendChild(h1_1);
    
    for(var i in result){

        var list = result[i];
       // console.log(list);

        var li = document.createElement("li");
        li.innerText = list.name;
        li.setAttribute("id",i)
        ul.appendChild(li);

        menuList[i] = list.speisen;

        li.addEventListener("click", function(e) {
            var liElement = e.target;
            showMenu(liElement.id);

        });

    }


    restaurantList.appendChild(ul);
    //console.log(menuList);


   

}


function showMenu(id){

    var menu = document.getElementById("menu");
    menu.innerHTML = "";

    var h1_2 = document.createElement("h1");
    h1_2.innerText = "Menüs";
    menu.appendChild(h1_2);

    var food = menuList[id];
    var ul_2 = document.createElement("ul");

    for(var i=0;i < food.length; i++){
        
        var li_2 = document.createElement("li");
        li_2.innerText = food[i].name;
        ul_2.appendChild(li_2);

    }
    menu.appendChild(ul_2);

};



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
