// Function to print the current date and time
function printCurrentDatetime() {
  const datetime = new Date();
  console.log(`Current Date and Time: ${datetime.toISOString()}`);
}

module.exports = { printCurrentDatetime };
