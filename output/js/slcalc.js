function setclassview(setareaid)
{
  var menuobj = document.getElementById(setareaid);
  if(menuobj){
//    menuobj.innerHTML="Hello world";
    var CategorySelect = "Category:<input type=text size =3 onkeyup=\"categorySelect(this.value);\">";
    var RaceSelect     = " Race:<input type=text size=3 onkeyup=\"alert('Race!');\">";
    var NumberSelect   = " number:<input type=text size=3 onkeyup=\"alert('Number!');\">";
    menuobj.innerHTML = "" + CategorySelect + RaceSelect + NumberSelect;
  }
}

function categorySelect(catname)
{
  var elm=document.getElementsByTagName('div');
  for(var i=0;i < elm.length;i++)
  {
    if(elm[i].getAttribute("className")=="category"){
      if(elm[i].getAttribute("value").indexOf(catname) < 0){ 
alert("d:"+elm[i].getAttribute("value"));
        elm[i].style.display="none;";
      }else{
alert("a:"+elm[i].getAttribute("value"));
        elm[i].style.display="block;";
      }
    }
  }
}

window.onload = function() {
  setclassview("topmenu");
}

