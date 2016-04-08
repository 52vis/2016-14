window.onload = function () {
  init(); 
}

var limits = {
  "2011": {
    "homeless_per_100k_max": 83,
    "sheltered_per_100k": 78.97,
    "unsheltered_per_100k": 26.77
  },
  "2012": {
    "homeless_per_100k_max": 83.58,
    "sheltered_per_100k": 73.35,
    "unsheltered_per_100k": 31.71
  },
  "2013": {
    "homeless_per_100k_max": 76.82,
    "sheltered_per_100k": 66.97,
    "unsheltered_per_100k": 25.01
  },
  "2014": {
    "homeless_per_100k_max": 61.53,
    "sheltered_per_100k": 56.83,
    "unsheltered_per_100k": 24.36
  },
  "2015": {
    "homeless_per_100k_max": 60.69,
    "sheltered_per_100k": 54.45,
    "unsheltered_per_100k": 29.13
  }
}

function init(){
  for (var i = 2015; i >=2011; i--) {
    draw(i);
  }
}

function draw(year) {
  var homeless_data = d3.map();
  var width = 960,
      height = 600;
  
  var quantize = d3.scale.quantize()
    .domain([0, limits[year]['homeless_per_100k_max']])
    .range(d3.range(9).map(function(i) { return "q" + i + "-9"; }));

  var projection = d3.geo.albersUsa()
      .scale(1280)
      .translate([width / 2, height / 2]);
  
  var path = d3.geo.path()
      .projection(projection);
  
  var svg = d3.select(".svg"+year);
  
  queue()
    .defer(d3.json, "./us.json")
    .defer(d3.json, "./normalized_data.json")
    .await(ready);

  function ready(error, us, homeless) {
    if (error) throw error;

    for (var state in homeless[year]) {
      homeless_data.set(state, homeless[year][state]['homeless_per_100k']);
    }

    var states = topojson.feature(us, us.objects.states),
      selection0 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q0-9"; })},
      selection1 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q1-9"; })},
      selection2 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q2-9"; })},
      selection3 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q3-9"; })},
      selection4 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q4-9"; })},
      selection5 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q5-9"; })},
      selection6 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q6-9"; })},
      selection7 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q7-9"; })},
      selection8 = {type: "FeatureCollection", features: states.features.filter(function(d) { return quantize(homeless_data.get(d.properties.code)) == "q8-9"; })};

    svg.append("path")
      .datum(selection0)
      .attr("class", "q0-9")
      .attr("d", path)
      .attr("filter","url(#f3)");
  
    svg.append("path")
      .datum(selection1)
      .attr("class", "q1-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection2)
      .attr("class", "q2-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection3)
      .attr("class", "q3-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection4)
      .attr("class", "q4-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection5)
      .attr("class", "q5-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection6)
      .attr("class", "q6-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection7)
      .attr("class", "q7-9")
      .attr("d", path)
      .attr("filter","url(#f3)");

    svg.append("path")
      .datum(selection8)
      .attr("class", "q8-9")
      .attr("d", path)
      .attr("filter","url(#f3)");   

    svg.append("path")
      .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a !== b; }))
      .attr("class", "states")
      .attr("d", path); 
  
  }
  
  d3.select(self.frameElement).style("height", height + "px");
}

