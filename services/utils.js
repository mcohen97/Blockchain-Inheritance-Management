const moment = require('moment')
 

function dateStringToUnix(stringDate){
  return moment(stringDate).unix();
}

function unixToDateString(unixDate){
  return moment.unix(unixDate).format('DD/MM/YYYY hh:mm:ss');
}

exports.dateStringToUnix = dateStringToUnix; 
exports.unixToDateString = unixToDateString;