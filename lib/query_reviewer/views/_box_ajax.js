var i = 0;
var last = null;
while (document.getElementById("query_review_" + i)) {
  last = document.getElementById("query_review_" + i);
  i++;
}

if (i < 10) {
  var containerDiv = document.createElement("div");
  containerDiv.style.left = (i * 30 + 1) + "px";
  containerDiv.id = "query_review_" + i;
  containerDiv.className = "query_review_container";

  var innerHtml = '<%= j(render(partial: "box_includes")) %>';
  innerHtml += '<div class="query_review <%= parent_div_class %>" id="query_review_header_' + i + '">';
  innerHtml += '<%= j(render(partial: "box_header")) %>';
  innerHtml += '</div>';
  innerHtml += '<div class="query_review_details" id="query_review_details_' + i + '" style="display: none;">';
  innerHtml += '<%= j(render(partial: enabled_by_cookie ? "box_body" : "box_disabled")) %>';
  innerHtml += '</div>';

  containerDiv.innerHTML = innerHtml;

  var parentDiv = document.getElementById("query_review_parent");
  if (!parentDiv) {
    parentDiv = document.createElement("div");
    parentDiv.id = "query_review_parent";
    parentDiv.className = "query_review_parent";
    document.body.appendChild(parentDiv);
  }

  parentDiv.appendChild(containerDiv);
}
