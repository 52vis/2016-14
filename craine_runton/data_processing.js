const fs = require('fs');
const xlsx = require('xlsx');
const readline = require('readline');
const parse = require('csv-parse/lib/sync');
require('should');

const state_abbr = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"];
var data = {'2011': {},'2012': {},'2013': {},'2014': {},'2015': {}};

process_the_data();

/**
 * Run all the subroutines
 */
function process_the_data() {
  munge_hud_data();
  munge_population_data();
  normalize_results();
  var maxes = stats();
  
  fs.writeFile('./normalized_data.json', JSON.stringify(data, null, 2), function(err) {
    if (err) {
      console.log('Error writing normalize_results.json');
    }
  });
  fs.writeFile('./stats.json', JSON.stringify(maxes, null, 2), function(err) {
    if (err) {
      console.log('Error writing stats.json')
    }
  })
}

/**
 * Read in the HUD dataset, and grab just the data points that we want
 */
function munge_hud_data() {
  // Read in the HUD data set from the Excel file using the xlsx package from npm
  var workbook = xlsx.readFile('./2007-2015-PIT-Counts-by-CoC.xlsx');
  
  // Loop through the years that have data for homeless veterans
  for (var year in data) {

    // Grab just the worksheet for the current year, and convert it to JSON using the package utilities
    var worksheet = xlsx.utils.sheet_to_json(workbook.Sheets[year]);
    
    state_abbr.forEach(function(state) {

      for (var prop in worksheet) {

        // Since we want to sum each state's information, we at matching the CoC Number string against the current
        //  state's abbreviation. If we get a match, then we continue the processing
        if (worksheet[prop]['CoC Number'].indexOf(state) > -1) {
            
          // This is here to handle the one row of Arkansas that had no data recorded in 2011 (row 17, CoC Number AR-507)
          if ((worksheet[prop]['Homeless Veterans, '+year] ||
              worksheet[prop]['Sheltered Homeless Veterans, '+year] ||
              worksheet[prop]['Unsheltered Homeless Veterans, '+year]) === '.') {
            // Set the number to zero, since it had a '.' for what presumable was no data collected
            worksheet[prop]['Homeless Veterans, '+year] = 0;
            worksheet[prop]['Sheltered Homeless Veterans, '+year] = 0;
            worksheet[prop]['Unsheltered Homeless Veterans, '+year] = 0;
          }

          if (typeof data[year][state] !== 'undefined') {
            // The state already exists for the year being parsed, so add the new values to the existing values
            data[year][state]['homeless_veterans'] = data[year][state]['homeless_veterans']  + worksheet[prop]['Homeless Veterans, '+year];
            data[year][state]['homeless_veterans_sheltered'] = data[year][state]['homeless_veterans_sheltered']  + worksheet[prop]['Sheltered Homeless Veterans, '+year];
            data[year][state]['homeless_veterans_unsheltered'] = data[year][state]['homeless_veterans_unsheltered']  + worksheet[prop]['Unsheltered Homeless Veterans, '+year];

          } else {
            // The state does not exist yet, so place the initial values in here
            data[year][state] = {
              'homeless_veterans': worksheet[prop]['Homeless Veterans, '+year],
              'homeless_veterans_sheltered': worksheet[prop]['Sheltered Homeless Veterans, '+year],
              'homeless_veterans_unsheltered': worksheet[prop]['Unsheltered Homeless Veterans, '+year],
              'state_population': 0,
              'homeless_per_100k': 0,
              'sheltered_per_100k': 0,
              'unsheltered_per_100k': 0
            }
          }
        }
      }
    });
  };
};

/**
 * Add the state population data to the set
 */
function munge_population_data() {
  var csv = fs.readFileSync('./uspop.csv');
  var pop_data = parse(csv);
  var parsed_data = {};

  for (var i = 1; i <= 51; i++) {
    var csv_state = pop_data[i][1];
    var pop_2011 = pop_data[i][13];
    var pop_2012 = pop_data[i][14];
    var pop_2013 = pop_data[i][15];
    var pop_2014 = pop_data[i][16];
    var pop_2015 = pop_data[i][17];
  
    parsed_data[csv_state] = {
      '2011': parseInt(pop_2011),
      '2012': parseInt(pop_2012),
      '2013': parseInt(pop_2013),
      '2014': parseInt(pop_2014),
      '2015': parseInt(pop_2015),
    };
  }

  for (var year in data) {  
    for (var state in parsed_data) {
      data[year][state]['state_population'] = parsed_data[state][year];
    }
  }
};

/**
 * Do some computation for some normalized results
 */
function normalize_results(callback) {
  for (var year in data) {
    for (var state in data[year]) {
      var population = data[year][state]['state_population'];
      var homeless = data[year][state]['homeless_veterans'];
      var sheltered = data[year][state]['homeless_veterans_sheltered'];
      var unsheltered = data[year][state]['homeless_veterans_unsheltered'];

      data[year][state]['homeless_per_100k'] = parseFloat(((homeless / population) * 100000).toFixed(2));
      data[year][state]['sheltered_per_100k'] = parseFloat(((sheltered / population) * 100000).toFixed(2));
      data[year][state]['unsheltered_per_100k'] = parseFloat(((unsheltered / population) * 100000).toFixed(2));
    }
  }
};

function stats() {
  var results = {'2011': {},'2012': {},'2013': {},'2014': {},'2015': {}};
  for (var year in data) {
    var homeless = [];
    var sheltered = [];
    var unsheltered = [];
    for (var state in data[year]) {
      homeless.push(data[year][state]['homeless_per_100k']);
      sheltered.push(data[year][state]['sheltered_per_100k']);
      unsheltered.push(data[year][state]['unsheltered_per_100k']);
    }
    results[year]['homeless_per_100k_max'] = Math.max.apply(null, homeless);
    results[year]['sheltered_per_100k'] = Math.max.apply(null, sheltered);
    results[year]['unsheltered_per_100k'] = Math.max.apply(null, unsheltered);
  }
  return results;
}